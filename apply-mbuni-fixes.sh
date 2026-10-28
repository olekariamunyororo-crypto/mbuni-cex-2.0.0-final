#!/usr/bin/env bash
# Mbuni CEX 2.0 — fix script. Run from the project root:  bash apply-mbuni-fixes.sh
# Writes the corrected files (originals saved next to them as *.orig), removes dead files.
set -euo pipefail
[ -f package.json ] && [ -d engine ] || { echo "Run from the mbuni-cex project root"; exit 1; }
w(){ mkdir -p "$(dirname "$1")"; [ -f "$1" ] && [ ! -f "$1.orig" ] && cp "$1" "$1.orig"; cat > "$1"; echo "  wrote $1"; }

w 'Dockerfile' <<'MBUNI_EOF_7f3a'
# syntax=docker/dockerfile:1.7

# =============================================================================
# Mbuni CEX — multi-stage Dockerfile
#
# Stages:
#   1. deps      — install production node_modules
#   2. builder   — install ALL deps, generate Prisma client, build Next.js
#   3. runner    — minimal runtime image with standalone Next.js server
#
# Build:
#   docker build -t mbuni-cex:latest .
#
# Run (with docker-compose.yml):
#   docker compose up -d --build
# =============================================================================

# ---------- Stage 1: deps ----------
FROM oven/bun:1.3 AS deps
WORKDIR /app

# Copy only lockfile + package.json for layer caching
COPY package.json bun.lock ./

# Install ALL dependencies (we need devDependencies for the build)
RUN bun install --frozen-lockfile

# ---------- Stage 2: builder ----------
FROM oven/bun:1.3 AS builder
WORKDIR /app

# Copy installed node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source
COPY . .

# Build-time env (no secrets here — runtime env is injected at deploy time)
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# The repo's schema uses SQLite for local dev/CI; the production image talks to
# PostgreSQL (see docker-compose.yml / k8s). Switch the provider at build time.
ARG DB_PROVIDER=postgresql
RUN sed -i "s/provider = \"sqlite\"/provider = \"${DB_PROVIDER}\"/" prisma/schema.prisma

# Generate Prisma client + build Next.js (produces .next/standalone/)
RUN bun run db:generate
RUN bun run build

# ---------- Stage 3: runner ----------
FROM oven/bun:1.3 AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Create a non-root user for security
RUN addgroup --system --gid 1001 nodejs \
 && adduser --system --uid 1001 nextjs

# Copy the standalone Next.js server (already includes minimal node_modules)
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Prisma client + schema (needed at runtime for db:push / migrations)
COPY --from=builder --chown=nextjs:nodejs /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder --chown=nextjs:nodejs /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=builder --chown=nextjs:nodejs /app/prisma ./prisma
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./package.json

# Switch to non-root user
USER nextjs

EXPOSE 3000

# Health check — /api/session returns 200 even when not authenticated
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD bun -e "fetch('http://localhost:3000/api/session').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["bun", "server.js"]
MBUNI_EOF_7f3a
w 'docker-compose-2.0.yml' <<'MBUNI_EOF_7f3a'
# Mbuni CEX 2.0 — Full microservices stack
#
# Services:
#   engine      — Rust matching engine (gRPC :50051)
#   trading     — Go trading service  (HTTP :8080)
#   wallet      — Go wallet service   (HTTP :8081)
#   marketdata  — Go market data      (HTTP :8082)
#   compliance  — Go compliance        (HTTP :8083)
#   db          — PostgreSQL 17
#   nats        — NATS JetStream
#   dragonfly   — Dragonfly (Redis-compatible cache)
#   caddy       — Reverse proxy + auto-TLS
#
# Usage:
#   docker compose -f docker-compose-2.0.yml up -d --build

services:
  engine:
    build:
      context: .
      dockerfile: engine/Dockerfile
    container_name: mbuni-engine
    restart: unless-stopped
    ports:
      - "127.0.0.1:50051:50051"
    environment:
      RUST_LOG: info
    networks:
      - mbuni-net

  trading:
    build:
      context: .
      dockerfile: services/Dockerfile
      args:
        SERVICE_NAME: trading
    container_name: mbuni-trading
    restart: unless-stopped
    depends_on:
      engine:
        condition: service_started
      db:
        condition: service_healthy
      nats:
        condition: service_started
    environment:
      PORT: "8080"
      ENGINE_ADDR: "engine:50051"
      DATABASE_URL: "postgresql://mbuni:${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}@db:5432/mbuni_cex?sslmode=disable"
      NATS_URL: "nats://nats:4222"
      REDIS_URL: "redis://dragonfly:6379"
    ports:
      - "127.0.0.1:8080:8080"
    networks:
      - mbuni-net

  wallet:
    build:
      context: .
      dockerfile: services/Dockerfile
      args:
        SERVICE_NAME: wallet
    container_name: mbuni-wallet
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
      nats:
        condition: service_started
    environment:
      PORT: "8081"
      DATABASE_URL: "postgresql://mbuni:${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}@db:5432/mbuni_cex?sslmode=disable"
      NATS_URL: "nats://nats:4222"
    ports:
      - "127.0.0.1:8081:8081"
    networks:
      - mbuni-net

  marketdata:
    build:
      context: .
      dockerfile: services/Dockerfile
      args:
        SERVICE_NAME: marketdata
    container_name: mbuni-marketdata
    restart: unless-stopped
    depends_on: [engine, dragonfly]
    environment:
      PORT: "8082"
      ENGINE_ADDR: "engine:50051"
      REDIS_URL: "redis://dragonfly:6379"
    ports:
      - "127.0.0.1:8082:8082"
    networks:
      - mbuni-net

  compliance:
    build:
      context: .
      dockerfile: services/Dockerfile
      args:
        SERVICE_NAME: compliance
    container_name: mbuni-compliance
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      PORT: "8083"
      DATABASE_URL: "postgresql://mbuni:${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}@db:5432/mbuni_cex?sslmode=disable"
    ports:
      - "127.0.0.1:8083:8083"
    networks:
      - mbuni-net

  db:
    image: postgres:17-alpine
    container_name: mbuni-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: mbuni
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}
      POSTGRES_DB: mbuni_cex
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mbuni"]
      interval: 5s
      timeout: 3s
      retries: 10
    networks:
      - mbuni-net

  nats:
    image: nats:2.10-alpine
    container_name: mbuni-nats
    restart: unless-stopped
    command: ["--jetstream", "--store_dir", "/data"]
    volumes:
      - natsdata:/data
    ports:
      - "127.0.0.1:4222:4222"
      - "127.0.0.1:8222:8222"  # monitoring
    networks:
      - mbuni-net

  dragonfly:
    image: docker.dragonflydb.io/dragonflydb/dragonfly:v1.25.0
    container_name: mbuni-dragonfly
    restart: unless-stopped
    volumes:
      - dragonflydata:/data
    ports:
      - "127.0.0.1:6379:6379"
    networks:
      - mbuni-net

  caddy:
    image: caddy:2.8-alpine
    container_name: mbuni-caddy
    restart: unless-stopped
    depends_on: [trading, wallet, marketdata, compliance]
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./infra/caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    environment:
      DOMAIN: ${DOMAIN:-localhost}
    networks:
      - mbuni-net

volumes:
  pgdata:
  natsdata:
  dragonflydata:
  caddy_data:
  caddy_config:

networks:
  mbuni-net:
    driver: bridge
MBUNI_EOF_7f3a
w 'engine/Cargo.toml' <<'MBUNI_EOF_7f3a'
[package]
name = "mbuni-matching-engine"
version = "2.0.0"
edition = "2021"
description = "Mbuni CEX 2.0 — High-performance matching engine in Rust (Tokio + Tonic)"
license = "MIT"

[lib]
name = "mbuni_matching_engine"
path = "src/lib.rs"

[[bin]]
name = "mbuni-engine"
path = "src/main.rs"

[dependencies]
tonic = "0.12"
prost = "0.13"
tokio = { version = "1.40", features = ["full"] }
tokio-stream = "0.1"
dashmap = "6.1"
parking_lot = "0.12"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
rand = "0.8"
uuid = { version = "1.10", features = ["v4"] }

[build-dependencies]
tonic-build = "0.12"

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
panic = "abort"
MBUNI_EOF_7f3a
w 'engine/Dockerfile' <<'MBUNI_EOF_7f3a'
# Mbuni CEX 2.0 — Rust Matching Engine Dockerfile
FROM rust:1.88-slim AS builder
WORKDIR /app

# Install protoc + build deps
RUN apt-get update && apt-get install -y protobuf-compiler pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

# Copy proto files
COPY proto/ /app/proto/

# Copy engine source
COPY engine/ /app/engine/

WORKDIR /app/engine
# Commit engine/Cargo.lock (cargo generate-lockfile) for reproducible builds, then use --locked
RUN cargo build --release

# --- Runtime ---
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/engine/target/release/mbuni-engine /app/mbuni-engine

EXPOSE 50051
RUN useradd -r -u 1001 mbuni
USER mbuni
CMD ["/app/mbuni-engine"]
MBUNI_EOF_7f3a
w 'engine/build.rs' <<'MBUNI_EOF_7f3a'
// Build script — compiles ../proto/matching_engine.proto into Rust (tonic/prost).
// The generated code lands in OUT_DIR and is pulled in with `tonic::include_proto!`
// (see src/lib.rs); nothing is written into src/.
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let proto = "../proto/matching_engine.proto";
    tonic_build::configure()
        .build_server(true)
        .build_client(false) // engine is server-only
        .compile_protos(&[proto], &["../proto"])?;
    println!("cargo:rerun-if-changed={proto}");
    println!("cargo:rerun-if-changed=build.rs");
    Ok(())
}
MBUNI_EOF_7f3a
w 'engine/src/lib.rs' <<'MBUNI_EOF_7f3a'
//! Mbuni CEX 2.0 — matching engine library.
//!
//! The gRPC binary lives in `main.rs`; keeping the logic in a library crate lets
//! `tests/` (integration tests) and benchmarks import it.

pub mod matching_engine;

/// Generated protobuf + gRPC code for package `mbuni.v1`.
pub mod proto {
    tonic::include_proto!("mbuni.v1");
}
MBUNI_EOF_7f3a
w 'engine/src/main.rs' <<'MBUNI_EOF_7f3a'
// Mbuni CEX 2.0 — Matching Engine entry point
//
// Runs the Rust matching engine as a gRPC server (default 0.0.0.0:50051).
// Consumed by the Go Trading Service.
//
// Build:  cargo build --release
// Run:    ./target/release/mbuni-engine         (ENGINE_ADDR=host:port, RUST_LOG=info)
// Test:   cargo test

use std::net::SocketAddr;

use mbuni_matching_engine::matching_engine::EngineService;
use mbuni_matching_engine::proto::matching_engine_server::MatchingEngineServer;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Honour RUST_LOG (the old hard-coded filter matched no crate name, so logs were swallowed).
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")))
        .init();

    let addr: SocketAddr = std::env::var("ENGINE_ADDR")
        .unwrap_or_else(|_| "0.0.0.0:50051".to_string())
        .parse()?;
    tracing::info!("Mbuni CEX Matching Engine v2.0.0 starting on {}", addr);

    let engine = EngineService::new();
    engine.seed_all_pairs();
    tracing::info!("order books seeded; ready to accept orders");

    tonic::transport::Server::builder()
        .add_service(MatchingEngineServer::new(engine))
        .serve_with_shutdown(addr, shutdown_signal())
        .await?;

    tracing::info!("shutdown complete");
    Ok(())
}

async fn shutdown_signal() {
    #[cfg(unix)]
    {
        use tokio::signal::unix::{signal, SignalKind};
        if let Ok(mut term) = signal(SignalKind::terminate()) {
            tokio::select! {
                _ = tokio::signal::ctrl_c() => {}
                _ = term.recv() => {}
            }
            return;
        }
    }
    let _ = tokio::signal::ctrl_c().await;
}
MBUNI_EOF_7f3a
w 'engine/src/matching_engine.rs' <<'MBUNI_EOF_7f3a'
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
MBUNI_EOF_7f3a
w 'engine/tests/engine_tests.rs' <<'MBUNI_EOF_7f3a'
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
MBUNI_EOF_7f3a
w 'eslint.config.mjs' <<'MBUNI_EOF_7f3a'
import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import nextTypescript from "eslint-config-next/typescript";
import { dirname } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const eslintConfig = [...nextCoreWebVitals, ...nextTypescript, {
  rules: {
    // TypeScript rules
    "@typescript-eslint/no-explicit-any": "off",
    "@typescript-eslint/no-unused-vars": "off",
    "@typescript-eslint/no-non-null-assertion": "off",
    "@typescript-eslint/ban-ts-comment": "off",
    "@typescript-eslint/prefer-as-const": "off",
    "@typescript-eslint/no-unused-disable-directive": "off",
    
    // React rules
    "react-hooks/exhaustive-deps": "off",
    "react-hooks/purity": "off",
    "react/no-unescaped-entities": "off",
    "react/display-name": "off",
    "react/prop-types": "off",
    "react-compiler/react-compiler": "off",
    
    // Next.js rules
    "@next/next/no-img-element": "off",
    "@next/next/no-html-link-for-pages": "off",
    
    // General JavaScript rules
    "prefer-const": "off",
    "no-unused-vars": "off",
    "no-console": "off",
    "no-debugger": "off",
    "no-empty": "off",
    "no-irregular-whitespace": "off",
    "no-case-declarations": "off",
    "no-fallthrough": "off",
    "no-mixed-spaces-and-tabs": "off",
    "no-redeclare": "off",
    "no-undef": "off",
    "no-unreachable": "off",
    "no-useless-escape": "off",
  },
}, {
  // Vendored shadcn/ui primitives — not our code (same exclusion as vitest coverage)
  files: ["src/components/ui/**"],
  rules: { "react-hooks/set-state-in-effect": "off" },
}, {
  ignores: [
    "node_modules/**",
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
    "examples/**",
    "skills/**",
    // Build artifacts
    "storybook-static/**",
    "coverage/**",
    "playwright-report/**",
    "test-results/**",
    // Prisma generated client
    "node_modules/.prisma/**",
  ]
}];

export default eslintConfig;
MBUNI_EOF_7f3a
w 'next.config.ts' <<'MBUNI_EOF_7f3a'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  poweredByHeader: false,
  // Type errors must fail the build — `ignoreBuildErrors: true` used to hide them.
  reactStrictMode: false,
};

export default nextConfig;
MBUNI_EOF_7f3a
w 'prisma/seed.ts' <<'MBUNI_EOF_7f3a'
// =============================================================================
// Mbuni CEX — Prisma database seed
//
// Run with:  bun run db:seed   (or:  just db-seed  /  make db-seed)
//
// This seeds the REAL database (PostgreSQL in prod, SQLite in dev) with:
//   - 1 admin user
//   - 4 demo users (different KYC tiers + onboarding states)
//   - Trading pair configuration (10 pairs)
//   - Fee schedule (6 tiers, 0–18 bps)
//
// It's idempotent — safe to run multiple times. Existing records are skipped.
//
// NOTE: This is different from `src/lib/opencex/seed.ts`, which is in-memory
// demo data for the browser matching engine (orders, trades, klines, etc.).
// That data is regenerated on every page load. This seed.ts creates real
// persistent DB records for users, pairs, and fees.
// =============================================================================

import { db } from "../src/lib/db";
import bcrypt from "bcryptjs";

// ----- Helpers -----

const IS_PROD = process.env.NODE_ENV === "production";

// Demo accounts have publicly known passwords. Never seed them into production
// unless explicitly forced, and require a real admin password when you do.
if (IS_PROD && process.env.SEED_ALLOW_PRODUCTION !== "true") {
  console.error("Refusing to seed demo users in production (set SEED_ALLOW_PRODUCTION=true to override).");
  process.exit(1);
}
const ADMIN_PASSWORD = process.env.SEED_ADMIN_PASSWORD ?? (IS_PROD ? "" : "adminpass123");
if (!ADMIN_PASSWORD) {
  console.error("SEED_ADMIN_PASSWORD is required when seeding in production.");
  process.exit(1);
}

const log = (msg: string) => console.log(`  ✓ ${msg}`);
const skip = (msg: string) => console.log(`  → ${msg} (already exists)`);

async function upsertUser(params: {
  email: string;
  name: string;
  password: string;
  kycStatus?: "NONE" | "PENDING" | "VERIFIED" | "REJECTED";
  tier?: number;
  twoFA?: boolean;
  passkey?: boolean;
  onboardingComplete?: boolean;
  onboarding?: {
    experience: "NOVICE" | "INTERMEDIATE" | "PRO" | "INSTITUTIONAL";
    followedPairs: string[];
    enable2FA: boolean;
    passkeyEnrolled: boolean;
    acceptedTerms: boolean;
  } | null;
}) {
  const existing = await db.user.findUnique({ where: { email: params.email } });
  if (existing) {
    skip(`user ${params.email}`);
    return existing;
  }
  const passwordHash = await bcrypt.hash(params.password, 10);
  const user = await db.user.create({
    data: {
      email: params.email,
      name: params.name,
      passwordHash,
      kycStatus: params.kycStatus ?? "NONE",
      tier: params.tier ?? 0,
      twoFA: params.twoFA ?? false,
      passkey: params.passkey ?? false,
      onboardingComplete: params.onboardingComplete ?? false,
    },
  });
  if (params.onboarding) {
    await db.onboarding.create({
      data: {
        userId: user.id,
        experience: params.onboarding.experience,
        followedPairs: params.onboarding.followedPairs.join(","),
        enable2FA: params.onboarding.enable2FA,
        passkeyEnrolled: params.onboarding.passkeyEnrolled,
        acceptedTerms: params.onboarding.acceptedTerms,
      },
    });
  }
  log(IS_PROD ? `user ${params.email}` : `user ${params.email} (password: ${params.password})`);
  return user;
}

// ----- Main -----

async function main() {
  console.log("\n🌱 Seeding Mbuni CEX database...\n");

  // ----- Users -----
  console.log("Users:");

  await upsertUser({
    email: "admin@mbuni.cex",
    name: "Exchange Admin",
    password: ADMIN_PASSWORD,
    kycStatus: "VERIFIED",
    tier: 5,
    twoFA: true,
    passkey: true,
    onboardingComplete: true,
    onboarding: {
      experience: "INSTITUTIONAL",
      followedPairs: ["BTC/USDT", "ETH/USDT", "SOL/USDT"],
      enable2FA: true,
      passkeyEnrolled: true,
      acceptedTerms: true,
    },
  });

  await upsertUser({
    email: "alex.demo@mbuni.cex",
    name: "Alex Trader",
    password: "testpass123",
    kycStatus: "VERIFIED",
    tier: 3,
    twoFA: true,
    passkey: true,
    onboardingComplete: true,
    onboarding: {
      experience: "PRO",
      followedPairs: ["BTC/USDT", "ETH/USDT", "SOL/USDT"],
      enable2FA: true,
      passkeyEnrolled: true,
      acceptedTerms: true,
    },
  });

  await upsertUser({
    email: "bobby.trader@example.com",
    name: "Bobby Trader",
    password: "testpass123",
    kycStatus: "VERIFIED",
    tier: 2,
    twoFA: true,
    passkey: false,
    onboardingComplete: true,
    onboarding: {
      experience: "INTERMEDIATE",
      followedPairs: ["BTC/USDT", "ETH/USDT"],
      enable2FA: true,
      passkeyEnrolled: false,
      acceptedTerms: true,
    },
  });

  await upsertUser({
    email: "carol.newbie@example.com",
    name: "Carol Newbie",
    password: "testpass123",
    kycStatus: "PENDING",
    tier: 0,
    twoFA: false,
    passkey: false,
    onboardingComplete: false,
    onboarding: null,
  });

  console.log("");

  // ----- Done -----
  console.log("✅ Seed complete.\n");
  console.log("Demo accounts (email / password):");
  console.log(`  admin@mbuni.cex        / ${IS_PROD ? "<SEED_ADMIN_PASSWORD>" : ADMIN_PASSWORD}   (Tier 5, institutional)`);
  console.log("  alex.demo@mbuni.cex    / testpass123    (Tier 3, pro)");
  console.log("  bobby.trader@example.com / testpass123  (Tier 2, intermediate)");
  console.log("  carol.newbie@example.com / testpass123  (Tier 0, onboarding incomplete)");
  console.log("");
}

main()
  .catch((e) => {
    console.error("❌ Seed failed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await db.$disconnect();
  });
MBUNI_EOF_7f3a
w 'proto/compliance.proto' <<'MBUNI_EOF_7f3a'
syntax = "proto3";

package mbuni.v1;

option go_package = "github.com/olekariamunyororo-crypto/mbuni-cex/gen/mbuni/v1;mbunipb";

service ComplianceService {
  rpc SubmitKyc(SubmitKycRequest) returns (KycResponse);
  rpc GetKycStatus(GetKycStatusRequest) returns (KycResponse);
  rpc ScreenTransaction(ScreenTransactionRequest) returns (ScreenTransactionResponse);
}

message SubmitKycRequest {
  string user_id = 1;
  string document_type = 2;    // NATIONAL_ID, PASSPORT, DRIVERS_LICENSE
  string document_number = 3;
  string full_name = 4;
  string date_of_birth = 5;
  string address = 6;
  string city = 7;
  string country = 8;
}

message KycResponse {
  string status = 1;  // NONE, PENDING, VERIFIED, REJECTED
  optional string reject_reason = 2;
  optional int64 submitted_at = 3;
  optional int64 verified_at = 4;
  uint32 attempt_count = 5;
}

message GetKycStatusRequest {
  string user_id = 1;
}

message ScreenTransactionRequest {
  string user_id = 1;
  string asset = 2;
  double amount = 3;
  string tx_hash = 4;
  string counterparty_address = 5;
}

message ScreenTransactionResponse {
  bool passed = 1;
  string risk_level = 2;  // LOW, MEDIUM, HIGH
  optional string reason = 3;
}
MBUNI_EOF_7f3a
w 'proto/market_data.proto' <<'MBUNI_EOF_7f3a'
syntax = "proto3";

package mbuni.v1;

option go_package = "github.com/olekariamunyororo-crypto/mbuni-cex/gen/mbuni/v1;mbunipb";

service MarketDataService {
  rpc GetTicker(GetTickerRequest) returns (TickerResponse);
  rpc GetKlines(GetKlinesRequest) returns (KlinesResponse);
  rpc StreamTrades(StreamRequest) returns (stream Trade);
  rpc StreamOrderBook(StreamRequest) returns (stream OrderBookSnapshot);
}

import "matching_engine.proto";

message GetTickerRequest {
  string pair = 1;
}

message TickerResponse {
  string pair = 1;
  double last_price = 2;
  double price_change = 3;
  double price_change_pct = 4;
  double high_24h = 5;
  double low_24h = 6;
  double volume_24h = 7;
  double quote_volume_24h = 8;
}

message GetKlinesRequest {
  string pair = 1;
  string interval = 2;  // "1m", "5m", "15m", "1h", "4h"
  uint32 limit = 3;
}

message Kline {
  int64 open_time = 1;
  double open = 2;
  double high = 3;
  double low = 4;
  double close = 5;
  double volume = 6;
}

message KlinesResponse {
  repeated Kline klines = 1;
}
MBUNI_EOF_7f3a
w 'proto/matching_engine.proto' <<'MBUNI_EOF_7f3a'
syntax = "proto3";

package mbuni.v1;

option go_package = "github.com/olekariamunyororo-crypto/mbuni-cex/gen/mbuni/v1;mbunipb";

// Matching Engine — gRPC service exposed by the Rust engine
// Consumed by: Trading Service (Go)

service MatchingEngine {
  // Place a new order. Returns the order result + any trades produced.
  rpc PlaceOrder(PlaceOrderRequest) returns (PlaceOrderResponse);
  
  // Cancel an existing order by ID.
  rpc CancelOrder(CancelOrderRequest) returns (CancelOrderResponse);
  
  // Get a snapshot of the current order book for a pair.
  rpc GetSnapshot(SnapshotRequest) returns (OrderBookSnapshot);
  
  // Subscribe to a stream of order book updates for a pair.
  rpc StreamBookUpdates(StreamRequest) returns (stream BookUpdate);
  
  // Subscribe to a stream of trades for a pair.
  rpc StreamTrades(StreamRequest) returns (stream Trade);
  
  // Health check
  rpc Health(HealthRequest) returns (HealthResponse);
}

// --- Enums ---

enum Side {
  SIDE_UNSPECIFIED = 0;
  BUY = 1;
  SELL = 2;
}

enum OrderType {
  ORDER_TYPE_UNSPECIFIED = 0;
  LIMIT = 1;
  MARKET = 2;
  IOC = 3;      // Immediate-or-Cancel
  FOK = 4;      // Fill-or-Kill
  POST_ONLY = 5;
}

enum OrderStatus {
  ORDER_STATUS_UNSPECIFIED = 0;
  NEW = 1;
  PARTIALLY_FILLED = 2;
  FILLED = 3;
  CANCELLED = 4;
  REJECTED = 5;
}

// --- Request / Response messages ---

message PlaceOrderRequest {
  string pair = 1;          // e.g. "BTC/USDT"
  Side side = 2;
  OrderType order_type = 3;
  optional double price = 4; // null for MARKET orders
  double qty = 5;
  string user_id = 6;
  string client_order_id = 7; // idempotency key
}

message PlaceOrderResponse {
  Order order = 1;
  repeated Trade trades = 2;
  bool ok = 3;
  string reject_reason = 4;
}

message CancelOrderRequest {
  string order_id = 1;
  string pair = 2;
}

message CancelOrderResponse {
  bool ok = 1;
}

message SnapshotRequest {
  string pair = 1;
  uint32 depth = 2; // number of levels per side (default 20)
}

message OrderBookSnapshot {
  string pair = 1;
  repeated BookLevel bids = 2;  // sorted descending
  repeated BookLevel asks = 3;  // sorted ascending
  double spread = 4;
  double mid_price = 5;
  double last_price = 6;
  int64 timestamp = 7;
}

message BookLevel {
  double price = 1;
  double qty = 2;
  double total = 3;       // cumulative
  uint32 order_count = 4;
}

message StreamRequest {
  string pair = 1;
}

message BookUpdate {
  string pair = 1;
  repeated BookLevel bids = 2;
  repeated BookLevel asks = 3;
  double last_price = 4;
  int64 timestamp = 5;
}

message Trade {
  string id = 1;
  string pair = 2;
  double price = 3;
  double qty = 4;
  Side side = 5;            // aggressor side
  string buyer_order_id = 6;
  string seller_order_id = 7;
  int64 timestamp = 8;
}

message Order {
  string id = 1;
  string pair = 2;
  Side side = 3;
  OrderType order_type = 4;
  optional double price = 5;
  double qty = 6;
  double filled_qty = 7;
  double remaining_qty = 8;
  OrderStatus status = 9;
  string user_id = 10;
  int64 timestamp = 11;
  optional double avg_fill_price = 12;
}

message HealthRequest {}

message HealthResponse {
  bool ready = 1;
  string version = 2;
  uint64 uptime_seconds = 3;
  uint64 orders_processed = 4;
}
MBUNI_EOF_7f3a
w 'proto/trading.proto' <<'MBUNI_EOF_7f3a'
syntax = "proto3";

package mbuni.v1;

option go_package = "github.com/olekariamunyororo-crypto/mbuni-cex/gen/mbuni/v1;mbunipb";

// Trading Service — gRPC + REST service exposed by Go
// Consumed by: API Gateway / Frontend

service TradingService {
  rpc PlaceOrder(PlaceOrderRequest) returns (PlaceOrderResponse);
  rpc CancelOrder(CancelOrderRequest) returns (CancelOrderResponse);
  rpc GetOpenOrders(GetOrdersRequest) returns (GetOrdersResponse);
  rpc GetOrderHistory(GetOrdersRequest) returns (GetOrdersResponse);
  rpc GetBalances(GetBalancesRequest) returns (GetBalancesResponse);
}

// Re-import shared types
import "matching_engine.proto";

message GetOrdersRequest {
  string user_id = 1;
  optional string pair = 2;
  uint32 limit = 3;
  uint32 offset = 4;
}

message GetOrdersResponse {
  repeated Order orders = 1;
  uint32 total = 2;
}

message GetBalancesRequest {
  string user_id = 1;
}

message Balance {
  string asset = 1;
  double free = 2;
  double locked = 3;
  double usd_value = 4;
}

message GetBalancesResponse {
  repeated Balance balances = 1;
}
MBUNI_EOF_7f3a
w 'proto/wallet.proto' <<'MBUNI_EOF_7f3a'
syntax = "proto3";

package mbuni.v1;

option go_package = "github.com/olekariamunyororo-crypto/mbuni-cex/gen/mbuni/v1;mbunipb";

service WalletService {
  rpc GetDepositAddress(GetDepositAddressRequest) returns (DepositAddressResponse);
  rpc RequestWithdrawal(WithdrawalRequest) returns (WithdrawalResponse);
  rpc GetDeposits(GetTransactionsRequest) returns (DepositsResponse);
  rpc GetWithdrawals(GetTransactionsRequest) returns (WithdrawalsResponse);
  rpc AddWhitelistAddress(WhitelistRequest) returns (WhitelistResponse);
  rpc GetWhitelist(GetWhitelistRequest) returns (WhitelistResponse);
}

message GetDepositAddressRequest {
  string user_id = 1;
  string asset = 2;
  string chain = 3;
}

message DepositAddressResponse {
  string address = 1;
  string chain = 2;
  string memo = 3;
}

message WithdrawalRequest {
  string user_id = 1;
  string asset = 2;
  string chain = 3;
  double amount = 4;
  string address = 5;
}

message WithdrawalResponse {
  string withdrawal_id = 1;
  string status = 2;
  double fee = 3;
}

message GetTransactionsRequest {
  string user_id = 1;
  optional string asset = 2;
  uint32 limit = 3;
  uint32 offset = 4;
}

message Deposit {
  string id = 1;
  string asset = 2;
  string chain = 3;
  double amount = 4;
  string tx_hash = 5;
  string address = 6;
  uint32 confirmations = 7;
  uint32 required_confirmations = 8;
  string status = 9;
  int64 timestamp = 10;
}

message Withdrawal {
  string id = 1;
  string asset = 2;
  string chain = 3;
  double amount = 4;
  double fee = 5;
  string address = 6;
  string tx_hash = 7;
  string status = 8;
  int64 timestamp = 9;
}

message DepositsResponse {
  repeated Deposit deposits = 1;
  uint32 total = 2;
}

message WithdrawalsResponse {
  repeated Withdrawal withdrawals = 1;
  uint32 total = 2;
}

message WhitelistRequest {
  string user_id = 1;
  string asset = 2;
  string chain = 3;
  string address = 4;
  string label = 5;
}

message WhitelistResponse {
  repeated WhitelistedAddress addresses = 1;
  bool ok = 2;
}

message GetWhitelistRequest {
  string user_id = 1;
}

message WhitelistedAddress {
  string id = 1;
  string asset = 2;
  string chain = 3;
  string address = 4;
  string label = 5;
  uint32 time_lock_hours = 6;
  int64 added_at = 7;
}
MBUNI_EOF_7f3a
w 'services/Dockerfile' <<'MBUNI_EOF_7f3a'
# Mbuni CEX 2.0 — Go services Dockerfile (used for all 4 Go services)
# Build context = repo root.  Requires go.sum committed (run `go mod tidy` in each service).
FROM golang:1.23-alpine AS builder
ARG SERVICE_NAME
WORKDIR /app
COPY proto/ /app/proto/
COPY services/${SERVICE_NAME}/ /app/services/${SERVICE_NAME}/
WORKDIR /app/services/${SERVICE_NAME}
RUN go mod download
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /app/server ./cmd/

# --- Runtime: ~2 MB static base, non-root (was golang:1.23-slim, ~700 MB, root) ---
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
MBUNI_EOF_7f3a
w 'services/compliance/cmd/main.go' <<'MBUNI_EOF_7f3a'
// Mbuni CEX 2.0 — Compliance Service (Go)
// Handles: KYC submission + status, AML screening, risk rules, audit logging
package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/caarlos0/env/v11"
)

type Config struct {
	Port        string `env:"PORT" envDefault:"8083"`
	DatabaseURL string `env:"DATABASE_URL" envDefault:"postgres://postgres:password@db:5432/mbuni_cex?sslmode=disable"`
}

func main() {
	cfg := Config{}
	env.Parse(&cfg)

	slog.Info("🦬 Mbuni CEX Compliance Service v2.0.0 starting", "port", cfg.Port)

	mux := http.NewServeMux()
	mux.HandleFunc("POST /api/kyc", submitKyc)
	mux.HandleFunc("GET /api/kyc", getKycStatus)
	mux.HandleFunc("POST /api/aml/screen", screenTransaction)
	mux.HandleFunc("GET /healthz", healthHandler)
	mux.HandleFunc("GET /readyz", healthHandler)

	srv := &http.Server{Addr: ":" + cfg.Port, Handler: mux, ReadHeaderTimeout: 5 * time.Second}

	go func() {
		slog.Info("✓ Compliance Service listening", "port", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("Server failed", "error", err)
			os.Exit(1)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	slog.Info("Shutting down...")
	srv.Shutdown(context.Background())
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"healthy"}`))
}

func submitKyc(w http.ResponseWriter, r *http.Request) {
	var req struct {
		DocumentType   string `json:"documentType"`
		DocumentNumber string `json:"documentNumber"`
		FullName       string `json:"fullName"`
		DOB            string `json:"dob"`
		Address        string `json:"address"`
		City           string `json:"city"`
		Country        string `json:"country"`
	}
	json.NewDecoder(r.Body).Decode(&req)

	// AML screening — check against sanctioned names
	sanctioned := []string{"sanctioned", "terrorist", "criminal", "fraud", "laundering"}
	for _, s := range sanctioned {
		if containsIgnoreCase(req.FullName, s) {
			writeJSON(w, map[string]interface{}{
				"ok":     false,
				"status": "REJECTED",
				"reason": "AML flag: name matches sanctioned entity pattern",
			})
			return
		}
	}

	// TODO: Save to DB, call Sumsub/Onfido for real document verification
	// For demo: auto-approve
	writeJSON(w, map[string]interface{}{
		"ok":      true,
		"status":  "PENDING",
		"message": "KYC submitted. Documents under review.",
	})
}

func getKycStatus(w http.ResponseWriter, r *http.Request) {
	// TODO: Query from DB
	writeJSON(w, map[string]interface{}{
		"status":        "VERIFIED",
		"attemptCount":  1,
		"submittedAt":   time.Now().Add(-24 * time.Hour).UnixMilli(),
		"verifiedAt":    time.Now().Add(-23 * time.Hour).UnixMilli(),
	})
}

func screenTransaction(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Asset              string  `json:"asset"`
		Amount             float64 `json:"amount"`
		TxHash             string  `json:"txHash"`
		CounterpartyAddress string  `json:"counterpartyAddress"`
	}
	json.NewDecoder(r.Body).Decode(&req)

	// TODO: Call Scorechain or Chainalysis KYT for real screening
	// For demo: always pass with low risk
	writeJSON(w, map[string]interface{}{
		"passed":    true,
		"riskLevel": "LOW",
	})
}

func containsIgnoreCase(s, substr string) bool {
	for i := 0; i+len(substr) <= len(s); i++ {
		match := true
		for j := 0; j < len(substr); j++ {
			a, b := s[i+j], substr[j]
			if a >= 'A' && a <= 'Z' { a += 32 }
			if b >= 'A' && b <= 'Z' { b += 32 }
			if a != b { match = false; break }
		}
		if match { return true }
	}
	return false
}

func writeJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}
MBUNI_EOF_7f3a
w 'services/compliance/go.mod' <<'MBUNI_EOF_7f3a'
module github.com/olekariamunyororo-crypto/mbuni-cex/services/compliance

go 1.23

require github.com/caarlos0/env/v11 v11.2.2
MBUNI_EOF_7f3a
w 'services/marketdata/cmd/main.go' <<'MBUNI_EOF_7f3a'
// Mbuni CEX 2.0 — Market Data Service (Go)
// Handles: real-time order book, trade tape, klines, WebSocket distribution
package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/caarlos0/env/v11"
	"github.com/gorilla/websocket"
)

type Config struct {
	Port       string `env:"PORT" envDefault:"8082"`
	EngineAddr string `env:"ENGINE_ADDR" envDefault:"engine:50051"`
	RedisURL   string `env:"REDIS_URL" envDefault:"redis://dragonfly:6379"`
}

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

func main() {
	cfg := Config{}
	env.Parse(&cfg)

	slog.Info("🦬 Mbuni CEX Market Data Service v2.0.0 starting", "port", cfg.Port)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/ticker", getTicker)
	mux.HandleFunc("GET /api/klines", getKlines)
	mux.HandleFunc("GET /api/orderbook", getOrderBook)
	mux.HandleFunc("GET /api/trades", getTrades)
	mux.HandleFunc("/ws", handleWebSocket)
	mux.HandleFunc("GET /healthz", healthHandler)
	mux.HandleFunc("GET /readyz", healthHandler)

	srv := &http.Server{Addr: ":" + cfg.Port, Handler: mux, ReadHeaderTimeout: 5 * time.Second}

	go func() {
		slog.Info("✓ Market Data Service listening", "port", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("Server failed", "error", err)
			os.Exit(1)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	slog.Info("Shutting down...")
	srv.Shutdown(context.Background())
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"healthy"}`))
}

func getTicker(w http.ResponseWriter, r *http.Request) {
	pair := r.URL.Query().Get("pair")
	// TODO: Get from Redis cache (updated by gRPC stream from engine)
	writeJSON(w, map[string]interface{}{
		"pair":          pair,
		"lastPrice":     80835.61,
		"priceChange":   -235.4,
		"priceChangePct": -0.29,
		"high":          82100.0,
		"low":           79800.0,
		"volume":        6160.5,
		"quoteVolume":   498000000,
	})
}

func getKlines(w http.ResponseWriter, r *http.Request) {
	// TODO: Query from TimescaleDB
	writeJSON(w, map[string]interface{}{"klines": []interface{}{}})
}

func getOrderBook(w http.ResponseWriter, r *http.Request) {
	pair := r.URL.Query().Get("pair")
	// TODO: Get from Redis cache (updated by gRPC stream from engine)
	writeJSON(w, map[string]interface{}{
		"pair": pair,
		"bids": [][]float64{{80835.0, 0.45}, {80834.9, 0.32}},
		"asks": [][]float64{{80835.1, 0.38}, {80835.2, 0.55}},
	})
}

func getTrades(w http.ResponseWriter, r *http.Request) {
	// TODO: Get from Redis cache
	writeJSON(w, map[string]interface{}{"trades": []interface{}{}})
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		slog.Error("WebSocket upgrade failed", "error", err)
		return
	}
	defer conn.Close()

	slog.Info("WebSocket client connected", "remote", conn.RemoteAddr())

	// TODO: Subscribe to gRPC stream from engine, forward to WebSocket
	// For now, send a ping every second
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			if err := conn.WriteJSON(map[string]interface{}{
				"type": "ping",
				"time": time.Now().Unix(),
			}); err != nil {
				return
			}
		}
	}
}

func writeJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}
MBUNI_EOF_7f3a
w 'services/marketdata/go.mod' <<'MBUNI_EOF_7f3a'
module github.com/olekariamunyororo-crypto/mbuni-cex/services/marketdata

go 1.23

require (
	github.com/caarlos0/env/v11 v11.2.2
	github.com/gorilla/websocket v1.5.3
)
MBUNI_EOF_7f3a
w 'services/trading/cmd/main.go' <<'MBUNI_EOF_7f3a'
// Mbuni CEX 2.0 — Trading Service entry point
package main

import (
	"context"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/caarlos0/env/v11"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type Config struct {
	Port            string `env:"PORT" envDefault:"8080"`
	EngineAddr      string `env:"ENGINE_ADDR" envDefault:"engine:50051"`
	DatabaseURL     string `env:"DATABASE_URL" envDefault:"postgres://postgres:password@db:5432/mbuni_cex?sslmode=disable"`
	NATSURL         string `env:"NATS_URL" envDefault:"nats://nats:4222"`
	RedisURL        string `env:"REDIS_URL" envDefault:"redis://dragonfly:6379"`
	JWTSecret       string `env:"JWT_SECRET" envDefault:"dev-secret"`
}

func main() {
	cfg := Config{}
	if err := env.Parse(&cfg); err != nil {
		slog.Error("Failed to parse config", "error", err)
		os.Exit(1)
	}

	slog.Info("🦬 Mbuni CEX Trading Service v2.0.0 starting", "port", cfg.Port)

	// Connect to the Rust matching engine via gRPC
	engineConn, err := grpc.NewClient(cfg.EngineAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		slog.Error("Failed to connect to matching engine", "addr", cfg.EngineAddr, "error", err)
		os.Exit(1)
	}
	defer engineConn.Close()
	slog.Info("✓ Connected to matching engine", "addr", cfg.EngineAddr)

	// Initialize the trading service
	svc := NewTradingService(engineConn, cfg.DatabaseURL, cfg.NATSURL)

	// Set up HTTP routes
	mux := http.NewServeMux()
	mux.HandleFunc("POST /api/orders", svc.PlaceOrderHandler)
	mux.HandleFunc("DELETE /api/orders/{id}", svc.CancelOrderHandler)
	mux.HandleFunc("GET /api/orders", svc.GetOrdersHandler)
	mux.HandleFunc("GET /api/balances", svc.GetBalancesHandler)
	mux.HandleFunc("GET /api/trades", svc.GetTradesHandler)
	mux.HandleFunc("GET /healthz", healthHandler)
	mux.HandleFunc("GET /readyz", readyHandler(svc))

	srv := &http.Server{
		ReadHeaderTimeout: 5 * time.Second,
		Addr:    ":" + cfg.Port,
		Handler: mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	// Graceful shutdown
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("Server failed", "error", err)
			os.Exit(1)
		}
	}()

	slog.Info("✓ Trading Service listening", "port", cfg.Port)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	slog.Info("Shutting down...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	srv.Shutdown(ctx)
	slog.Info("✓ Shutdown complete")
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"healthy"}`))
}

func readyHandler(svc *TradingService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if svc.IsReady() {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte(`{"status":"ready"}`))
		} else {
			w.WriteHeader(http.StatusServiceUnavailable)
			w.Write([]byte(`{"status":"not_ready"}`))
		}
	}
}
MBUNI_EOF_7f3a
w 'services/trading/cmd/trading_service.go' <<'MBUNI_EOF_7f3a'
// Mbuni CEX 2.0 — Trading Service core logic
package main

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	"github.com/nats-io/nats.go"
	"google.golang.org/grpc"
)

type TradingService struct {
	engineConn *grpc.ClientConn
	natsConn   *nats.Conn
	ready      bool
}

func NewTradingService(engineConn *grpc.ClientConn, dbURL, natsURL string) *TradingService {
	nc, err := nats.Connect(natsURL)
	if err != nil {
		slog.Warn("Failed to connect to NATS, running without event publishing", "error", err)
	} else {
		slog.Info("✓ Connected to NATS", "url", natsURL)
	}

	svc := &TradingService{
		engineConn: engineConn,
		natsConn:   nc,
		ready:      true,
	}

	return svc
}

func (s *TradingService) IsReady() bool {
	return s.ready
}

// PlaceOrderHandler handles POST /api/orders
func (s *TradingService) PlaceOrderHandler(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Pair      string  `json:"pair"`
		Side      string  `json:"side"`       // "BUY" or "SELL"
		Type      string  `json:"type"`       // LIMIT, MARKET, IOC, FOK, POST_ONLY
		Price     *float64 `json:"price"`
		Qty       float64 `json:"qty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	// Validate
	if req.Pair == "" || req.Side == "" || req.Type == "" {
		writeError(w, http.StatusBadRequest, "pair, side, and type are required")
		return
	}
	if req.Qty <= 0 {
		writeError(w, http.StatusBadRequest, "qty must be positive")
		return
	}

	// TODO: Get user ID from JWT context
	userID := "demo_user"

	// TODO: Pre-trade balance check
	// For now, just forward to the engine

	// In a real implementation, this would:
	// 1. Validate user has sufficient balance (query PostgreSQL or Redis cache)
	// 2. Reserve the balance (atomic operation)
	// 3. Forward the order to the Rust matching engine via gRPC
	// 4. On fill: update balances in PostgreSQL
	// 5. Publish event to NATS (orders.placed, trades.executed)

	// Simulated response for now
	response := map[string]interface{}{
		"ok": true,
		"order": map[string]interface{}{
			"id":         fmt.Sprintf("ord_%d", time.Now().UnixNano()),
			"pair":       req.Pair,
			"side":       req.Side,
			"type":       req.Type,
			"price":      req.Price,
			"qty":        req.Qty,
			"filledQty":  req.Qty, // Auto-fill for demo
			"status":     "FILLED",
			"userId":     userID,
			"timestamp":  time.Now().UnixMilli(),
		},
	}

	// Publish event to NATS
	if s.natsConn != nil {
		event, _ := json.Marshal(map[string]interface{}{
			"subject":   "orders.placed",
			"pair":      req.Pair,
			"side":      req.Side,
			"qty":       req.Qty,
			"userId":    userID,
			"timestamp": time.Now().UnixMilli(),
		})
		s.natsConn.Publish("orders.placed", event)
	}

	writeJSON(w, http.StatusOK, response)
}

// CancelOrderHandler handles DELETE /api/orders/{id}
func (s *TradingService) CancelOrderHandler(w http.ResponseWriter, r *http.Request) {
	orderID := r.PathValue("id")
	if orderID == "" {
		writeError(w, http.StatusBadRequest, "order ID required")
		return
	}

	// TODO: Forward cancel to the matching engine via gRPC
	// TODO: Release reserved balance

	if s.natsConn != nil {
		s.natsConn.Publish("orders.cancelled", []byte(`{"id":"`+orderID+`"}`))
	}

	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

// GetOrdersHandler handles GET /api/orders
func (s *TradingService) GetOrdersHandler(w http.ResponseWriter, r *http.Request) {
	pair := r.URL.Query().Get("pair")
	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil {
			limit = v
		}
	}

	// TODO: Query from PostgreSQL
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"orders": []interface{}{},
		"pair":   pair,
		"limit":  limit,
	})
}

// GetBalancesHandler handles GET /api/balances
func (s *TradingService) GetBalancesHandler(w http.ResponseWriter, r *http.Request) {
	// TODO: Query from PostgreSQL
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"balances": []map[string]interface{}{
			{"asset": "USDT", "free": 245680.42, "locked": 4200.0, "usdValue": 245680.42},
			{"asset": "BTC", "free": 3.4521, "locked": 0.05, "usdValue": 279000.0},
			{"asset": "ETH", "free": 42.18, "locked": 1.2, "usdValue": 136900.0},
		},
	})
}

// GetTradesHandler handles GET /api/trades
func (s *TradingService) GetTradesHandler(w http.ResponseWriter, r *http.Request) {
	pair := r.URL.Query().Get("pair")
	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil {
			limit = v
		}
	}

	// TODO: Query from PostgreSQL
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"trades": []interface{}{},
		"pair":   pair,
		"limit":  limit,
	})
}

// --- Helpers ---

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, msg string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}
MBUNI_EOF_7f3a
w 'services/trading/go.mod' <<'MBUNI_EOF_7f3a'
module github.com/olekariamunyororo-crypto/mbuni-cex/services/trading

go 1.23

require (
	github.com/caarlos0/env/v11 v11.2.2
	github.com/nats-io/nats.go v1.37.0
	google.golang.org/grpc v1.67.0
)
MBUNI_EOF_7f3a
w 'services/wallet/cmd/main.go' <<'MBUNI_EOF_7f3a'
// Mbuni CEX 2.0 — Wallet Service (Go)
// Handles: deposits, withdrawals, custody, multi-chain, address whitelist
package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/caarlos0/env/v11"
)

type Config struct {
	Port        string `env:"PORT" envDefault:"8081"`
	DatabaseURL string `env:"DATABASE_URL" envDefault:"postgres://postgres:password@db:5432/mbuni_cex?sslmode=disable"`
	NATSURL     string `env:"NATS_URL" envDefault:"nats://nats:4222"`
}

func main() {
	cfg := Config{}
	env.Parse(&cfg)

	slog.Info("🦬 Mbuni CEX Wallet Service v2.0.0 starting", "port", cfg.Port)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/wallet/balances", getBalances)
	mux.HandleFunc("GET /api/wallet/deposits", getDeposits)
	mux.HandleFunc("GET /api/wallet/withdrawals", getWithdrawals)
	mux.HandleFunc("POST /api/wallet/withdraw", requestWithdrawal)
	mux.HandleFunc("GET /api/wallet/deposit-address", getDepositAddress)
	mux.HandleFunc("GET /api/wallet/whitelist", getWhitelist)
	mux.HandleFunc("POST /api/wallet/whitelist", addWhitelist)
	mux.HandleFunc("GET /api/wallet/chains", getChains)
	mux.HandleFunc("GET /healthz", healthHandler)
	mux.HandleFunc("GET /readyz", healthHandler)

	srv := &http.Server{Addr: ":" + cfg.Port, Handler: mux, ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 10 * time.Second, WriteTimeout: 10 * time.Second}

	go func() {
		slog.Info("✓ Wallet Service listening", "port", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("Server failed", "error", err)
			os.Exit(1)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	slog.Info("Shutting down...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	srv.Shutdown(ctx)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"healthy"}`))
}

func getBalances(w http.ResponseWriter, r *http.Request) {
	// TODO: Query from PostgreSQL
	writeJSON(w, map[string]interface{}{
		"balances": []map[string]interface{}{
			{"asset": "USDT", "free": 245680.42, "locked": 4200.0, "usdValue": 245680.42},
			{"asset": "BTC", "free": 3.4521, "locked": 0.05, "usdValue": 279000.0},
			{"asset": "ETH", "free": 42.18, "locked": 1.2, "usdValue": 136900.0},
			{"asset": "SOL", "free": 380.5, "locked": 0, "usdValue": 67900.0},
		},
	})
}

func getDeposits(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, map[string]interface{}{"deposits": []interface{}{}})
}

func getWithdrawals(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, map[string]interface{}{"withdrawals": []interface{}{}})
}

func requestWithdrawal(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Asset   string  `json:"asset"`
		Chain   string  `json:"chain"`
		Amount  float64 `json:"amount"`
		Address string  `json:"address"`
	}
	json.NewDecoder(r.Body).Decode(&req)
	// TODO: Validate, check whitelist, check balance, create withdrawal record, publish to NATS
	writeJSON(w, map[string]interface{}{"ok": true, "status": "PENDING"})
}

func getDepositAddress(w http.ResponseWriter, r *http.Request) {
	asset := r.URL.Query().Get("asset")
	chain := r.URL.Query().Get("chain")
	writeJSON(w, map[string]string{
		"address": "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
		"chain":   chain,
		"asset":   asset,
	})
}

func getWhitelist(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, map[string]interface{}{"addresses": []interface{}{}})
}

func addWhitelist(w http.ResponseWriter, r *http.Request) {
	// TODO: Add to DB, set 24h time-lock
	writeJSON(w, map[string]bool{"ok": true})
}

func getChains(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, map[string]interface{}{
		"chains": []map[string]interface{}{
			{"name": "Bitcoin", "confirmations": 3, "withdrawalFeeUSD": 8.5},
			{"name": "Ethereum", "confirmations": 12, "withdrawalFeeUSD": 4.2},
			{"name": "Solana", "confirmations": 32, "withdrawalFeeUSD": 0.05},
			{"name": "Tron", "confirmations": 20, "withdrawalFeeUSD": 1.5},
		},
	})
}

func writeJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}
MBUNI_EOF_7f3a
w 'services/wallet/go.mod' <<'MBUNI_EOF_7f3a'
module github.com/olekariamunyororo-crypto/mbuni-cex/services/wallet

go 1.23

require github.com/caarlos0/env/v11 v11.2.2
MBUNI_EOF_7f3a
w 'src/app/api/kyc/route.ts' <<'MBUNI_EOF_7f3a'
// Mbuni CEX — KYC/AML verification endpoint
// POST /api/kyc  { documentType, documentNumber, fullName, dob, address, city, country }
// GET  /api/kyc  → returns current user's KYC status
import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth/config";
import { db } from "@/lib/db";

// ---------------------------------------------------------------------------
// DEMO MODE
// Real verification must come from a provider (Sumsub / Onfido) via a signed
// webhook. The self-approval below exists only so the UI flow can be demoed.
//   - ON by default in `next dev` / tests
//   - OFF by default in production; requires an explicit KYC_DEMO_AUTO_APPROVE=true
// A production deployment must NEVER enable it: it lets any user self-verify.
// ---------------------------------------------------------------------------
const DEMO_AUTO_APPROVE =
  process.env.KYC_DEMO_AUTO_APPROVE === "true" ||
  (process.env.KYC_DEMO_AUTO_APPROVE !== "false" && process.env.NODE_ENV !== "production");

// Placeholder name screen — NOT a real sanctions check. Replace with a
// Scorechain / Chainalysis KYT / Sumsub AML call before launch.
const FLAGGED_NAME_FRAGMENTS = ["sanctioned", "terrorist", "criminal", "fraud", "laundering"];

function amlScreening(name: string): { passed: boolean; reason?: string } {
  const lower = name.toLowerCase();
  for (const s of FLAGGED_NAME_FRAGMENTS) {
    if (lower.includes(s)) {
      return { passed: false, reason: "AML flag: name matches sanctioned entity pattern" };
    }
  }
  // NOTE: the previous version also rejected ~13% of applicants at random
  // (Math.random() risk score) and burned one of their 3 attempts each time.
  return { passed: true };
}

function maskDocumentNumber(n: string | null): string | null {
  if (!n) return null;
  return "•".repeat(Math.max(0, n.length - 4)) + n.slice(-4);
}

function validAdultDob(dob: string): boolean {
  const d = new Date(dob);
  if (Number.isNaN(d.getTime())) return false;
  const now = new Date();
  const eighteen = new Date(now.getFullYear() - 18, now.getMonth(), now.getDate());
  return d <= eighteen && d.getFullYear() >= 1900;
}

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    return NextResponse.json({ ok: false, error: "Unauthorized" }, { status: 401 });
  }
  const user = await db.user.findUnique({
    where: { id: session.user.id },
    select: {
      kycStatus: true,
      kycDocumentType: true,
      kycDocumentNumber: true,
      kycSubmittedAt: true,
      kycVerifiedAt: true,
      kycRejectReason: true,
      kycAttemptCount: true,
    },
  });
  if (!user) {
    return NextResponse.json({ ok: false, error: "User not found" }, { status: 404 });
  }
  // Never send the full ID number back to the browser.
  return NextResponse.json({
    ok: true,
    kyc: { ...user, kycDocumentNumber: maskDocumentNumber(user.kycDocumentNumber) },
  });
}

export async function POST(req: Request) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    return NextResponse.json({ ok: false, error: "Unauthorized" }, { status: 401 });
  }
  const userId = session.user.id;

  try {
    const body = await req.json().catch(() => ({}));
    const documentType = String(body.documentType ?? "");
    const documentNumber = String(body.documentNumber ?? "").trim();
    const fullName = String(body.fullName ?? "").trim();
    const dob = String(body.dob ?? "");
    const address = String(body.address ?? "").trim();

    if (!["NATIONAL_ID", "PASSPORT", "DRIVERS_LICENSE"].includes(documentType)) {
      return NextResponse.json({ ok: false, error: "Valid document type required" }, { status: 400 });
    }
    if (documentNumber.length < 4 || documentNumber.length > 40) {
      return NextResponse.json({ ok: false, error: "Valid document number required" }, { status: 400 });
    }
    if (fullName.length < 3 || fullName.length > 120) {
      return NextResponse.json({ ok: false, error: "Full name required" }, { status: 400 });
    }
    if (!dob || !validAdultDob(dob)) {
      return NextResponse.json({ ok: false, error: "A valid date of birth (18+) is required" }, { status: 400 });
    }
    if (!address || address.length > 300) {
      return NextResponse.json({ ok: false, error: "Address required" }, { status: 400 });
    }

    const existingUser = await db.user.findUnique({
      where: { id: userId },
      select: { kycAttemptCount: true, kycStatus: true },
    });
    if (!existingUser) {
      return NextResponse.json({ ok: false, error: "User not found" }, { status: 404 });
    }
    if (existingUser.kycStatus === "VERIFIED") {
      // A verified identity must not be overwritable through this endpoint.
      return NextResponse.json({ ok: false, error: "Account is already verified" }, { status: 409 });
    }
    if (existingUser.kycAttemptCount >= 3 && existingUser.kycStatus === "REJECTED") {
      return NextResponse.json({ ok: false, error: "Maximum KYC attempts exceeded. Contact support." }, { status: 429 });
    }

    const amlResult = amlScreening(fullName);
    if (!amlResult.passed) {
      await db.user.update({
        where: { id: userId },
        data: {
          kycStatus: "REJECTED",
          kycRejectReason: amlResult.reason,
          kycAttemptCount: { increment: 1 },
          kycDocumentType: documentType,
          kycDocumentNumber: documentNumber,
          kycSubmittedAt: new Date(),
        },
      });
      return NextResponse.json({ ok: false, status: "REJECTED", reason: amlResult.reason });
    }

    await db.user.update({
      where: { id: userId },
      data: {
        kycStatus: "PENDING",
        kycDocumentType: documentType,
        kycDocumentNumber: documentNumber,
        kycSubmittedAt: new Date(),
        kycRejectReason: null,
        kycAttemptCount: { increment: 1 },
      },
    });

    if (DEMO_AUTO_APPROVE) {
      if (process.env.NODE_ENV === "production") {
        console.warn("[kyc] KYC_DEMO_AUTO_APPROVE is enabled in production — every user can self-verify!");
      }
      setTimeout(async () => {
        try {
          // Only approve if it is still PENDING (e.g. an admin may have rejected it meanwhile).
          const res = await db.user.updateMany({
            where: { id: userId, kycStatus: "PENDING" },
            data: { kycStatus: "VERIFIED", kycVerifiedAt: new Date() },
          });
          if (res.count > 0) {
            await db.user.updateMany({ where: { id: userId, tier: { lt: 1 } }, data: { tier: 1 } });
          }
        } catch (e) {
          console.error("[kyc] demo auto-approve failed:", e);
        }
      }, 4000);
    }

    return NextResponse.json({
      ok: true,
      status: "PENDING",
      message: "KYC submitted. Documents under review.",
    });
  } catch (e) {
    console.error("[kyc] submit failed:", e);
    return NextResponse.json({ ok: false, error: "Could not process KYC submission" }, { status: 500 });
  }
}
MBUNI_EOF_7f3a
w 'src/app/api/signup/route.ts' <<'MBUNI_EOF_7f3a'
// Mbuni CEX — Signup endpoint
// POST /api/signup  { email, password, name? }
// Creates a User with bcrypt-hashed password and returns success.
import { NextResponse } from "next/server";
import bcrypt from "bcryptjs";
import { db } from "@/lib/db";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return NextResponse.json({ ok: false, error: "Invalid request body" }, { status: 400 });
    }
    const email = String(body.email ?? "").toLowerCase().trim();
    const password = String(body.password ?? "");
    const name = body.name ? String(body.name).trim().slice(0, 80) || null : null;

    if (!email || email.length > 254 || !EMAIL_RE.test(email)) {
      return NextResponse.json({ ok: false, error: "Valid email required" }, { status: 400 });
    }
    if (password.length < 8) {
      return NextResponse.json({ ok: false, error: "Password must be ≥ 8 characters" }, { status: 400 });
    }
    // bcrypt only hashes the first 72 bytes; a cap also bounds CPU per request.
    if (Buffer.byteLength(password, "utf8") > 72) {
      return NextResponse.json({ ok: false, error: "Password must be at most 72 bytes" }, { status: 400 });
    }

    const existing = await db.user.findUnique({ where: { email }, select: { id: true } });
    if (existing) {
      return NextResponse.json({ ok: false, error: "Email already registered" }, { status: 409 });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    try {
      const user = await db.user.create({
        data: { email, name, passwordHash, kycStatus: "NONE", tier: 0 },
      });
      return NextResponse.json({ ok: true, userId: user.id, email: user.email });
    } catch (e) {
      // Two concurrent signups can both pass the findUnique above.
      if ((e as { code?: string }).code === "P2002") {
        return NextResponse.json({ ok: false, error: "Email already registered" }, { status: 409 });
      }
      throw e;
    }
  } catch (e) {
    // Never leak internal/DB error text to the client.
    console.error("[signup] failed:", e);
    return NextResponse.json({ ok: false, error: "Could not create account" }, { status: 500 });
  }
}
MBUNI_EOF_7f3a
w 'src/hooks/use-mobile.ts' <<'MBUNI_EOF_7f3a'
import * as React from "react"

const MOBILE_BREAKPOINT = 768
const QUERY = `(max-width: ${MOBILE_BREAKPOINT - 1}px)`

function subscribe(onChange: () => void) {
  const mql = window.matchMedia(QUERY)
  mql.addEventListener("change", onChange)
  return () => mql.removeEventListener("change", onChange)
}

export function useIsMobile() {
  // useSyncExternalStore avoids the setState-in-effect cascade and is
  // hydration-safe: the server snapshot is always `false`.
  return React.useSyncExternalStore(
    subscribe,
    () => window.matchMedia(QUERY).matches,
    () => false
  )
}
MBUNI_EOF_7f3a
w 'src/lib/auth/config.ts' <<'MBUNI_EOF_7f3a'
// Mbuni CEX — NextAuth configuration
// JWT strategy with Credentials provider backed by Prisma (SQLite)

import type { NextAuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import bcrypt from "bcryptjs";
import { db } from "@/lib/db";

const DEV_SECRET = "mbuni-cex-dev-secret-change-me";

// Fail closed: never sign JWTs with a publicly known fallback secret in production.
// (NEXT_PHASE is set by `next build`, which has no runtime secrets by design.)
function resolveSecret(): string {
  const s = process.env.NEXTAUTH_SECRET;
  if (s && s.length >= 32) return s;
  const isBuild = process.env.NEXT_PHASE === "phase-production-build";
  if (process.env.NODE_ENV === "production" && !isBuild) {
    throw new Error("NEXTAUTH_SECRET must be set to a random string of at least 32 characters in production");
  }
  return s ?? DEV_SECRET;
}

export const authOptions: NextAuthOptions = {
  session: {
    strategy: "jwt",
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },
  providers: [
    CredentialsProvider({
      name: "Credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) return null;
        const email = credentials.email.toLowerCase().trim();
        const user = await db.user.findUnique({ where: { email } });
        if (!user || !user.passwordHash) return null;
        const valid = await bcrypt.compare(credentials.password, user.passwordHash);
        if (!valid) return null;
        return {
          id: user.id,
          email: user.email,
          name: user.name ?? undefined,
        };
      },
    }),
  ],
  pages: {
    // We use a custom in-app auth screen — no NextAuth-hosted pages.
    signIn: "/",
    error: "/",
  },
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id;
      }
      // Refresh onboarding flag from DB on every JWT mint
      if (token.id) {
        const dbUser = await db.user.findUnique({
          where: { id: token.id as string },
          select: { onboardingComplete: true, tier: true, kycStatus: true, name: true },
        });
        if (dbUser) {
          token.onboardingComplete = dbUser.onboardingComplete;
          token.tier = dbUser.tier;
          token.kycStatus = dbUser.kycStatus;
          if (!token.name && dbUser.name) token.name = dbUser.name;
        }
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        (session.user as { id?: string }).id = token.id as string;
        (session.user as { onboardingComplete?: boolean }).onboardingComplete =
          token.onboardingComplete as boolean;
        (session.user as { tier?: number }).tier = token.tier as number;
        (session.user as { kycStatus?: string }).kycStatus = token.kycStatus as string;
      }
      return session;
    },
  },
  secret: resolveSecret(),
};

// Extend Session types
declare module "next-auth" {
  interface Session {
    user: {
      id?: string;
      email: string;
      name?: string | null;
      onboardingComplete?: boolean;
      tier?: number;
      kycStatus?: string;
    };
  }
  interface User {
    id: string;
    email: string;
    name?: string | null;
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    id?: string;
    onboardingComplete?: boolean;
    tier?: number;
    kycStatus?: string;
  }
}
MBUNI_EOF_7f3a
w 'src/lib/db.ts' <<'MBUNI_EOF_7f3a'
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

// Query logging prints every statement (including bound params such as emails)
// and slows hot paths. It is opt-in: PRISMA_LOG_QUERIES=1
const log: ('query' | 'warn' | 'error')[] =
  process.env.PRISMA_LOG_QUERIES === '1'
    ? ['query', 'warn', 'error']
    : process.env.NODE_ENV === 'production'
      ? ['error']
      : ['warn', 'error']

export const db = globalForPrisma.prisma ?? new PrismaClient({ log })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db
MBUNI_EOF_7f3a
w 'src/lib/opencex/engine.ts' <<'MBUNI_EOF_7f3a'
// Mbuni CEX — In-memory matching engine (TypeScript reference impl of the Rust engine)
//
// Implements the responsibilities described in §5 of the spec:
//  - High-performance in-memory order books (per pair)
//  - Price-Time priority matching
//  - Pre-trade risk checks
//  - Publishes trades and order book deltas
//
// Supported order types: LIMIT, MARKET, IOC, FOK, POST_ONLY

import type {
  Order,
  OrderBookLevel,
  OrderBookSnapshot,
  OrderType,
  Side,
  Trade,
  TradingPair,
} from "./types";

interface RestingOrder {
  id: string;
  pair: string;
  side: Side;
  type: OrderType;
  price: number;
  qty: number; // remaining
  userId: string;
  timestamp: number;
}

const uid = (() => {
  let n = 0;
  return (prefix = "id") => `${prefix}_${(n++).toString(36)}_${Math.random().toString(36).slice(2, 8)}`;
})();

function round(num: number, decimals: number): number {
  const f = Math.pow(10, decimals);
  return Math.round(num * f) / f;
}

export interface MatchResult {
  order: Order;
  trades: Trade[];
  // events for the NATS bus
  events: Array<{ subject: "orders.placed" | "orders.cancelled" | "orders.filled" | "trades.executed" | "balances.updated"; payload: unknown }>;
}

export class MatchingEngine {
  // Per pair: bids (price → FIFO queue), asks (price → FIFO queue)
  private bids = new Map<number, RestingOrder[]>(); // best = highest
  private asks = new Map<number, RestingOrder[]>(); // best = lowest
  private lastPrice: number;
  private nextSeq = 1;
  public readonly pair: TradingPair;

  // Bookkeeping callbacks
  onTrade?: (t: Trade) => void;
  onOrderUpdate?: (o: Order) => void;
  onBookUpdate?: (snapshot: OrderBookSnapshot) => void;

  constructor(pair: TradingPair, initialPrice: number) {
    this.pair = pair;
    this.lastPrice = initialPrice;
  }

  private priceKey(price: number): number {
    return round(price, this.pair.priceDecimals);
  }

  private bookFor(side: Side): Map<number, RestingOrder[]> {
    return side === "BUY" ? this.bids : this.asks;
  }

  private bestPrice(side: Side): number | null {
    const book = this.bookFor(side);
    // Single pass, no array allocation. (Math.max(...keys) throws RangeError on very large books.)
    let best: number | null = null;
    for (const p of book.keys()) {
      if (best === null || (side === "BUY" ? p > best : p < best)) best = p;
    }
    return best;
  }

  /**
   * Compute the total qty available on the opposite book that an aggressor
   * order of `aggressorSide` could match, optionally constrained by a max
   * price (for FOK LIMIT). Used for the FOK pre-flight check.
   *
   * A BUY aggressor walks the ASK book (ascending prices, stops at price).
   * A SELL aggressor walks the BID book (descending prices, stops at price).
   */
  private availableLiquidity(aggressorSide: Side, maxPrice: number | null): number {
    const restingSide: Side = aggressorSide === "BUY" ? "SELL" : "BUY";
    const book = this.bookFor(restingSide);
    let total = 0;
    for (const [price, queue] of book) {
      if (maxPrice !== null && !this.crossable(restingSide, price, maxPrice)) continue;
      for (const resting of queue) {
        total += resting.qty;
      }
    }
    return round(total, this.pair.baseDecimals);
  }

  private crossable(restingSide: Side, restingPrice: number, aggressorPrice: number | null): boolean {
    if (aggressorPrice === null) return true; // market
    if (restingSide === "SELL") return aggressorPrice >= restingPrice; // aggressor BUY
    return aggressorPrice <= restingPrice; // aggressor SELL, resting BUY
  }

  placeOrder(params: {
    pair: string;
    side: Side;
    type: OrderType;
    price: number | null;
    qty: number;
    userId: string;
  }): MatchResult {
    const { side, type, price, qty, userId, pair } = params;
    const trades: Trade[] = [];
    const events: MatchResult["events"] = [];

    // Pre-trade risk checks
    if (qty <= 0) {
      const o = this.makeOrder({ pair, side, type, price, qty, userId, status: "REJECTED", filledQty: 0 });
      return { order: o, trades, events };
    }
    if (type !== "MARKET" && (price === null || price <= 0)) {
      const o = this.makeOrder({ pair, side, type, price, qty, userId, status: "REJECTED", filledQty: 0 });
      return { order: o, trades, events };
    }
    if (type === "POST_ONLY" && price !== null) {
      // Post-Only would cross → reject
      const oppositeBest = this.bestPrice(side === "BUY" ? "SELL" : "BUY");
      if (oppositeBest !== null && this.crossable(side === "BUY" ? "SELL" : "BUY", oppositeBest, price)) {
        const o = this.makeOrder({ pair, side, type, price, qty, userId, status: "REJECTED", filledQty: 0 });
        return { order: o, trades, events };
      }
    }

    // FOK (Fill-or-Kill): pre-flight liquidity check.
    // The order must fill ENTIRELY or not at all — so verify the book has
    // enough qty at acceptable prices BEFORE touching anything. If it can't
    // fill, reject immediately and leave the book untouched.
    if (type === "FOK") {
      const available = this.availableLiquidity(side, price);
      if (available < qty) {
        const o = this.makeOrder({ pair, side, type, price, qty, userId, status: "CANCELLED", filledQty: 0 });
        o.remainingQty = 0; // nothing rests on the book — remainder is killed
        events.push({ subject: "orders.cancelled", payload: { id: o.id, reason: "FOK_NOT_FILLABLE" } });
        return { order: o, trades, events };
      }
    }

    const order = this.makeOrder({ pair, side, type, price, qty, userId, status: "NEW", filledQty: 0 });
    events.push({ subject: "orders.placed", payload: order });

    let remaining = qty;
    let filledQty = 0;
    let totalCost = 0;
    const aggressorSide = side;
    const oppositeSide: Side = side === "BUY" ? "SELL" : "BUY";

    // Match against the opposite book (price-time priority)
    if (type !== "POST_ONLY") {
      while (remaining > 0) {
        const best = this.bestPrice(oppositeSide);
        if (best === null) break;
        if (!this.crossable(oppositeSide, best, price)) break;

        const queue = this.bookFor(oppositeSide).get(best)!;
        while (queue.length > 0 && remaining > 0) {
          const resting = queue[0];
          const fillQty = Math.min(remaining, resting.qty);
          const fillPrice = resting.price;
          const trade: Trade = {
            id: uid("t"),
            pair,
            price: fillPrice,
            qty: round(fillQty, this.pair.baseDecimals),
            side: aggressorSide,
            buyerOrderId: aggressorSide === "BUY" ? order.id : resting.id,
            sellerOrderId: aggressorSide === "SELL" ? order.id : resting.id,
            timestamp: Date.now(),
          };
          trades.push(trade);
          this.lastPrice = fillPrice;

          remaining = round(remaining - fillQty, this.pair.baseDecimals);
          filledQty = round(filledQty + fillQty, this.pair.baseDecimals);
          totalCost += fillQty * fillPrice;

          resting.qty = round(resting.qty - fillQty, this.pair.baseDecimals);
          if (resting.qty <= 0) {
            queue.shift();
            events.push({
              subject: "orders.filled",
              payload: { id: resting.id, status: "FILLED", pair },
            });
          } else {
            events.push({
              subject: "orders.filled",
              payload: { id: resting.id, status: "PARTIALLY_FILLED", pair, remaining: resting.qty },
            });
          }
          events.push({ subject: "trades.executed", payload: trade });
          events.push({
            subject: "balances.updated",
            payload: { pair, tradeId: trade.id, price: fillPrice, qty: fillQty },
          });
        }
        if (queue.length === 0) {
          this.bookFor(oppositeSide).delete(best);
        }
      }
    }

    // IOC: cancel remainder (FOK is handled by the pre-flight check above —
    // if we reach here, FOK is guaranteed to fully fill)
    if (type === "IOC" && remaining > 0) {
      order.status = filledQty > 0 ? "PARTIALLY_FILLED" : "CANCELLED";
      order.remainingQty = 0;
    } else if (remaining > 0 && (type === "LIMIT" || type === "POST_ONLY")) {
      // Rest on book
      const resting: RestingOrder = {
        id: order.id,
        pair,
        side,
        type,
        price: price!,
        qty: remaining,
        userId,
        timestamp: Date.now(),
      };
      const key = this.priceKey(price!);
      const book = this.bookFor(side);
      if (!book.has(key)) book.set(key, []);
      book.get(key)!.push(resting);
      order.status = filledQty > 0 ? "PARTIALLY_FILLED" : "NEW";
      order.remainingQty = remaining;
    } else if (remaining === 0) {
      order.status = "FILLED";
      order.remainingQty = 0;
    } else {
      // MARKET with leftover (no liquidity) → cancel remainder
      order.status = filledQty > 0 ? "PARTIALLY_FILLED" : "CANCELLED";
      order.remainingQty = 0;
    }

    order.filledQty = filledQty;
    order.avgFillPrice = filledQty > 0 ? round(totalCost / filledQty, this.pair.priceDecimals) : null;

    events.push({ subject: "orders.filled", payload: order });

    // Notify
    this.onOrderUpdate?.(order);
    trades.forEach((t) => this.onTrade?.(t));
    this.emitBookSnapshot();

    return { order, trades, events };
  }

  cancel(orderId: string): boolean {
    for (const book of [this.bids, this.asks]) {
      for (const [price, queue] of book) {
        const idx = queue.findIndex((o) => o.id === orderId);
        if (idx >= 0) {
          queue.splice(idx, 1);
          if (queue.length === 0) book.delete(price);
          this.onOrderUpdate?.({
            id: orderId,
            pair: this.pair.symbol,
            side: "BUY", // placeholder, real impl tracks
            type: "LIMIT",
            price,
            qty: 0,
            filledQty: 0,
            remainingQty: 0,
            status: "CANCELLED",
            userId: "",
            timestamp: Date.now(),
            avgFillPrice: null,
          });
          this.emitBookSnapshot();
          return true;
        }
      }
    }
    return false;
  }

  getSnapshot(): OrderBookSnapshot {
    const bids: OrderBookLevel[] = [];
    const asks: OrderBookLevel[] = [];
    let bidTotal = 0;
    let askTotal = 0;

    const bidPrices = Array.from(this.bids.keys()).sort((a, b) => b - a).slice(0, 20);
    for (const p of bidPrices) {
      const queue = this.bids.get(p)!;
      const qty = queue.reduce((s, o) => s + o.qty, 0);
      bidTotal += qty;
      bids.push({ price: p, qty: round(qty, this.pair.baseDecimals), total: round(bidTotal, this.pair.baseDecimals), orderCount: queue.length });
    }
    const askPrices = Array.from(this.asks.keys()).sort((a, b) => a - b).slice(0, 20);
    for (const p of askPrices) {
      const queue = this.asks.get(p)!;
      const qty = queue.reduce((s, o) => s + o.qty, 0);
      askTotal += qty;
      asks.push({ price: p, qty: round(qty, this.pair.baseDecimals), total: round(askTotal, this.pair.baseDecimals), orderCount: queue.length });
    }

    const bestBid = bidPrices.length ? bidPrices[0] : 0;
    const bestAsk = askPrices.length ? askPrices[0] : 0;
    const spread = bestBid && bestAsk ? round(bestAsk - bestBid, this.pair.priceDecimals) : 0;
    const midPrice = bestBid && bestAsk ? round((bestBid + bestAsk) / 2, this.pair.priceDecimals) : this.lastPrice;

    return {
      pair: this.pair.symbol,
      bids,
      asks,
      spread,
      midPrice,
      lastPrice: this.lastPrice,
      timestamp: Date.now(),
    };
  }

  private emitBookSnapshot() {
    this.onBookUpdate?.(this.getSnapshot());
  }

  private makeOrder(p: {
    pair: string;
    side: Side;
    type: OrderType;
    price: number | null;
    qty: number;
    userId: string;
    status: Order["status"];
    filledQty: number;
  }): Order {
    return {
      id: uid("o"),
      pair: p.pair,
      side: p.side,
      type: p.type,
      price: p.price,
      qty: p.qty,
      filledQty: p.filledQty,
      remainingQty: p.qty - p.filledQty,
      status: p.status,
      userId: p.userId,
      timestamp: Date.now(),
      avgFillPrice: null,
    };
  }

  // Seed the book with random market-makers (used to bootstrap a lively order book)
  seedBook(midPrice: number, levels = 12, qtyEach = 0.5) {
    for (let i = 1; i <= levels; i++) {
      const bidPrice = round(midPrice - i * this.pair.tickSize, this.pair.priceDecimals);
      const askPrice = round(midPrice + i * this.pair.tickSize, this.pair.priceDecimals);
      const bidQty = round(qtyEach * (1 + Math.random()), this.pair.baseDecimals);
      const askQty = round(qtyEach * (1 + Math.random()), this.pair.baseDecimals);
      const bidKey = this.priceKey(bidPrice);
      const askKey = this.priceKey(askPrice);
      if (!this.bids.has(bidKey)) this.bids.set(bidKey, []);
      if (!this.asks.has(askKey)) this.asks.set(askKey, []);
      this.bids.get(bidKey)!.push({
        id: uid("mm"),
        pair: this.pair.symbol,
        side: "BUY",
        type: "LIMIT",
        price: bidPrice,
        qty: bidQty,
        userId: "market-maker",
        timestamp: Date.now() - (levels - i) * 1000,
      });
      this.asks.get(askKey)!.push({
        id: uid("mm"),
        pair: this.pair.symbol,
        side: "SELL",
        type: "LIMIT",
        price: askPrice,
        qty: askQty,
        userId: "market-maker",
        timestamp: Date.now() - (levels - i) * 1000,
      });
    }
    this.lastPrice = midPrice;
    this.emitBookSnapshot();
  }

  // Simulated bot activity (random MM rebalancing + taker orders) — drives the live feel
  tick() {
    const snap = this.getSnapshot();
    if (snap.bids.length === 0 || snap.asks.length === 0) return;

    // 70% chance: MM cancels + re-quotes a level
    // 30% chance: a taker crosses the spread → real trade
    const roll = Math.random();
    if (roll < 0.7) {
      const side: Side = Math.random() < 0.5 ? "BUY" : "SELL";
      const book = side === "BUY" ? this.bids : this.asks;
      const prices = Array.from(book.keys());
      if (prices.length > 4) {
        // cancel a random deep level
        const idx = 2 + Math.floor(Math.random() * (prices.length - 3));
        const p = prices[idx];
        const queue = book.get(p);
        if (queue && queue.length > 0) {
          queue.pop();
          if (queue.length === 0) book.delete(p);
        }
        // re-quote at a slightly different price near the mid
        const mid = snap.midPrice;
        const offset = (Math.floor(Math.random() * 6) + 2) * this.pair.tickSize;
        const newPrice = round(side === "BUY" ? mid - offset : mid + offset, this.pair.priceDecimals);
        const key = this.priceKey(newPrice);
        if (!book.has(key)) book.set(key, []);
        book.get(key)!.push({
          id: uid("mm"),
          pair: this.pair.symbol,
          side,
          type: "LIMIT",
          price: newPrice,
          qty: round(0.2 + Math.random() * 1.5, this.pair.baseDecimals),
          userId: "market-maker",
          timestamp: Date.now(),
        });
      }
    } else {
      // Taker crosses spread
      const side: Side = Math.random() < 0.5 ? "BUY" : "SELL";
      const qty = round(0.05 + Math.random() * 0.6, this.pair.baseDecimals);
      this.placeOrder({
        pair: this.pair.symbol,
        side,
        type: "MARKET",
        price: null,
        qty,
        userId: "bot-taker",
      });
    }
    this.emitBookSnapshot();
  }
}
MBUNI_EOF_7f3a
w 'src/lib/opencex/store.test.ts' <<'MBUNI_EOF_7f3a'
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { estimateBuyCost, useOpenCEX } from "./store";

const PAIR = "BTC/USDT";
const bal = (asset: string) => useOpenCEX.getState().balances.find((b) => b.asset === asset)!;

function fresh() {
  const s = useOpenCEX.getState();
  if (s.engineInterval) clearInterval(s.engineInterval);
  useOpenCEX.setState({ started: false, engineInterval: null, orders: [], trades: [] });
  useOpenCEX.getState().init();
  // stop the bot ticker so tests are deterministic
  const i = useOpenCEX.getState().engineInterval;
  if (i) clearInterval(i);
  useOpenCEX.setState({ engineInterval: null });
}

describe("store settlement", () => {
  beforeEach(fresh);
  afterAll(() => {
    const i = useOpenCEX.getState().engineInterval;
    if (i) clearInterval(i);
  });

  it("MARKET buy debits quote and credits base", () => {
    const usdt0 = bal("USDT").free, btc0 = bal("BTC").free;
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "MARKET", price: null, qty: 0.01 });
    expect(r.ok).toBe(true);
    expect(r.order!.status).toBe("FILLED");
    expect(bal("USDT").free).toBeLessThan(usdt0 - 100); // ~0.01 BTC ≈ $800 paid
    expect(bal("BTC").free).toBeCloseTo(btc0 + 0.01, 8);
    expect(bal("USDT").locked).toBe(4200); // untouched
  });

  it("LIMIT buy that crosses pays the FILL price, not the limit price", () => {
    const ask = useOpenCEX.getState().books[PAIR].asks[0].price;
    const usdt0 = bal("USDT").free;
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "LIMIT", price: ask + 500, qty: 0.01 });
    expect(r.order!.status).toBe("FILLED");
    expect(usdt0 - bal("USDT").free).toBeCloseTo(0.01 * ask, 4);
  });

  it("FOK that cannot fill (CANCELLED) locks nothing", () => {
    const top = useOpenCEX.getState().books[PAIR].asks[0];
    const before = { f: bal("USDT").free, l: bal("USDT").locked };
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "FOK", price: top.price, qty: top.qty + 1 });
    expect(r.order!.status).toBe("CANCELLED");
    expect(bal("USDT").free).toBe(before.f);
    expect(bal("USDT").locked).toBe(before.l);
  });

  it("IOC partial fill does not lock the cancelled remainder", () => {
    const top = useOpenCEX.getState().books[PAIR].asks[0];
    const l0 = bal("USDT").locked;
    const f0 = bal("USDT").free;
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "IOC", price: top.price, qty: top.qty + 1 });
    expect(r.order!.status).toBe("PARTIALLY_FILLED");
    expect(bal("USDT").locked).toBe(l0);
    expect(f0 - bal("USDT").free).toBeCloseTo(top.qty * top.price, 4);
  });

  it("resting LIMIT locks funds and cancel releases them", () => {
    const l0 = bal("USDT").locked, f0 = bal("USDT").free;
    const px = useOpenCEX.getState().books[PAIR].bids[0].price - 100; // well below the book → rests
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "LIMIT", price: px, qty: 0.1 });
    expect(r.order!.status).toBe("NEW");
    expect(bal("USDT").locked).toBeCloseTo(l0 + px * 0.1, 4);
    useOpenCEX.getState().cancelOrder(r.order!.id);
    expect(bal("USDT").locked).toBeCloseTo(l0, 4);
    expect(bal("USDT").free).toBeCloseTo(f0, 4);
  });

  it("when another trader fills the user's resting order, balances and order status settle", () => {
    const px = useOpenCEX.getState().books[PAIR].bids[0].price - 100;
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "LIMIT", price: px, qty: 0.1 });
    const l1 = bal("USDT").locked, btc1 = bal("BTC").free;
    const eng = useOpenCEX.getState().engines[PAIR];
    eng.placeOrder({ pair: PAIR, side: "SELL", type: "MARKET", price: null, qty: 100, userId: "someone-else" }); // sweeps the whole bid side
    const o = useOpenCEX.getState().orders.find((x) => x.id === r.order!.id)!;
    expect(o.status).toBe("FILLED");
    expect(o.remainingQty).toBe(0);
    expect(bal("USDT").locked).toBeCloseTo(l1 - px * 0.1, 4);
    expect(bal("BTC").free).toBeCloseTo(btc1 + 0.1, 8);
  });

  it("estimateBuyCost walks levels and extrapolates", () => {
    expect(estimateBuyCost([{ price: 10, qty: 1 }, { price: 11, qty: 1 }], 1.5)).toBeCloseTo(10 + 5.5);
    expect(estimateBuyCost([{ price: 10, qty: 1 }], 3)).toBeCloseTo(30);
  });
});
MBUNI_EOF_7f3a
w 'src/lib/opencex/store.ts' <<'MBUNI_EOF_7f3a'
// Mbuni CEX — Central client store
//
// Ties together:
//  - Per-pair matching engines (Rust engine — TS reference impl)
//  - User balances (with reservation / release on order placement)
//  - Live trade tape
//  - Kline history + 24h ticker
//  - NATS-style event log (spec §8)
//
// All updates flow through here so every view stays consistent.

"use client";

import { create } from "zustand";
import { MatchingEngine } from "./engine";
import {
  CHAINS,
  DEPOSITS,
  FEE_SCHEDULES,
  INITIAL_BALANCES,
  INITIAL_PRICES,
  SAMPLE_USERS,
  TRADING_PAIRS,
  WHITELISTED_ADDRESSES,
  WITHDRAWALS,
  generateKlines,
} from "./seed";
import type {
  Balance,
  Deposit,
  FeeSchedule,
  Kline,
  Order,
  OrderBookSnapshot,
  Side,
  SystemEvent,
  Trade,
  Ticker24h,
  User,
  WhitelistedAddress,
  Withdrawal,
} from "./types";

const CURRENT_USER_ID = "u_self";

interface MbuniCEXState {
  // Static / reference data
  pairs: typeof TRADING_PAIRS;
  feeSchedules: FeeSchedule[];
  chains: typeof CHAINS;
  users: User[];

  // Live data
  activePair: string;
  balances: Balance[];
  orders: Order[]; // current user's orders
  trades: Trade[]; // global trade tape (most recent)
  tickers: Record<string, Ticker24h>;
  books: Record<string, OrderBookSnapshot>;
  klines: Record<string, Kline[]>;
  deposits: Deposit[];
  withdrawals: Withdrawal[];
  whitelist: WhitelistedAddress[];
  events: SystemEvent[];

  // Internal engines (not serializable, kept outside react tree)
  engines: Record<string, MatchingEngine>;
  engineInterval: ReturnType<typeof setInterval> | null;
  started: boolean;

  // Live data (Binance WebSocket feed)
  liveMode: boolean;       // true = real Binance data, false = simulated bots
  feedConnected: boolean;  // WebSocket connection status
  feed: unknown;           // BinanceFeed instance (not serializable)

  // Actions
  init: () => void;
  setActivePair: (symbol: string) => void;
  setLiveMode: (enabled: boolean) => void;
  setFeedConnected: (connected: boolean) => void;
  setFeed: (feed: unknown) => void;
  updateBookFromBinance: (pair: string, bids: Array<[number, number]>, asks: Array<[number, number]>) => void;
  updateTradeFromBinance: (pair: string, price: number, qty: number, side: "BUY" | "SELL", timestamp: number) => void;
  updateTickerFromBinance: (pair: string, lastPrice: number, priceChangePct: number, high: number, low: number, volume: number, quoteVolume: number) => void;
  updateKlineFromBinance: (pair: string, openTime: number, open: number, high: number, low: number, close: number, volume: number, isClosed: boolean) => void;
  placeOrder: (params: { pair: string; side: Side; type: Order["type"]; price: number | null; qty: number }) => { ok: boolean; reason?: string; order?: Order };
  cancelOrder: (orderId: string) => void;
  requestWithdrawal: (params: { asset: string; chain: string; amount: number; address: string }) => { ok: boolean; reason?: string };
  addWhitelist: (params: { asset: string; chain: string; address: string; label: string }) => void;
  pushEvent: (subject: SystemEvent["subject"], payload: unknown) => void;
}

function uid(prefix = "id") {
  return `${prefix}_${Math.random().toString(36).slice(2, 10)}`;
}

function findPair(pairs: typeof TRADING_PAIRS, symbol: string) {
  return pairs.find((p) => p.symbol === symbol)!;
}

function buildTicker(pair: string, lastPrice: number, klines: Kline[]): Ticker24h {
  const last24 = klines.slice(-1440); // 24h of 1m klines
  const high = last24.length ? Math.max(...last24.map((k) => k.high)) : lastPrice;
  const low = last24.length ? Math.min(...last24.map((k) => k.low)) : lastPrice;
  const open = last24.length ? last24[0].open : lastPrice;
  const volume = last24.reduce((s, k) => s + k.volume, 0);
  const quoteVolume = last24.reduce((s, k) => s + k.volume * k.close, 0);
  const priceChange = lastPrice - open;
  return {
    pair,
    lastPrice,
    priceChange,
    priceChangePct: open ? (priceChange / open) * 100 : 0,
    high,
    low,
    volume,
    quoteVolume,
  };
}

export const useOpenCEX = create<MbuniCEXState>((set, get) => ({
  pairs: TRADING_PAIRS,
  feeSchedules: FEE_SCHEDULES,
  chains: CHAINS,
  users: SAMPLE_USERS,

  activePair: "BTC/USDT",
  balances: INITIAL_BALANCES,
  orders: [],
  trades: [],
  tickers: {},
  books: {},
  klines: {},
  deposits: DEPOSITS,
  withdrawals: WITHDRAWALS,
  whitelist: WHITELISTED_ADDRESSES,
  events: [],

  engines: {},
  engineInterval: null,
  started: false,

  // Live data defaults
  liveMode: false,
  feedConnected: false,
  feed: null,

  init: () => {
    if (get().started) return;
    const engines: Record<string, MatchingEngine> = {};
    const books: Record<string, OrderBookSnapshot> = {};
    const tickers: Record<string, Ticker24h> = {};
    const klines: Record<string, Kline[]> = {};

    for (const pair of TRADING_PAIRS) {
      const initial = INITIAL_PRICES[pair.symbol] ?? 100;
      const eng = new MatchingEngine(pair, initial);
      eng.seedBook(initial, 14, pair.base === "BTC" ? 0.4 : pair.base === "ETH" ? 1.2 : 50);
      engines[pair.symbol] = eng;
      books[pair.symbol] = eng.getSnapshot();
      const ks = generateKlines(pair.symbol, initial, 360);
      klines[pair.symbol] = ks;
      tickers[pair.symbol] = buildTicker(pair.symbol, initial, ks);

      eng.onTrade = (t) => {
        // One store update per trade (was three), including settlement when one of the
        // user's RESTING orders is the maker side of this trade.
        set((s) => {
          const next: Partial<MbuniCEXState> = { trades: [t, ...s.trades].slice(0, 100) };

          const tk = s.tickers[pair.symbol];
          if (tk) {
            next.tickers = {
              ...s.tickers,
              [pair.symbol]: { ...tk, lastPrice: t.price, priceChange: t.price - tk.lastPrice + tk.priceChange },
            };
          }

          const cur = s.klines[pair.symbol];
          if (cur && cur.length > 0) {
            const ks = cur.slice();
            const last = { ...ks[ks.length - 1] };
            last.close = t.price;
            last.high = Math.max(last.high, t.price);
            last.low = Math.min(last.low, t.price);
            last.volume = round(last.volume + t.qty, 6);
            ks[ks.length - 1] = last;
            next.klines = { ...s.klines, [pair.symbol]: ks };
          }

          // Maker = the side opposite the aggressor.
          const makerId = t.side === "BUY" ? t.sellerOrderId : t.buyerOrderId;
          const mi = s.orders.findIndex((o) => o.id === makerId);
          if (mi >= 0) {
            const mo = s.orders[mi];
            const makerIsBuy = mo.side === "BUY";
            const filled = round(mo.filledQty + t.qty, pair.baseDecimals);
            const remaining = Math.max(0, round(mo.remainingQty - t.qty, pair.baseDecimals));
            const prevCost = (mo.avgFillPrice ?? 0) * mo.filledQty;
            const orders = s.orders.slice();
            orders[mi] = {
              ...mo,
              filledQty: filled,
              remainingQty: remaining,
              status: remaining <= 0 ? "FILLED" : "PARTIALLY_FILLED",
              avgFillPrice: round((prevCost + t.qty * t.price) / filled, pair.priceDecimals),
            };
            next.orders = orders;
            const cost = t.qty * t.price;
            next.balances = s.balances.map((b) => {
              if (makerIsBuy) {
                if (b.asset === pair.quote) return { ...b, locked: round(Math.max(0, b.locked - cost), 8) };
                if (b.asset === pair.base) return { ...b, free: round(b.free + t.qty, 8) };
              } else {
                if (b.asset === pair.base) return { ...b, locked: round(Math.max(0, b.locked - t.qty), 8) };
                if (b.asset === pair.quote) return { ...b, free: round(b.free + cost, 8) };
              }
              return b;
            });
          }
          return next;
        });
      };
      eng.onBookUpdate = (snap) => {
        set((s) => ({ books: { ...s.books, [pair.symbol]: snap } }));
      };
      eng.onOrderUpdate = (o) => {
        if (o.userId === CURRENT_USER_ID) {
          set((s) => {
            const idx = s.orders.findIndex((x) => x.id === o.id);
            const next = [...s.orders];
            if (idx >= 0) {
              next[idx] = { ...next[idx], ...o };
            } else {
              next.unshift(o);
            }
            return { orders: next };
          });
        }
      };
    }

    // Seed some initial bot trades
    const initialTrades: Trade[] = [];
    for (let i = 0; i < 30; i++) {
      const pair = TRADING_PAIRS[Math.floor(Math.random() * TRADING_PAIRS.length)];
      const base = INITIAL_PRICES[pair.symbol];
      const price = base * (1 + (Math.random() - 0.5) * 0.001);
      initialTrades.push({
        id: uid("t"),
        pair: pair.symbol,
        price: round(price, pair.priceDecimals),
        qty: round(Math.random() * (pair.base === "BTC" ? 0.3 : pair.base === "ETH" ? 2 : 100), pair.baseDecimals),
        side: Math.random() < 0.5 ? "BUY" : "SELL",
        buyerOrderId: uid("o"),
        sellerOrderId: uid("o"),
        timestamp: Date.now() - (30 - i) * 1500,
      });
    }
    initialTrades.sort((a, b) => b.timestamp - a.timestamp);

    set({
      engines,
      books,
      tickers,
      klines,
      started: true,
      trades: initialTrades,
    });

    // Drive live activity on all engines (bots)
    const interval = setInterval(() => {
      const state = get();
      // Each tick: nudge a few engines
      const targets = Object.values(state.engines).slice(0, 6);
      for (const eng of targets) {
        eng.tick();
      }
      // Occasionally refresh tickers (simulate 24h calc)
      // (handled in onTrade)
    }, 1200);
    set({ engineInterval: interval });
  },

  setActivePair: (symbol) => set({ activePair: symbol }),

  // ----- Live data (Binance WebSocket) -----

  setLiveMode: (enabled) => {
    const state = get();
    if (enabled === state.liveMode) return;
    set({ liveMode: enabled });
    // When entering live mode, stop the simulated bot interval
    // (real data will drive the display instead)
    if (enabled && state.engineInterval) {
      clearInterval(state.engineInterval);
      set({ engineInterval: null });
    }
    // When leaving live mode, restart the bot interval
    if (!enabled && !state.engineInterval && state.started) {
      const interval = setInterval(() => {
        const s = get();
        const targets = Object.values(s.engines).slice(0, 6);
        for (const eng of targets) {
          eng.tick();
        }
      }, 1200);
      set({ engineInterval: interval });
    }
  },

  setFeedConnected: (connected) => set({ feedConnected: connected }),
  setFeed: (feed) => set({ feed }),

  updateBookFromBinance: (pair, bids, asks) => {
    const state = get();
    const p = findPair(state.pairs, pair);
    // Convert Binance depth to OrderBookSnapshot format
    const bookBids = bids.slice(0, 20).map(([price, qty]) => ({ price, qty, total: 0, orderCount: 1 }));
    const bookAsks = asks.slice(0, 20).map(([price, qty]) => ({ price, qty, total: 0, orderCount: 1 }));
    // Compute cumulative totals
    let bidTotal = 0;
    for (const b of bookBids) { bidTotal += b.qty; b.total = round(bidTotal, p.baseDecimals); }
    let askTotal = 0;
    for (const a of bookAsks) { askTotal += a.qty; a.total = round(askTotal, p.baseDecimals); }

    const bestBid = bookBids.length ? bookBids[0].price : 0;
    const bestAsk = bookAsks.length ? bookAsks[0].price : 0;
    const spread = bestBid && bestAsk ? round(bestAsk - bestBid, p.priceDecimals) : 0;
    const midPrice = bestBid && bestAsk ? round((bestBid + bestAsk) / 2, p.priceDecimals) : 0;
    const lastPrice = state.books[pair]?.lastPrice ?? midPrice;

    set((s) => ({
      books: {
        ...s.books,
        [pair]: { pair, bids: bookBids, asks: bookAsks, spread, midPrice, lastPrice, timestamp: Date.now() },
      },
    }));
  },

  updateTradeFromBinance: (pair, price, qty, side, timestamp) => {
    const state = get();
    const p = findPair(state.pairs, pair);
    const trade: Trade = {
      id: `binance_${timestamp}_${Math.random().toString(36).slice(2, 6)}`,
      pair,
      price: round(price, p.priceDecimals),
      qty: round(qty, p.baseDecimals),
      side,
      buyerOrderId: "binance",
      sellerOrderId: "binance",
      timestamp,
    };
    // Add to trade tape + update lastPrice on the book
    set((s) => {
      const trades = [trade, ...s.trades].slice(0, 100);
      const book = s.books[pair];
      const books = book
        ? { ...s.books, [pair]: { ...book, lastPrice: price } }
        : s.books;
      return { trades, books };
    });
    // Also update the engine's lastPrice so user orders fill at realistic prices
    const eng = state.engines[pair];
    if (eng) {
      (eng as any).lastPrice = price;
    }
  },

  updateTickerFromBinance: (pair, lastPrice, priceChangePct, high, low, volume, quoteVolume) => {
    const state = get();
    const existing = state.tickers[pair];
    const priceChange = existing ? lastPrice - (lastPrice - (lastPrice * priceChangePct / 100)) : 0;
    set((s) => ({
      tickers: {
        ...s.tickers,
        [pair]: {
          pair,
          lastPrice,
          priceChange: priceChange || (lastPrice * priceChangePct / 100),
          priceChangePct,
          high,
          low,
          volume,
          quoteVolume,
        },
      },
    }));
  },

  updateKlineFromBinance: (pair, openTime, open, high, low, close, volume, isClosed) => {
    set((s) => {
      const ks = s.klines[pair] ? [...s.klines[pair]] : [];
      if (ks.length === 0) {
        // No history — just add this candle
        ks.push({ openTime, open, high, low, close, volume });
        return { klines: { ...s.klines, [pair]: ks } };
      }
      const last = ks[ks.length - 1];
      // If the candle is for the same time period, update it
      if (last.openTime === openTime) {
        ks[ks.length - 1] = { openTime, open, high, low, close, volume };
      } else if (openTime > last.openTime) {
        // New candle — add it
        ks.push({ openTime, open, high, low, close, volume });
        // Keep max 500 candles
        if (ks.length > 500) ks.shift();
      }
      return { klines: { ...s.klines, [pair]: ks } };
    });
  },

  placeOrder: ({ pair, side, type, price, qty }) => {
    const state = get();
    const eng = state.engines[pair];
    if (!eng) return { ok: false, reason: "Unknown pair" };
    const p = findPair(state.pairs, pair);

    // Balance reservation check
    const baseAsset = p.base;
    const quoteAsset = p.quote;
    const isBuy = side === "BUY";

    if (type === "LIMIT" || type === "POST_ONLY") {
      const cost = (price ?? 0) * qty;
      const bal = state.balances.find((b) => b.asset === (isBuy ? quoteAsset : baseAsset));
      if (!bal || bal.free < (isBuy ? cost : qty)) {
        return { ok: false, reason: `Insufficient ${isBuy ? quoteAsset : baseAsset} balance` };
      }
    } else {
      // MARKET / IOC / FOK — estimate worst-case cost using best ask (BUY) or just check qty (SELL)
      if (isBuy) {
        const snap = state.books[pair];
        // Worst-case cost: the limit price for IOC/FOK, otherwise walk the visible asks.
        const est = price !== null ? price * qty : estimateBuyCost(snap?.asks ?? [], qty);
        const bal = state.balances.find((b) => b.asset === quoteAsset);
        if (!bal || bal.free < est) return { ok: false, reason: `Insufficient ${quoteAsset} for market buy` };
      } else {
        const bal = state.balances.find((b) => b.asset === baseAsset);
        if (!bal || bal.free < qty) return { ok: false, reason: `Insufficient ${baseAsset} balance` };
      }
    }

    const result = eng.placeOrder({ pair, side, type, price, qty, userId: CURRENT_USER_ID });

    // Settle the TAKER side from what actually happened:
    //  - pay/receive at the real fill prices (price improvement is kept by the user)
    //  - lock funds only for the part of a LIMIT/POST_ONLY order that rests on the book
    //  - IOC/FOK/MARKET remainders are cancelled, so they never lock anything
    if (result.order.status !== "REJECTED") {
      const filledQty = result.trades.reduce((acc, t) => acc + t.qty, 0);
      const filledCost = result.trades.reduce((acc, t) => acc + t.qty * t.price, 0);
      const rests =
        (type === "LIMIT" || type === "POST_ONLY") &&
        (result.order.status === "NEW" || result.order.status === "PARTIALLY_FILLED") &&
        result.order.remainingQty > 0;
      const restQty = rests ? result.order.remainingQty : 0;
      const lockQuote = round((price ?? 0) * restQty, 8);

      set((s) => ({
        balances: s.balances.map((b) => {
          if (isBuy) {
            if (b.asset === quoteAsset) {
              return { ...b, free: round(b.free - filledCost - lockQuote, 8), locked: round(b.locked + lockQuote, 8) };
            }
            if (b.asset === baseAsset) return { ...b, free: round(b.free + filledQty, 8) };
          } else {
            if (b.asset === baseAsset) {
              return { ...b, free: round(b.free - filledQty - restQty, 8), locked: round(b.locked + restQty, 8) };
            }
            if (b.asset === quoteAsset) return { ...b, free: round(b.free + filledCost, 8) };
          }
          return b;
        }),
      }));
    }

    // Push events
    for (const ev of result.events) {
      get().pushEvent(ev.subject, ev.payload);
    }

    return { ok: true, order: result.order };
  },

  cancelOrder: (orderId) => {
    const state = get();
    const order = state.orders.find((o) => o.id === orderId);
    if (!order) return;
    if (order.status !== "NEW" && order.status !== "PARTIALLY_FILLED") return;
    const eng = state.engines[order.pair];
    if (!eng) return;
    const ok = eng.cancel(orderId);
    if (ok) {
      // Release locked balance
      set((s) => {
        const p = findPair(s.pairs, order.pair);
        const isBuy = order.side === "BUY";
        const reserved = isBuy ? (order.price ?? 0) * order.remainingQty : order.remainingQty;
        const balances = s.balances.map((b) => {
          if (b.asset === (isBuy ? p.quote : p.base)) {
            return { ...b, free: round(b.free + reserved, 8), locked: round(Math.max(0, b.locked - reserved), 8) };
          }
          return b;
        });
        const orders = s.orders.map((o) => (o.id === orderId ? { ...o, status: "CANCELLED" as const, remainingQty: 0 } : o));
        return { balances, orders };
      });
      get().pushEvent("orders.cancelled", { id: orderId });
    }
  },

  requestWithdrawal: ({ asset, chain, amount }) => {
    const state = get();
    const bal = state.balances.find((b) => b.asset === asset);
    if (!bal || bal.free < amount) return { ok: false, reason: "Insufficient balance" };
    const chainInfo = state.chains.find((c) => c.name === chain);
    const fee = chainInfo ? chainInfo.withdrawalFeeUSD / (INITIAL_PRICES[`${asset}/USDT`] ?? 1) : 0;
    const w: Withdrawal = {
      id: uid("w"),
      asset,
      chain,
      amount,
      fee: round(fee, 6),
      address: state.whitelist[0]?.address ?? "",
      txHash: null,
      status: "PENDING",
      timestamp: Date.now(),
    };
    set((s) => ({
      withdrawals: [w, ...s.withdrawals],
      balances: s.balances.map((b) => (b.asset === asset ? { ...b, free: round(b.free - amount, 8), locked: round(b.locked + amount, 8) } : b)),
    }));
    get().pushEvent("withdrawals.completed", w);
    return { ok: true };
  },

  addWhitelist: ({ asset, chain, address, label }) => {
    const item: WhitelistedAddress = {
      id: uid("wa"),
      asset,
      chain,
      address,
      label,
      addedAt: Date.now(),
      timeLockHours: 24,
    };
    set((s) => ({ whitelist: [item, ...s.whitelist] }));
  },

  pushEvent: (subject, payload) => {
    const ev: SystemEvent = {
      id: uid("ev"),
      subject,
      payload,
      timestamp: Date.now(),
    };
    set((s) => ({ events: [ev, ...s.events].slice(0, 200) }));
  },
}));

function round(n: number, d: number) {
  const f = Math.pow(10, d);
  return Math.round(n * f) / f;
}

/** Cost of buying `qty` by walking the visible ask levels (extrapolates at the last level). */
export function estimateBuyCost(asks: Array<{ price: number; qty: number }>, qty: number): number {
  let remaining = qty;
  let cost = 0;
  for (const lvl of asks) {
    if (remaining <= 0) break;
    const take = Math.min(remaining, lvl.qty);
    cost += take * lvl.price;
    remaining -= take;
  }
  if (remaining > 0 && asks.length > 0) cost += remaining * asks[asks.length - 1].price;
  return cost;
}
MBUNI_EOF_7f3a
w 'src/lib/opencex/use-binance-feed.ts' <<'MBUNI_EOF_7f3a'
"use client";

import { useEffect, useRef } from "react";
import { useOpenCEX } from "@/lib/opencex/store";
import { BinanceFeed, type BinanceDepth, type BinanceKline, type BinanceTicker, type BinanceTrade } from "@/lib/opencex/binance-feed";

// Binance can emit dozens of trade/depth/ticker/kline messages per second.
// Applying each one straight to the store means one Zustand update (and one
// round of selector runs) per message. We coalesce them: only the latest
// depth/ticker/kline per flush window is applied, trades are applied in order.
const FLUSH_MS = 100;
const MAX_PENDING_TRADES = 200; // bound memory if the tab is throttled in the background

/**
 * Hook that connects the Binance WebSocket feed to the Zustand store.
 *
 * Call this once in the trading view (or any component that's always mounted
 * while the app is showing trading data). It will:
 *   1. Enable live mode (real Binance data instead of simulated bots)
 *   2. Connect to Binance's WebSocket for the active pair
 *   3. Switch streams when the active pair changes
 *   4. Clean up on unmount
 */
export function useBinanceFeed() {
  const activePair = useOpenCEX((s) => s.activePair);
  const setLiveMode = useOpenCEX((s) => s.setLiveMode);
  const setFeedConnected = useOpenCEX((s) => s.setFeedConnected);
  const setFeed = useOpenCEX((s) => s.setFeed);
  const updateBook = useOpenCEX((s) => s.updateBookFromBinance);
  const updateTrade = useOpenCEX((s) => s.updateTradeFromBinance);
  const updateTicker = useOpenCEX((s) => s.updateTickerFromBinance);
  const updateKline = useOpenCEX((s) => s.updateKlineFromBinance);

  const feedRef = useRef<BinanceFeed | null>(null);
  // The pair the live socket is currently subscribed to (set on mount).
  const connectedPairRef = useRef<string | null>(null);

  useEffect(() => {
    setLiveMode(true);

    let depth: BinanceDepth | null = null;
    let ticker: BinanceTicker | null = null;
    let kline: BinanceKline | null = null;
    let trades: BinanceTrade[] = [];
    let timer: ReturnType<typeof setTimeout> | null = null;

    const flush = () => {
      timer = null;
      const d = depth, tk = ticker, k = kline, tr = trades;
      depth = ticker = kline = null;
      trades = [];
      if (d) updateBook(d.pair, d.bids, d.asks);
      for (const t of tr) updateTrade(t.pair, t.price, t.qty, t.side, t.timestamp);
      if (tk) updateTicker(tk.pair, tk.lastPrice, tk.priceChangePct, tk.high, tk.low, tk.volume, tk.quoteVolume);
      if (k) updateKline(k.pair, k.openTime, k.open, k.high, k.low, k.close, k.volume, k.isClosed);
    };
    const schedule = () => {
      if (timer === null) timer = setTimeout(flush, FLUSH_MS);
    };

    const initialPair = useOpenCEX.getState().activePair;
    const feed = new BinanceFeed(initialPair, {
      onConnect: () => setFeedConnected(true),
      onDisconnect: () => setFeedConnected(false),
      onDepth: (d) => { depth = d; schedule(); },
      onTrade: (t) => {
        trades.push(t);
        if (trades.length > MAX_PENDING_TRADES) trades.splice(0, trades.length - MAX_PENDING_TRADES);
        schedule();
      },
      onTicker: (t) => { ticker = t; schedule(); },
      onKline: (k) => {
        // A closed candle must never be dropped in favour of a later open one.
        if (kline && kline.isClosed && kline.openTime !== k.openTime) updateKline(kline.pair, kline.openTime, kline.open, kline.high, kline.low, kline.close, kline.volume, kline.isClosed);
        kline = k;
        schedule();
      },
    });

    feed.connect();
    feedRef.current = feed;
    connectedPairRef.current = initialPair;
    setFeed(feed);

    return () => {
      if (timer !== null) clearTimeout(timer);
      feed.close();
      feedRef.current = null;
      connectedPairRef.current = null;
      setFeed(null);
      setFeedConnected(false);
      setLiveMode(false);
    };
  }, []); // Connect once on mount

  // Switch streams when the active pair changes (skipped on mount: the feed
  // was just created for this pair, and switching would tear down the socket
  // that is still handshaking).
  useEffect(() => {
    const feed = feedRef.current;
    if (!feed || connectedPairRef.current === activePair) return;
    connectedPairRef.current = activePair;
    feed.switchPair(activePair);
  }, [activePair]);
}
MBUNI_EOF_7f3a

rm -f src/app/api/route.ts services/trading/trading_service.go; rmdir engine/proto 2>/dev/null || true
echo "Done. Next steps:"
echo "  1) (cd engine && cargo generate-lockfile && cargo test)   # commit engine/Cargo.lock"
echo "  2) for s in trading wallet compliance marketdata; do (cd services/\$s && go mod tidy); done   # commit go.sum"
echo "  3) bun remove @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities @hookform/resolvers @mdxeditor/editor @reactuses/core @tanstack/react-query @tanstack/react-table @types/bcryptjs date-fns next-intl react-markdown react-syntax-highlighter uuid z-ai-web-dev-sdk zod sharp   # optional, shrinks install"
echo "  4) bun run test:unit && bunx tsc --noEmit && bun run lint"
