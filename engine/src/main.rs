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
