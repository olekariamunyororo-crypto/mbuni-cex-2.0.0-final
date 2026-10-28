//! Mbuni CEX 2.0 — matching engine library.
//!
//! The gRPC binary lives in `main.rs`; keeping the logic in a library crate lets
//! `tests/` (integration tests) and benchmarks import it.

pub mod matching_engine;

/// Generated protobuf + gRPC code for package `mbuni.v1`.
pub mod proto {
    tonic::include_proto!("mbuni.v1");
}
