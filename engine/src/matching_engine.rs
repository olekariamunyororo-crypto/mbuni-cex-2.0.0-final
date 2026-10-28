// Mbuni CEX 2.0 — Core matching engine logic
//
// Rust port of the TypeScript reference engine (src/lib/opencex/engine.ts).
// Implements:
//   - Price-time priority matching (BUY hits the lowest ask first, SELL hits the HIGHEST bid first)
//   - All 5 order types: LIMIT, MARKET, IOC, FOK, POST_ONLY
//   - Pre-trade validation + FOK pre-flight liquidity check
//   - O(log n) cancel via an order index
//   - Order book snapshots and bounded server-streaming of book updates / trades
//
// Performance targets (§5 of spec):
//   - Order processing latency (p99): < 500µs
//   - Throughput per shard: ≥ 100,000 orders/sec

use std::cmp::Ordering;
use std::collections::{BTreeMap, HashMap, VecDeque};
use std::pin::Pin;
use std::sync::atomic::{AtomicU64, Ordering as AtomicOrdering};
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

use dashmap::DashMap;
use parking_lot::RwLock;
use tokio::sync::mpsc;
use tokio_stream::wrappers::ReceiverStream;
use tokio_stream::{Stream, StreamExt};
use tonic::{Request, Response, Status};
use uuid::Uuid;

use crate::proto::matching_engine_server::MatchingEngine;
use crate::proto::*;

// --- Constants ---

/// Quantities below this are treated as zero (guards against f64 dust after rounding).
const EPS: f64 = 1e-12;
/// Per-subscriber buffer. A subscriber that falls this far behind is dropped (trades) or
/// skipped (book snapshots) instead of growing memory without bound.
const SUBSCRIBER_BUFFER: usize = 1024;
const MAX_SNAPSHOT_DEPTH: usize = 200;

struct PairConfig {
    symbol: &'static str,
    base_decimals: u8,
    price_decimals: u8,
    min_qty: f64,
    tick_size: f64,
    initial_price: f64,
}

const TRADING_PAIRS: &[PairConfig] = &[
    PairConfig { symbol: "BTC/USDT", base_decimals: 8, price_decimals: 2, min_qty: 0.0001, tick_size: 0.1, initial_price: 80835.61 },
    PairConfig { symbol: "ETH/USDT", base_decimals: 6, price_decimals: 2, min_qty: 0.001, tick_size: 0.01, initial_price: 3245.8 },
    PairConfig { symbol: "SOL/USDT", base_decimals: 2, price_decimals: 3, min_qty: 0.01, tick_size: 0.001, initial_price: 178.42 },
    PairConfig { symbol: "BNB/USDT", base_decimals: 3, price_decimals: 2, min_qty: 0.01, tick_size: 0.01, initial_price: 605.2 },
    PairConfig { symbol: "XRP/USDT", base_decimals: 1, price_decimals: 4, min_qty: 1.0, tick_size: 0.0001, initial_price: 0.5234 },
    PairConfig { symbol: "ARB/USDT", base_decimals: 2, price_decimals: 4, min_qty: 1.0, tick_size: 0.0001, initial_price: 0.7821 },
    PairConfig { symbol: "OP/USDT", base_decimals: 2, price_decimals: 4, min_qty: 1.0, tick_size: 0.0001, initial_price: 1.953 },
    PairConfig { symbol: "DOGE/USDT", base_decimals: 0, price_decimals: 5, min_qty: 1.0, tick_size: 0.00001, initial_price: 0.12134 },
    PairConfig { symbol: "MATIC/USDT", base_decimals: 2, price_decimals: 4, min_qty: 1.0, tick_size: 0.0001, initial_price: 0.4821 },
    PairConfig { symbol: "AVAX/USDT", base_decimals: 2, price_decimals: 3, min_qty: 0.1, tick_size: 0.001, initial_price: 28.74 },
    PairConfig { symbol: "LINK/USDT", base_decimals: 2, price_decimals: 3, min_qty: 0.1, tick_size: 0.001, initial_price: 14.32 },
    PairConfig { symbol: "TON/USDT", base_decimals: 2, price_decimals: 3, min_qty: 0.1, tick_size: 0.001, initial_price: 5.21 },
];

// --- Data structures ---

#[derive(Clone, Debug)]
struct RestingOrder {
    id: String,
    side: Side,
    price: f64,
    qty: f64, // remaining
}

/// f64 wrapper with a total order so it can be a BTreeMap key (NaN is rejected at the API edge).
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct OrderedFloat(pub f64);

impl Eq for OrderedFloat {}
impl PartialOrd for OrderedFloat {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for OrderedFloat {
    fn cmp(&self, other: &Self) -> Ordering {
        self.0.total_cmp(&other.0)
    }
}

pub struct PairBook {
    pair: String,
    base_decimals: u8,
    price_decimals: u8,
    min_qty: f64,
    tick_size: f64,
    // BTreeMap = ordered price levels. Best bid = LAST key, best ask = FIRST key.
    // Each level is a FIFO queue (VecDeque → O(1) pop of the oldest order).
    bids: BTreeMap<OrderedFloat, VecDeque<RestingOrder>>,
    asks: BTreeMap<OrderedFloat, VecDeque<RestingOrder>>,
    /// order id → (side, price level) so cancel does not scan the whole book.
    order_index: HashMap<String, (Side, OrderedFloat)>,
    last_price: f64,
    book_subscribers: Vec<mpsc::Sender<BookUpdate>>,
    trade_subscribers: Vec<mpsc::Sender<Trade>>,
}

type PlaceResult = (Order, Vec<Trade>, bool, String);

fn round(val: f64, decimals: u8) -> f64 {
    let factor = 10f64.powi(decimals as i32);
    (val * factor).round() / factor
}

fn opposite(side: Side) -> Side {
    if side == Side::Buy { Side::Sell } else { Side::Buy }
}

/// Would an aggressor at `aggressor_price` (None = market) trade against a resting order?
fn crossable(resting_side: Side, resting_price: f64, aggressor_price: Option<f64>) -> bool {
    match aggressor_price {
        None => true,
        Some(ap) => {
            if resting_side == Side::Sell {
                ap >= resting_price // aggressor BUY crosses a SELL if price >= ask
            } else {
                ap <= resting_price // aggressor SELL crosses a BUY if price <= bid
            }
        }
    }
}

fn now_ms() -> u64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_millis() as u64).unwrap_or(0)
}

impl PairBook {
    pub fn new(pair: &str, base_dec: u8, _quote_dec: u8, price_dec: u8, min_qty: f64, tick: f64) -> Self {
        Self {
            pair: pair.to_string(),
            base_decimals: base_dec,
            price_decimals: price_dec,
            min_qty,
            tick_size: tick,
            bids: BTreeMap::new(),
            asks: BTreeMap::new(),
            order_index: HashMap::new(),
            last_price: 0.0,
            book_subscribers: Vec::new(),
            trade_subscribers: Vec::new(),
        }
    }

    /// Best price on the book of `side`: `Side::Buy` → best bid, `Side::Sell` → best ask.
    pub fn best_price(&self, side: Side) -> Option<f64> {
        match side {
            Side::Buy => self.bids.last_key_value().map(|(p, _)| p.0),
            Side::Sell => self.asks.first_key_value().map(|(p, _)| p.0),
            _ => None,
        }
    }

    /// Liquidity an aggressor could take, walking the opposite book best-price-first and
    /// stopping at the first level that no longer crosses (used by the FOK pre-flight check).
    fn available_liquidity(&self, aggressor_side: Side, limit: Option<f64>) -> f64 {
        let resting_side = opposite(aggressor_side);
        let levels: Box<dyn Iterator<Item = (&OrderedFloat, &VecDeque<RestingOrder>)> + '_> =
            if aggressor_side == Side::Buy { Box::new(self.asks.iter()) } else { Box::new(self.bids.iter().rev()) };
        let mut total = 0.0f64;
        for (price, queue) in levels {
            if !crossable(resting_side, price.0, limit) {
                break;
            }
            total += queue.iter().map(|o| o.qty).sum::<f64>();
        }
        round(total, self.base_decimals)
    }

    /// Seed the book with market-maker orders around the mid price.
    pub fn seed_book(&mut self, mid_price: f64, levels: usize, qty_each: f64) {
        for i in 1..=levels {
            let bid_price = round(mid_price - (i as f64) * self.tick_size, self.price_decimals);
            let ask_price = round(mid_price + (i as f64) * self.tick_size, self.price_decimals);
            let bid_qty = round(qty_each * (1.0 + rand::random::<f64>()), self.base_decimals);
            let ask_qty = round(qty_each * (1.0 + rand::random::<f64>()), self.base_decimals);
            self.rest(Side::Buy, Uuid::new_v4().to_string(), bid_price, bid_qty);
            self.rest(Side::Sell, Uuid::new_v4().to_string(), ask_price, ask_qty);
        }
        self.last_price = mid_price;
    }

    fn rest(&mut self, side: Side, id: String, price: f64, qty: f64) {
        let key = OrderedFloat(price);
        let book = if side == Side::Buy { &mut self.bids } else { &mut self.asks };
        book.entry(key).or_default().push_back(RestingOrder { id: id.clone(), side, price, qty });
        self.order_index.insert(id, (side, key));
    }

    fn reject(&self, req: &PlaceOrderRequest, reason: &str) -> PlaceResult {
        (self.make_order(req, OrderStatus::Rejected, 0.0), Vec::new(), false, reason.to_string())
    }

    /// Place an order — core matching logic.
    pub fn place_order(&mut self, req: &PlaceOrderRequest) -> PlaceResult {
        // --- Decode + validate (protobuf enums arrive as raw i32) ---
        let side = match Side::try_from(req.side) {
            Ok(s @ (Side::Buy | Side::Sell)) => s,
            _ => return self.reject(req, "Invalid side"),
        };
        let order_type = match OrderType::try_from(req.order_type) {
            Ok(OrderType::Unspecified) | Err(_) => return self.reject(req, "Invalid order type"),
            Ok(t) => t,
        };
        if !req.qty.is_finite() || req.qty <= 0.0 {
            return self.reject(req, "Quantity must be positive");
        }
        if req.qty < self.min_qty {
            return self.reject(req, "Quantity below minimum");
        }
        let price: Option<f64> = if order_type == OrderType::Market {
            None
        } else {
            match req.price {
                Some(p) if p.is_finite() && p > 0.0 => Some(p),
                _ => return self.reject(req, "Price must be a positive number"),
            }
        };
        let qty = req.qty;
        let opposite_side = opposite(side);

        // --- POST_ONLY: must not cross ---
        if order_type == OrderType::PostOnly {
            if let Some(best) = self.best_price(opposite_side) {
                if crossable(opposite_side, best, price) {
                    return self.reject(req, "POST_ONLY order would cross");
                }
            }
        }

        // --- FOK pre-flight: fill completely or not at all ---
        if order_type == OrderType::Fok && self.available_liquidity(side, price) + EPS < qty {
            let mut order = self.make_order(req, OrderStatus::Cancelled, 0.0);
            order.remaining_qty = 0.0;
            return (order, Vec::new(), false, "FOK_NOT_FILLABLE".to_string());
        }

        // --- Match against the opposite book (price-time priority) ---
        let order_id = Uuid::new_v4().to_string();
        let base_dec = self.base_decimals;
        let pair_name = self.pair.clone();
        let mut remaining = qty;
        let mut filled_qty = 0.0f64;
        let mut total_cost = 0.0f64;
        let mut trades: Vec<Trade> = Vec::new();
        let mut last_trade_price: Option<f64> = None;

        if order_type != OrderType::PostOnly {
            let hit_bids = side == Side::Sell; // a SELL aggressor consumes the BID book
            while remaining > EPS {
                let book = if hit_bids { &mut self.bids } else { &mut self.asks };
                // Best opposite level: highest bid, or lowest ask.
                let level = if hit_bids { book.last_entry() } else { book.first_entry() };
                let Some(mut level) = level else { break };
                if !crossable(opposite_side, level.key().0, price) {
                    break;
                }

                let queue = level.get_mut();
                while remaining > EPS {
                    let Some(resting) = queue.front_mut() else { break };
                    let fill_qty = remaining.min(resting.qty);
                    let fill_price = resting.price;

                    trades.push(Trade {
                        id: Uuid::new_v4().to_string(),
                        pair: pair_name.clone(),
                        price: fill_price,
                        qty: round(fill_qty, base_dec),
                        side: side as i32,
                        buyer_order_id: if side == Side::Buy { order_id.clone() } else { resting.id.clone() },
                        seller_order_id: if side == Side::Sell { order_id.clone() } else { resting.id.clone() },
                        timestamp: now_ms() as i64,
                    });
                    last_trade_price = Some(fill_price);

                    remaining = round(remaining - fill_qty, base_dec);
                    filled_qty = round(filled_qty + fill_qty, base_dec);
                    total_cost += fill_qty * fill_price;

                    resting.qty = round(resting.qty - fill_qty, base_dec);
                    if resting.qty <= EPS {
                        if let Some(done) = queue.pop_front() {
                            self.order_index.remove(&done.id); // disjoint field from `book`
                        }
                    }
                }
                if queue.is_empty() {
                    level.remove();
                }
            }
        }
        if let Some(p) = last_trade_price {
            self.last_price = p;
        }

        // --- Final status; rest the remainder of LIMIT / POST_ONLY orders ---
        let rests = remaining > EPS && matches!(order_type, OrderType::Limit | OrderType::PostOnly);
        let status = if rests {
            let p = price.unwrap_or_default(); // always Some for LIMIT / POST_ONLY (validated)
            self.rest(side, order_id.clone(), p, remaining);
            if filled_qty > 0.0 { OrderStatus::PartiallyFilled } else { OrderStatus::New }
        } else if remaining <= EPS {
            OrderStatus::Filled
        } else if filled_qty > 0.0 {
            OrderStatus::PartiallyFilled // IOC / MARKET: remainder cancelled
        } else {
            OrderStatus::Cancelled
        };

        let order = Order {
            id: order_id,
            pair: pair_name,
            side: side as i32,
            order_type: order_type as i32,
            price,
            qty,
            filled_qty,
            remaining_qty: if rests { remaining } else { 0.0 },
            status: status as i32,
            user_id: req.user_id.clone(),
            timestamp: now_ms() as i64,
            avg_fill_price: if filled_qty > 0.0 { Some(round(total_cost / filled_qty, self.price_decimals)) } else { None },
        };

        for t in &trades {
            self.notify_trade(t);
        }
        if !trades.is_empty() || rests {
            self.notify_book_update();
        }
        (order, trades, true, String::new())
    }

    /// Cancel a resting order by id (O(log n) via the order index).
    pub fn cancel_order(&mut self, order_id: &str) -> bool {
        let Some((side, key)) = self.order_index.remove(order_id) else { return false };
        let book = if side == Side::Buy { &mut self.bids } else { &mut self.asks };
        let mut removed = false;
        if let Some(queue) = book.get_mut(&key) {
            if let Some(pos) = queue.iter().position(|o| o.id == order_id) {
                queue.remove(pos);
                removed = true;
            }
            if queue.is_empty() {
                book.remove(&key);
            }
        }
        if removed {
            self.notify_book_update();
        }
        removed
    }

    /// Snapshot of the top `depth` levels per side.
    pub fn get_snapshot(&self, depth: usize) -> OrderBookSnapshot {
        let mut bids: Vec<BookLevel> = Vec::new();
        let mut asks: Vec<BookLevel> = Vec::new();
        let mut bid_total = 0.0f64;
        let mut ask_total = 0.0f64;

        for (price, queue) in self.bids.iter().rev().take(depth) {
            let qty: f64 = queue.iter().map(|o| o.qty).sum();
            bid_total += qty;
            bids.push(BookLevel {
                price: round(price.0, self.price_decimals),
                qty: round(qty, self.base_decimals),
                total: round(bid_total, self.base_decimals),
                order_count: queue.len() as u32,
            });
        }
        for (price, queue) in self.asks.iter().take(depth) {
            let qty: f64 = queue.iter().map(|o| o.qty).sum();
            ask_total += qty;
            asks.push(BookLevel {
                price: round(price.0, self.price_decimals),
                qty: round(qty, self.base_decimals),
                total: round(ask_total, self.base_decimals),
                order_count: queue.len() as u32,
            });
        }

        let best_bid = bids.first().map(|l| l.price).unwrap_or(0.0);
        let best_ask = asks.first().map(|l| l.price).unwrap_or(0.0);
        let both = best_bid > 0.0 && best_ask > 0.0;
        OrderBookSnapshot {
            pair: self.pair.clone(),
            bids,
            asks,
            spread: if both { round(best_ask - best_bid, self.price_decimals) } else { 0.0 },
            mid_price: if both { round((best_bid + best_ask) / 2.0, self.price_decimals) } else { self.last_price },
            last_price: self.last_price,
            timestamp: now_ms() as i64,
        }
    }

    fn make_order(&self, req: &PlaceOrderRequest, status: OrderStatus, filled: f64) -> Order {
        Order {
            id: Uuid::new_v4().to_string(),
            pair: self.pair.clone(),
            side: req.side,
            order_type: req.order_type,
            price: req.price,
            qty: req.qty,
            filled_qty: filled,
            remaining_qty: if status == OrderStatus::Rejected { req.qty } else { req.qty - filled },
            status: status as i32,
            user_id: req.user_id.clone(),
            timestamp: now_ms() as i64,
            avg_fill_price: None,
        }
    }

    fn notify_book_update(&mut self) {
        if self.book_subscribers.is_empty() {
            return; // don't build a 20-level snapshot nobody is listening to
        }
        let snap = self.get_snapshot(20);
        let update = BookUpdate {
            pair: snap.pair,
            bids: snap.bids,
            asks: snap.asks,
            last_price: snap.last_price,
            timestamp: snap.timestamp,
        };
        self.book_subscribers.retain(|tx| match tx.try_send(update.clone()) {
            Ok(()) => true,
            Err(mpsc::error::TrySendError::Full(_)) => true, // slow consumer: skip this snapshot, the next supersedes it
            Err(mpsc::error::TrySendError::Closed(_)) => false,
        });
    }

    fn notify_trade(&mut self, trade: &Trade) {
        // A consumer that cannot keep up must not silently miss trades: drop it so it reconnects.
        self.trade_subscribers.retain(|tx| tx.try_send(trade.clone()).is_ok());
    }
}

// --- The gRPC service ---

pub struct EngineService {
    books: Arc<DashMap<String, RwLock<PairBook>>>,
    start_time: SystemTime,
    orders_processed: AtomicU64,
}

impl Default for EngineService {
    fn default() -> Self {
        Self::new()
    }
}

impl EngineService {
    pub fn new() -> Self {
        let books = Arc::new(DashMap::new());
        for c in TRADING_PAIRS {
            let book = PairBook::new(c.symbol, c.base_decimals, 2, c.price_decimals, c.min_qty, c.tick_size);
            books.insert(c.symbol.to_string(), RwLock::new(book));
        }
        Self { books, start_time: SystemTime::now(), orders_processed: AtomicU64::new(0) }
    }

    /// Seed every pair with market-maker liquidity around its initial price.
    pub fn seed_all_pairs(&self) {
        for c in TRADING_PAIRS {
            if let Some(entry) = self.books.get(c.symbol) {
                let qty = if c.symbol.starts_with("BTC") { 0.4 } else if c.symbol.starts_with("ETH") { 1.2 } else { 50.0 };
                entry.write().seed_book(c.initial_price, 14, qty);
            }
        }
    }

    fn book(&self, pair: &str) -> Result<dashmap::mapref::one::Ref<'_, String, RwLock<PairBook>>, Status> {
        self.books.get(pair).ok_or_else(|| Status::not_found(format!("Unknown pair: {pair}")))
    }
}

type BoxStream<T> = Pin<Box<dyn Stream<Item = Result<T, Status>> + Send>>;

#[tonic::async_trait]
impl MatchingEngine for EngineService {
    async fn place_order(&self, request: Request<PlaceOrderRequest>) -> Result<Response<PlaceOrderResponse>, Status> {
        let req = request.into_inner();
        tracing::debug!("place_order pair={} side={} type={} qty={} user={}", req.pair, req.side, req.order_type, req.qty, req.user_id);

        let (order, trades, ok, reject_reason) = self.book(&req.pair)?.write().place_order(&req);
        self.orders_processed.fetch_add(1, AtomicOrdering::Relaxed);
        Ok(Response::new(PlaceOrderResponse { order: Some(order), trades, ok, reject_reason }))
    }

    async fn cancel_order(&self, request: Request<CancelOrderRequest>) -> Result<Response<CancelOrderResponse>, Status> {
        let req = request.into_inner();
        // NOTE: the proto carries no user id, so ownership MUST be verified by the caller (Trading Service).
        let ok = self.book(&req.pair)?.write().cancel_order(&req.order_id);
        Ok(Response::new(CancelOrderResponse { ok }))
    }

    async fn get_snapshot(&self, request: Request<SnapshotRequest>) -> Result<Response<OrderBookSnapshot>, Status> {
        let req = request.into_inner();
        let depth = if req.depth > 0 { (req.depth as usize).min(MAX_SNAPSHOT_DEPTH) } else { 20 };
        let snapshot = self.book(&req.pair)?.read().get_snapshot(depth);
        Ok(Response::new(snapshot))
    }

    type StreamBookUpdatesStream = BoxStream<BookUpdate>;

    async fn stream_book_updates(&self, request: Request<StreamRequest>) -> Result<Response<Self::StreamBookUpdatesStream>, Status> {
        let req = request.into_inner();
        let (tx, rx) = mpsc::channel(SUBSCRIBER_BUFFER);
        self.book(&req.pair)?.write().book_subscribers.push(tx); // unknown pair → NOT_FOUND (was: a stream that never yields)
        Ok(Response::new(Box::pin(ReceiverStream::new(rx).map(Ok))))
    }

    type StreamTradesStream = BoxStream<Trade>;

    async fn stream_trades(&self, request: Request<StreamRequest>) -> Result<Response<Self::StreamTradesStream>, Status> {
        let req = request.into_inner();
        let (tx, rx) = mpsc::channel(SUBSCRIBER_BUFFER);
        self.book(&req.pair)?.write().trade_subscribers.push(tx);
        Ok(Response::new(Box::pin(ReceiverStream::new(rx).map(Ok))))
    }

    async fn health(&self, _request: Request<HealthRequest>) -> Result<Response<HealthResponse>, Status> {
        Ok(Response::new(HealthResponse {
            ready: true,
            version: env!("CARGO_PKG_VERSION").to_string(),
            uptime_seconds: self.start_time.elapsed().map(|d| d.as_secs()).unwrap_or(0),
            orders_processed: self.orders_processed.load(AtomicOrdering::Relaxed),
        }))
    }
}
