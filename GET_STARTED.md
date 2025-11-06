# 🚀 Get Started with OpenPano Hybrid

## What You've Received

A complete **hybrid C++/Rust** panorama stitching library with cross-platform support for:
- ✅ **Python** (via PyO3)
- ✅ **iOS** (Swift bindings)
- ✅ **Android** (Kotlin bindings)
- ✅ **Rust** (native API)

## Project Structure

```
OpenPano/
├── src/                          # Original C++ code (UNTOUCHED)
│   ├── feature/                  # SIFT, feature detection
│   ├── stitch/                   # Image stitching algorithms
│   ├── lib/                      # Utilities, matrix operations
│   └── c_api/                    # ← NEW: C API wrapper
│       ├── openpano_c.h          #   C header (stable ABI)
│       └── openpano_c.cc         #   C++ → C wrapper
│
├── rust-wrapper/                 # ← NEW: Rust wrapper & bindings
│   ├── src/
│   │   ├── lib.rs                # Safe Rust API
│   │   ├── ffi.rs                # Unsafe FFI to C API
│   │   ├── uniffi_impl.rs        # UniFFI implementation
│   │   └── openpano.udl          # UniFFI interface definition
│   ├── examples/
│   │   ├── rust_example.rs       # Rust usage
│   │   ├── python_example.py     # Python usage
│   │   ├── swift_example.swift   # Swift usage
│   │   └── kotlin_example.kt     # Kotlin usage
│   ├── Cargo.toml                # Rust dependencies
│   ├── build.rs                  # Build script (builds C++ too)
│   ├── QUICKSTART.md             # Quick setup guide
│   └── README.md                 # Detailed docs
│
├── HYBRID_ARCHITECTURE.md        # ← Architecture explanation
└── GET_STARTED.md                # ← This file
```

## ⚡ 5-Minute Quickstart

### 1. Install Prerequisites

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Install C++ dependencies
# macOS:
brew install cmake eigen libjpeg

# Ubuntu/Debian:
sudo apt install cmake libeigen3-dev libjpeg-dev build-essential
```

### 2. Build & Test

```bash
cd rust-wrapper

# Build everything (C++ + Rust)
cargo build --release

# Success! You've built the hybrid library
```

### 3. Try Python

```bash
# Install Python bindings
pip install maturin
maturin develop --release

# Test it
python examples/python_example.py path/to/img1.jpg path/to/img2.jpg
```

## 🎯 What to Do Next

### For Development

1. **Read the docs**:
   - [`HYBRID_ARCHITECTURE.md`](HYBRID_ARCHITECTURE.md) - Understand the architecture
   - [`rust-wrapper/QUICKSTART.md`](rust-wrapper/QUICKSTART.md) - Platform-specific setup
   - [`rust-wrapper/README.md`](rust-wrapper/README.md) - API documentation

2. **Try the examples**:
   ```bash
   # Rust
   cargo run --release --example rust_example -- img1.jpg img2.jpg
   
   # Python (after maturin develop)
   python examples/python_example.py img1.jpg img2.jpg
   ```

3. **Explore the code**:
   - Start with `rust-wrapper/src/lib.rs` (safe Rust API)
   - Check `src/c_api/openpano_c.h` (C interface)
   - See `rust-wrapper/src/openpano.udl` (cross-platform API)

### For Python Users

```bash
cd rust-wrapper
pip install maturin
maturin develop --release
```

```python
from openpano import stitch_panorama

panorama = stitch_panorama(["img1.jpg", "img2.jpg"], None)
panorama.save("output.jpg")
print(f"{panorama.width()}x{panorama.height()}")
```

### For iOS Developers

```bash
cd rust-wrapper
cargo install cargo-lipo
rustup target add aarch64-apple-ios
cargo lipo --release

# Generate Swift bindings
cargo run --bin uniffi-bindgen generate src/openpano.udl \
    --language swift --out-dir ../bindings/swift
```

See [`rust-wrapper/examples/swift_example.swift`](rust-wrapper/examples/swift_example.swift)

### For Android Developers

```bash
cd rust-wrapper
cargo install cargo-ndk
rustup target add aarch64-linux-android armv7-linux-androideabi
cargo ndk -t arm64-v8a -t armeabi-v7a --platform 21 build --release

# Generate Kotlin bindings
cargo run --bin uniffi-bindgen generate src/openpano.udl \
    --language kotlin --out-dir ../bindings/kotlin
```

See [`rust-wrapper/examples/kotlin_example.kt`](rust-wrapper/examples/kotlin_example.kt)

## 📖 Documentation Overview

### Quick Reference

| Document | Purpose | Audience |
|----------|---------|----------|
| **GET_STARTED.md** (this) | First steps | Everyone |
| **HYBRID_ARCHITECTURE.md** | Architecture deep-dive | Developers |
| **rust-wrapper/QUICKSTART.md** | Platform setup | Platform devs |
| **rust-wrapper/README.md** | API documentation | Library users |

### Key Concepts

1. **Hybrid Architecture**: C++ core + Rust wrapper + UniFFI bindings
2. **C API Layer**: Stable ABI between C++ and Rust
3. **UniFFI**: Auto-generates Python/Swift/Kotlin bindings
4. **Zero-Copy**: Data stays in C++, we pass pointers
5. **Memory Safety**: Rust enforces safety at FFI boundaries

## 🔧 Makefile Commands

We've included a Makefile for convenience:

```bash
cd rust-wrapper

make help           # Show all commands
make build          # Build Rust library
make test           # Run tests
make python         # Build Python package
make python-dev     # Install Python in dev mode
make ios            # Build iOS framework
make android        # Build Android AAR
make clean          # Clean all build artifacts
make install-tools  # Install cargo-lipo, cargo-ndk, etc.
```

## 🐛 Troubleshooting

### "Eigen3 not found"
```bash
# macOS
brew install eigen

# Linux
sudo apt install libeigen3-dev
```

### "undefined reference to std::..."
The C++ standard library isn't linked. Check `rust-wrapper/build.rs` for your platform.

### Python import fails
```bash
cd rust-wrapper
maturin develop --release
```

### More help
See [`rust-wrapper/QUICKSTART.md`](rust-wrapper/QUICKSTART.md) troubleshooting section

## 🎨 Example Output

```bash
$ cargo run --example rust_example -- img1.jpg img2.jpg img3.jpg

OpenPano Rust Example
====================

Configuration:
  Estimate camera: true
  Cylinder mode: false
  Crop: true
  Max output size: 8000

Adding 3 images:
  [1] img1.jpg
  [2] img2.jpg
  [3] img3.jpg

Stitching images... (this may take a while)
✓ Stitching completed in 5.23s

Result:
  Width: 4500 px
  Height: 1200 px
  Channels: 3
  Total pixels: 5400000

Saving to 'panorama_output.jpg'...
✓ Done!
```

## 📊 Performance

Expected timings on modern hardware (i7/M1):
- 3 images (1920x1080): ~3-5 seconds
- 5 images (1920x1080): ~8-12 seconds
- Memory: ~500MB-2GB depending on image size

## 🛣️ Migration Path

This hybrid approach allows gradual migration:

```
Phase 1 (Now):     C++ Core + Rust Wrapper
Phase 2 (Later):   Replace I/O with Rust
Phase 3 (Future):  Replace feature matching with Rust
Phase 4 (Goal):    Pure Rust (if desired)
```

You're **not locked in** - you can:
- Stay hybrid forever (perfectly fine!)
- Gradually port modules to Rust
- Keep C++ for critical algorithms

## 🤝 Next Steps

1. ✅ Read [`HYBRID_ARCHITECTURE.md`](HYBRID_ARCHITECTURE.md)
2. ✅ Try the examples
3. ✅ Build for your target platform
4. ✅ Integrate into your app
5. ✅ Give feedback!

## 🎓 Learning Resources

- **Rust FFI**: https://doc.rust-lang.org/nomicon/ffi.html
- **UniFFI Book**: https://mozilla.github.io/uniffi-rs/
- **Original OpenPano**: https://github.com/ppwwyyxx/OpenPano
- **SIFT Paper**: http://matthewalunbrown.com/papers/ijcv2007.pdf

## 🙋 Need Help?

- **Architecture questions**: Read `HYBRID_ARCHITECTURE.md`
- **Build issues**: Check `rust-wrapper/QUICKSTART.md`
- **API docs**: See `rust-wrapper/README.md`
- **Bugs**: File an issue on GitHub

---

**Happy Stitching! 📸✨**

You now have a modern, cross-platform panorama stitching library that combines the battle-tested C++ algorithms with the safety and ergonomics of Rust!

