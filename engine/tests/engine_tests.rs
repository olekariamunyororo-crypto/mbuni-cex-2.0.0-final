// Mbuni CEX 2.0 — Matching engine integration tests
//
// Same invariants as the TypeScript suite, plus regression tests for the SELL-side
// matching bug (the old loop walked the bid book lowest-price-first).

use mbuni_matching_engine::matching_engine::{EngineService, PairBook};
use mbuni_matching_engine::proto::*;

fn make_pair() -> PairBook {
    let mut book = PairBook::new("BTC/USDT", 8, 2, 2, 0.0001, 0.1);
    book.seed_book(50000.0, 6, 1.0);
    book
}

fn req(side: Side, order_type: OrderType, price: Option<f64>, qty: f64) -> PlaceOrderRequest {
    req_user(side, order_type, price, qty, "test_user")
}

fn req_user(side: Side, order_type: OrderType, price: Option<f64>, qty: f64, user: &str) -> PlaceOrderRequest {
    PlaceOrderRequest {
        pair: "BTC/USDT".to_string(),
        side: side as i32,
        order_type: order_type as i32,
        price,
        qty,
        user_id: user.to_string(),
        client_order_id: String::new(),
    }
}

#[test]
fn seed_book_populates_bids_and_asks() {
    let snap = make_pair().get_snapshot(20);
    assert!(!snap.bids.is_empty() && !snap.asks.is_empty());
    assert!(snap.bids[0].price < snap.asks[0].price);
}

#[test]
fn limit_order_rests_on_book() {
    let mut book = make_pair();
    let (order, trades, ok, _) = book.place_order(&req(Side::Buy, OrderType::Limit, Some(49000.0), 0.5));
    assert!(ok);
    assert_eq!(order.status, OrderStatus::New as i32);
    assert_eq!(order.remaining_qty, 0.5);
    assert!(trades.is_empty());
    assert!(book.get_snapshot(20).bids.iter().any(|l| l.price == 49000.0));
}

#[test]
fn buy_limit_crosses_and_fills_at_best_ask() {
    let mut book = make_pair();
    let best_ask = book.best_price(Side::Sell).unwrap();
    let (order, trades, ok, _) = book.place_order(&req(Side::Buy, OrderType::Limit, Some(best_ask), 0.1));
    assert!(ok);
    assert_eq!(order.status, OrderStatus::Filled as i32);
    assert_eq!(order.filled_qty, 0.1);
    assert_eq!(trades[0].price, best_ask);
}

// ---- Regression: SELL aggressors must hit the HIGHEST bid first ----

#[test]
fn market_sell_fills_at_best_bid() {
    let mut book = make_pair();
    let best_bid = book.best_price(Side::Buy).unwrap();
    let (order, trades, ok, _) = book.place_order(&req(Side::Sell, OrderType::Market, None, 0.1));
    assert!(ok);
    assert_eq!(order.status, OrderStatus::Filled as i32);
    assert!(!trades.is_empty());
    assert_eq!(trades[0].price, best_bid, "market SELL must start at the best (highest) bid");
}

#[test]
fn limit_sell_crossing_the_book_executes() {
    let mut book = make_pair();
    let best_bid = book.best_price(Side::Buy).unwrap();
    let (order, trades, _, _) = book.place_order(&req(Side::Sell, OrderType::Limit, Some(best_bid), 0.1));
    assert_eq!(order.status, OrderStatus::Filled as i32);
    assert_eq!(trades[0].price, best_bid);
}

#[test]
fn sell_walks_bids_in_descending_price_order() {
    let mut book = make_pair();
    // Larger than the top bid level so it must walk several levels.
    let (_, trades, _, _) = book.place_order(&req(Side::Sell, OrderType::Market, None, 3.0));
    assert!(trades.len() >= 2);
    assert!(trades.windows(2).all(|w| w[0].price >= w[1].price), "bid levels must be consumed high → low");
}

#[test]
fn buy_walks_asks_in_ascending_price_order() {
    let mut book = make_pair();
    let (_, trades, _, _) = book.place_order(&req(Side::Buy, OrderType::Market, None, 3.0));
    assert!(trades.len() >= 2);
    assert!(trades.windows(2).all(|w| w[0].price <= w[1].price));
}

#[test]
fn time_priority_within_a_price_level() {
    let mut book = PairBook::new("BTC/USDT", 8, 2, 2, 0.0001, 0.1);
    let (first, _, _, _) = book.place_order(&req_user(Side::Buy, OrderType::Limit, Some(100.0), 1.0, "a"));
    let (second, _, _, _) = book.place_order(&req_user(Side::Buy, OrderType::Limit, Some(100.0), 1.0, "b"));
    let (_, trades, _, _) = book.place_order(&req(Side::Sell, OrderType::Market, None, 1.0));
    assert_eq!(trades.len(), 1);
    assert_eq!(trades[0].buyer_order_id, first.id, "oldest order at the level fills first");
    assert_ne!(trades[0].buyer_order_id, second.id);
}

#[test]
fn market_order_fills_against_book() {
    let mut book = make_pair();
    let (order, trades, ok, _) = book.place_order(&req(Side::Buy, OrderType::Market, None, 0.1));
    assert!(ok);
    assert_eq!(order.status, OrderStatus::Filled as i32);
    assert!(!trades.is_empty());
}

#[test]
fn market_order_on_empty_book_is_cancelled_not_resting() {
    let mut book = PairBook::new("BTC/USDT", 8, 2, 2, 0.0001, 0.1);
    let (order, trades, _, _) = book.place_order(&req(Side::Sell, OrderType::Market, None, 1.0));
    assert_eq!(order.status, OrderStatus::Cancelled as i32);
    assert!(trades.is_empty());
    assert!(book.get_snapshot(20).asks.is_empty());
}

#[test]
fn ioc_cancels_remainder() {
    let mut book = make_pair();
    let best_ask = book.best_price(Side::Sell).unwrap();
    let (order, _, ok, _) = book.place_order(&req(Side::Buy, OrderType::Ioc, Some(best_ask + 1000.0), 1000.0));
    assert!(ok);
    assert!(order.filled_qty > 0.0 && order.filled_qty < 1000.0);
    assert_eq!(order.status, OrderStatus::PartiallyFilled as i32);
    assert_eq!(order.remaining_qty, 0.0);
}

#[test]
fn fok_all_or_nothing_both_sides() {
    let mut book = make_pair();
    let best_ask = book.best_price(Side::Sell).unwrap();
    let (order, _, ok, _) = book.place_order(&req(Side::Buy, OrderType::Fok, Some(best_ask), 0.1));
    assert!(ok);
    assert_eq!(order.status, OrderStatus::Filled as i32);

    let (order, trades, ok, reason) = book.place_order(&req(Side::Buy, OrderType::Fok, Some(best_ask + 10000.0), 100000.0));
    assert!(!ok);
    assert_eq!(reason, "FOK_NOT_FILLABLE");
    assert_eq!(order.status, OrderStatus::Cancelled as i32);
    assert!(trades.is_empty());

    // SELL side must work too
    let best_bid = book.best_price(Side::Buy).unwrap();
    let before = book.get_snapshot(20);
    let (order, trades, _, _) = book.place_order(&req(Side::Sell, OrderType::Fok, Some(best_bid - 10000.0), 100000.0));
    assert_eq!(order.status, OrderStatus::Cancelled as i32);
    assert!(trades.is_empty());
    assert_eq!(before.bids.len(), book.get_snapshot(20).bids.len(), "failed FOK must not touch the book");
    let (order, _, ok, _) = book.place_order(&req(Side::Sell, OrderType::Fok, Some(best_bid - 10000.0), 0.1));
    assert!(ok);
    assert_eq!(order.status, OrderStatus::Filled as i32);
}

#[test]
fn post_only_never_crosses() {
    let mut book = make_pair();
    let best_ask = book.best_price(Side::Sell).unwrap();
    let (order, trades, ok, _) = book.place_order(&req(Side::Buy, OrderType::PostOnly, Some(best_ask), 0.5));
    assert!(!ok);
    assert_eq!(order.status, OrderStatus::Rejected as i32);
    assert!(trades.is_empty());

    let best_bid = book.best_price(Side::Buy).unwrap();
    let (order, _, ok, _) = book.place_order(&req(Side::Buy, OrderType::PostOnly, Some(best_bid - 100.0), 0.5));
    assert!(ok);
    assert_eq!(order.status, OrderStatus::New as i32);

    // and a SELL post-only at/below the best bid is rejected
    let (order, _, ok, _) = book.place_order(&req(Side::Sell, OrderType::PostOnly, Some(best_bid), 0.5));
    assert!(!ok);
    assert_eq!(order.status, OrderStatus::Rejected as i32);
}

#[test]
fn cancel_removes_order_and_is_idempotent() {
    let mut book = make_pair();
    let (order, _, ok, _) = book.place_order(&req(Side::Buy, OrderType::Limit, Some(49000.0), 0.5));
    assert!(ok);
    assert!(book.cancel_order(&order.id));
    assert!(!book.get_snapshot(20).bids.iter().any(|l| l.price == 49000.0));
    assert!(!book.cancel_order(&order.id), "second cancel must report false");
    assert!(!book.cancel_order("does-not-exist"));
}

#[test]
fn filled_resting_order_cannot_be_cancelled() {
    let mut book = PairBook::new("BTC/USDT", 8, 2, 2, 0.0001, 0.1);
    let (maker, _, _, _) = book.place_order(&req(Side::Buy, OrderType::Limit, Some(100.0), 1.0));
    book.place_order(&req(Side::Sell, OrderType::Market, None, 1.0));
    assert!(!book.cancel_order(&maker.id));
}

#[test]
fn no_crossed_book_after_random_orders_both_sides() {
    let mut book = make_pair();
    for _ in 0..500 {
        let side = if rand::random() { Side::Buy } else { Side::Sell };
        let price = 49990.0 + rand::random::<f64>() * 20.0;
        let qty = 0.001 + rand::random::<f64>() * 2.0;
        let t = match rand::random::<u8>() % 4 {
            0 => OrderType::Limit,
            1 => OrderType::Ioc,
            2 => OrderType::PostOnly,
            _ => OrderType::Limit,
        };
        book.place_order(&req(side, t, Some(price), qty));
        let snap = book.get_snapshot(20);
        if !snap.bids.is_empty() && !snap.asks.is_empty() {
            assert!(snap.bids[0].price < snap.asks[0].price, "crossed book: {} >= {}", snap.bids[0].price, snap.asks[0].price);
        }
    }
}

#[test]
fn quantity_is_conserved_on_every_fill() {
    let mut book = make_pair();
    for side in [Side::Buy, Side::Sell] {
        let (order, trades, _, _) = book.place_order(&req(side, OrderType::Market, None, 2.5));
        let traded: f64 = trades.iter().map(|t| t.qty).sum();
        assert!((traded - order.filled_qty).abs() < 1e-8);
        assert!((order.filled_qty + order.remaining_qty - order.qty).abs() < 1e-8 || order.remaining_qty == 0.0);
    }
}

#[test]
fn invalid_input_is_rejected() {
    let mut book = make_pair();
    for (price, qty) in [(Some(49000.0), 0.0), (Some(49000.0), -1.0), (Some(49000.0), f64::NAN), (Some(0.0), 1.0), (Some(f64::NAN), 1.0), (None, 1.0)] {
        let (order, _, ok, _) = book.place_order(&req(Side::Buy, OrderType::Limit, price, qty));
        assert!(!ok, "price={price:?} qty={qty} should be rejected");
        assert_eq!(order.status, OrderStatus::Rejected as i32);
    }
    let mut bad = req(Side::Buy, OrderType::Limit, Some(1.0), 1.0);
    bad.side = 0; // UNSPECIFIED
    assert!(!book.place_order(&bad).2);
    bad.side = 99; // unknown enum value
    assert!(!book.place_order(&bad).2);
}

#[test]
fn engine_service_boots_and_seeds() {
    let svc = EngineService::new();
    svc.seed_all_pairs();
}
