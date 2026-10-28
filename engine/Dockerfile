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
