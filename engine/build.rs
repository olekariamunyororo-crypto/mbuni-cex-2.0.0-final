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
