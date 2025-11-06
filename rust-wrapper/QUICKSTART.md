# OpenPano Hybrid C++/Rust Quickstart Guide

Get up and running with the hybrid C++/Rust implementation in 15 minutes!

## 📋 Prerequisites

Install the following tools:

```bash
# Rust (required)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# CMake (required)
# macOS:
brew install cmake eigen libjpeg

# Ubuntu/Debian:
sudo apt install cmake libeigen3-dev libjpeg-dev build-essential

# Arch Linux:
sudo pacman -S cmake eigen libjpeg gcc
```

## 🚀 Quick Build

```bash
# 1. Navigate to rust-wrapper
cd rust-wrapper

# 2. Build everything (C++ + Rust)
cargo build --release

# 3. Run the Rust example
cargo run --release --example rust_example -- ../path/to/img1.jpg ../path/to/img2.jpg

# Success! You should see panorama_output.jpg
```

## 🐍 Python Setup (5 minutes)

```bash
# Install maturin (Python build tool for Rust)
pip install maturin

# Build and install Python package
cd rust-wrapper
maturin develop --release

# Test it!
python examples/python_example.py img1.jpg img2.jpg img3.jpg

# Or in Python REPL:
python
>>> from openpano import stitch_panorama
>>> panorama = stitch_panorama(["img1.jpg", "img2.jpg"], None)
>>> panorama.save("out.jpg")
>>> print(f"{panorama.width()}x{panorama.height()}")
```

## 📱 iOS Setup (10 minutes)

```bash
# 1. Install cargo-lipo
cargo install cargo-lipo

# 2. Add iOS targets
rustup target add aarch64-apple-ios x86_64-apple-ios

# 3. Build universal library
cd rust-wrapper
cargo lipo --release

# 4. Generate Swift bindings
cargo run --bin uniffi-bindgen generate src/openpano.udl \
    --language swift \
    --out-dir ../bindings/swift

# 5. Add to Xcode project:
#    - Link: target/universal/release/libopenpano.a
#    - Add: bindings/swift/openpano.swift to your project
#    - Add C++ stdlib: Build Settings → Other Linker Flags → -lc++

# 6. Use in Swift:
```

```swift
import OpenPano

let paths = ["img1.jpg", "img2.jpg"]
let panorama = try stitchPanorama(imagePaths: paths, config: nil)
try panorama.save(path: "output.jpg")
```

## 🤖 Android Setup (15 minutes)

```bash
# 1. Install cargo-ndk
cargo install cargo-ndk

# 2. Set up Android NDK
export ANDROID_NDK_HOME=/path/to/android-ndk
# Or install via Android Studio SDK Manager

# 3. Add Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi

# 4. Build for Android
cd rust-wrapper
cargo ndk -t arm64-v8a -t armeabi-v7a --platform 21 build --release

# 5. Generate Kotlin bindings
cargo run --bin uniffi-bindgen generate src/openpano.udl \
    --language kotlin \
    --out-dir ../bindings/kotlin

# 6. Copy libraries to Android project:
#    - Copy target/aarch64-linux-android/release/libopenpano.so
#          to app/src/main/jniLibs/arm64-v8a/
#    - Copy target/armv7-linux-androideabi/release/libopenpano.so
#          to app/src/main/jniLibs/armeabi-v7a/
#    - Add bindings/kotlin/*.kt to your project

# 7. Use in Kotlin:
```

```kotlin
import com.openpano.*

val paths = listOf("img1.jpg", "img2.jpg")
val panorama = stitchPanorama(paths, null)
panorama.save("output.jpg")
```

## 🔧 Troubleshooting

### "Eigen3 not found"

```bash
# macOS
brew install eigen
# or
export Eigen3_DIR=/usr/local/include/eigen3/cmake

# Linux
sudo apt install libeigen3-dev
# or
export Eigen3_DIR=/usr/include/eigen3/cmake
```

### "libjpeg not found"

```bash
# macOS
brew install libjpeg

# Linux
sudo apt install libjpeg-dev
```

### Build fails with "undefined reference to std::..."

Make sure C++ standard library is linked:
```bash
# Check build.rs has correct linking for your platform
# Linux: libstdc++
# macOS: libc++
```

### Python: "No module named 'openpano'"

```bash
# Make sure you ran maturin develop
cd rust-wrapper
maturin develop --release

# Or install the wheel
maturin build --release
pip install target/wheels/*.whl
```

### iOS: "Symbol not found"

Add to Xcode project:
- Build Settings → Other Linker Flags → `-lc++`
- Build Settings → Enable Bitcode → No (for debug)

### Android: "java.lang.UnsatisfiedLinkError"

1. Check libraries are in correct jniLibs folders
2. Make sure library name matches: `libopenpano.so`
3. Load in Java/Kotlin:
```kotlin
companion object {
    init {
        System.loadLibrary("openpano")
    }
}
```

## 📖 Next Steps

- Read [README.md](README.md) for detailed API documentation
- Check [examples/](examples/) for more code samples
- See [src/openpano.udl](src/openpano.udl) for the full API reference
- Explore configuration options in `StitcherConfig`

## 🎯 Performance Tips

1. **Downscale images** to ~2-4 megapixels before stitching
2. Use **release builds** (`--release` flag)
3. Enable **LTO** in release profile (already configured)
4. For Python: use `--features pyo3/extension-module`

## 📊 Expected Performance

On a modern laptop (i7/M1):
- 3 images (1920x1080): ~3-5 seconds
- 5 images (1920x1080): ~8-12 seconds
- 10 images (1920x1080): ~25-40 seconds

Memory usage: ~500MB-2GB depending on image count and size

## 🤝 Need Help?

- Check existing [OpenPano issues](https://github.com/ppwwyyxx/OpenPano/issues)
- Read the [OpenPano paper](http://matthewalunbrown.com/papers/ijcv2007.pdf)
- File a new issue with:
  - Platform (macOS/Linux/Windows/iOS/Android)
  - Rust version (`rustc --version`)
  - Build error output
  - Sample images (if possible)

Happy stitching! 📸🎉

