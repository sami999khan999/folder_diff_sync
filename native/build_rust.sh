#!/bin/bash
set -e
cd "$(dirname "$0")/file_transfer_rs"
echo "Building Rust library in release mode..."
cargo build --release
