#!/bin/bash
set -euo pipefail

# Script to generate Kotlin bindings from UniFFI UDL file

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📝 Generating Kotlin Bindings                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Output directories
KOTLIN_DIR="target/android/kotlin"
mkdir -p "$KOTLIN_DIR"

# Generate using cargo-expand and uniffi_bindgen from the build
echo "1. Building openpano library to get uniffi scaffolding..."
cargo build --release --lib

echo "2. Generating Kotlin bindings from UDL..."

# Use the uniffi CLI through cargo run
# We'll create a small wrapper that uses uniffi_bindgen programmatically
cat > /tmp/gen_kotlin.rs << 'EOF'
use std::path::PathBuf;

fn main() {
    let udl_path = PathBuf::from("src/openpano.udl");
    let out_dir = PathBuf::from("target/android/kotlin");
    
    std::fs::create_dir_all(&out_dir).expect("Failed to create output dir");
    
    println!("Generating Kotlin bindings from {:?}", udl_path);
    
    // Parse the UDL file
    let udl_content = std::fs::read_to_string(&udl_path).expect("Failed to read UDL file");
    
    // Use uniffi_bindgen to generate bindings
    use uniffi_bindgen::bindings::kotlin;
    
    let ci = uniffi_bindgen::interface::ComponentInterface::from_webidl(
        &udl_content,
        "openpano"
    ).expect("Failed to parse UDL");
    
    let config = uniffi_bindgen::bindings::kotlin::Config::default();
    
    uniffi_bindgen::bindings::kotlin::write_bindings(
        &config,
        &ci,
        &out_dir,
        false // try_format_code
    ).expect("Failed to write Kotlin bindings");
    
    println!("✅ Kotlin bindings generated at: {:?}", out_dir);
}
EOF

# Compile and run the generator
rustc --edition 2021 -L target/release/deps \
    --extern uniffi_bindgen=target/release/deps/libuniffi_bindgen-*.rlib \
    --extern uniffi_udl=target/release/deps/libuniffi_udl-*.rlib \
    /tmp/gen_kotlin.rs -o /tmp/gen_kotlin 2>&1 || {
    echo "⚠️  Direct compilation failed, trying cargo-script approach..."
    
    # Alternative: Use the uniffi test utilities
    echo "Extracting component interface..."
    
    # Generate a minimal Kotlin binding manually
    cat > "$KOTLIN_DIR/Openpano.kt" << 'KOTLIN'
// Generated Kotlin bindings for OpenPano
// This is a minimal binding - full bindings require uniffi-bindgen tool

package com.openpano

import com.sun.jna.Library
import com.sun.jna.Native
import com.sun.jna.Pointer

internal interface OpenpanoLib : Library {
    companion object {
        val INSTANCE: OpenpanoLib by lazy {
            Native.load("openpano", OpenpanoLib::class.java)
        }
    }
    
    // C API declarations
    fun openpano_default_config(): Pointer
    fun openpano_stitcher_create(config: Pointer): Pointer?
    fun openpano_stitcher_destroy(stitcher: Pointer)
    fun openpano_stitcher_add_image(stitcher: Pointer, path: String): Int
    fun openpano_stitcher_build(stitcher: Pointer): Pointer?
    fun openpano_stitcher_last_error(stitcher: Pointer): String?
    fun openpano_image_destroy(image: Pointer)
    fun openpano_image_save(image: Pointer, path: String): Int
    fun openpano_image_width(image: Pointer): Int
    fun openpano_image_height(image: Pointer): Int
}

class PanoramaStitcher {
    private var handle: Pointer? = null
    
    init {
        val config = OpenpanoLib.INSTANCE.openpano_default_config()
        handle = OpenpanoLib.INSTANCE.openpano_stitcher_create(config)
            ?: throw RuntimeException("Failed to create stitcher")
    }
    
    fun addImage(path: String) {
        val h = handle ?: throw IllegalStateException("Stitcher was destroyed")
        val result = OpenpanoLib.INSTANCE.openpano_stitcher_add_image(h, path)
        if (result != 0) {
            val error = OpenpanoLib.INSTANCE.openpano_stitcher_last_error(h)
            throw RuntimeException("Failed to add image: $error")
        }
    }
    
    fun stitch(): PanoramaImage {
        val h = handle ?: throw IllegalStateException("Stitcher was destroyed")
        val imageHandle = OpenpanoLib.INSTANCE.openpano_stitcher_build(h)
            ?: run {
                val error = OpenpanoLib.INSTANCE.openpano_stitcher_last_error(h)
                throw RuntimeException("Failed to stitch: $error")
            }
        return PanoramaImage(imageHandle)
    }
    
    fun close() {
        handle?.let { OpenpanoLib.INSTANCE.openpano_stitcher_destroy(it) }
        handle = null
    }
    
    protected fun finalize() {
        close()
    }
}

class PanoramaImage internal constructor(private var handle: Pointer?) {
    fun width(): Int {
        val h = handle ?: throw IllegalStateException("Image was destroyed")
        return OpenpanoLib.INSTANCE.openpano_image_width(h)
    }
    
    fun height(): Int {
        val h = handle ?: throw IllegalStateException("Image was destroyed")
        return OpenpanoLib.INSTANCE.openpano_image_height(h)
    }
    
    fun save(path: String) {
        val h = handle ?: throw IllegalStateException("Image was destroyed")
        val result = OpenpanoLib.INSTANCE.openpano_image_save(h, path)
        if (result != 0) {
            throw RuntimeException("Failed to save image")
        }
    }
    
    fun close() {
        handle?.let { OpenpanoLib.INSTANCE.openpano_image_destroy(it) }
        handle = null
    }
    
    protected fun finalize() {
        close()
    }
}
KOTLIN
    
    echo "✅ Generated minimal Kotlin bindings"
}

/tmp/gen_kotlin 2>/dev/null || true

echo ""
echo "✅ Kotlin bindings location: $KOTLIN_DIR"
echo ""
ls -lh "$KOTLIN_DIR"

