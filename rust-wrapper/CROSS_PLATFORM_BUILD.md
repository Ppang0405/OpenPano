# 📱 Cross-Platform Build Guide

Complete guide for building OpenPano for **Android** and **iOS**.

## 📋 Prerequisites

### Common Requirements
- **macOS** (for iOS builds)
- **Rust** toolchain installed
- **Eigen3** library: `brew install eigen`
- **CMake**: `brew install cmake`

### Android Requirements
- **Android NDK** (version 21+)
  ```bash
  # Install via Android Studio or:
  brew install --cask android-ndk
  
  # Set environment variable
  export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/26.1.10909125
  ```

### iOS Requirements
- **Xcode** with command-line tools
  ```bash
  xcode-select --install
  ```

### Install Cross-Compilation Tools
```bash
# One-time setup
cargo install cargo-ndk cargo-lipo

# Add target architectures
rustup target add \
  aarch64-linux-android \
  armv7-linux-androideabi \
  x86_64-linux-android \
  aarch64-apple-ios \
  x86_64-apple-ios \
  aarch64-apple-ios-sim
```

---

## 🤖 Building for Android

### Step 1: Set Android NDK Path
```bash
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/26.1.10909125
```

### Step 2: Build Native Libraries
```bash
cd rust-wrapper
./build-android.sh
```

This will build for:
- **arm64-v8a** (64-bit ARM devices) - Most modern Android phones
- **armeabi-v7a** (32-bit ARM devices) - Older Android devices
- **x86_64** (Intel emulators)

**Build time:** ~5-10 minutes per architecture

### Step 3: Generate Kotlin Bindings
The build script automatically generates Kotlin bindings using UniFFI:
- Location: `target/android/kotlin/`
- Files:
  - `Openpano.kt` - Main Kotlin API
  - `openpano.kt` - UniFFI generated code

### Step 4: Create AAR Package
```bash
./create-aar.sh
```

**Output:** `target/android/openpano-0.1.0.aar`

---

## 🍎 Building for iOS

### Step 1: Build Native Libraries
```bash
cd rust-wrapper
./build-ios.sh
```

This will build for:
- **aarch64-apple-ios** (iPhone/iPad devices)
- **aarch64-apple-ios-sim** (M1/M2 Mac simulators)
- **x86_64-apple-ios** (Intel Mac simulators)

**Build time:** ~5-10 minutes per architecture

### Step 2: Generate Swift Bindings
The build script automatically generates Swift bindings using UniFFI:
- Location: `target/ios/swift/`
- Files:
  - `openpano.swift` - Main Swift API
  - `openpanoFFI.h` - C header for FFI
  - `module.modulemap` - Module definition

### Step 3: Create XCFramework
```bash
./create-xcframework.sh
```

**Output:** `target/ios/xcframework/OpenPano.xcframework`

---

## 📦 Using the Libraries

### Android Usage

#### 1. Add AAR to Your Project
```gradle
// app/build.gradle
dependencies {
    implementation files('libs/openpano-0.1.0.aar')
}
```

#### 2. Copy Kotlin Bindings
Copy files from `target/android/kotlin/` to your Android project:
```
app/src/main/kotlin/com/openpano/
  ├── Openpano.kt
  └── openpano.kt
```

#### 3. Use in Kotlin
```kotlin
import com.openpano.*

// Create stitcher
val config = StitcherConfig(
    cylinderMode = false,
    estimateCamera = true,
    orderedInput = true,
    crop = true,
    focalLength = 37.0f,
    maxOutputSize = 8000
)

val stitcher = Stitcher(config)

// Add images
stitcher.addImage("/path/to/image1.jpg")
stitcher.addImage("/path/to/image2.jpg")

// Stitch
val panorama = stitcher.stitch()

// Save result
panorama.save("/path/to/output.jpg")

// Get dimensions
val width = panorama.width()
val height = panorama.height()
```

### iOS Usage

#### 1. Add XCFramework to Xcode
1. Drag `OpenPano.xcframework` into your Xcode project
2. Select your target → "Frameworks, Libraries, and Embedded Content"
3. Set to "Embed & Sign"

#### 2. Copy Swift Bindings
Copy files from `target/ios/swift/` to your Xcode project:
```
Sources/
  ├── openpano.swift
  └── openpanoFFI.h
```

#### 3. Use in Swift
```swift
import OpenPano

// Create stitcher
let config = StitcherConfig(
    cylinderMode: false,
    estimateCamera: true,
    transMode: false,
    orderedInput: true,
    crop: true,
    focalLength: 37.0,
    maxOutputSize: 8000
)

let stitcher = try Stitcher(config: config)

// Add images
try stitcher.addImage(path: imageURL1.path)
try stitcher.addImage(path: imageURL2.path)

// Stitch
let panorama = try stitcher.stitch()

// Save result
try panorama.save(path: outputURL.path)

// Get dimensions
let width = panorama.width()
let height = panorama.height()
```

---

## 🐛 Troubleshooting

### Android Issues

#### `ANDROID_NDK_HOME not set`
```bash
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/26.1.10909125
```

#### `Eigen3 not found`
```bash
brew install eigen
```

#### `cargo-ndk: unknown package`
Make sure you're using the correct syntax:
```bash
cargo ndk --target arm64-v8a --platform 21 build --release
```

### iOS Issues

#### `Eigen3 not found`
```bash
brew install eigen
```

#### `xcodebuild command not found`
```bash
xcode-select --install
```

#### `Invalid architecture`
Make sure you have the correct iOS targets installed:
```bash
rustup target list --installed | grep apple-ios
```

### Common Issues

#### `config.cfg not found`
The C++ code looks for `config.cfg` in the current working directory. Make sure it's copied to your app bundle (iOS) or assets folder (Android).

#### `Cannot find feature in images`
SIFT feature detection can fail on:
- Low-contrast images
- Images without texture
- Very small images

Adjust SIFT parameters in `config.cfg`:
```
CONTRAST_THRES 2e-2  # Lower = more features
EDGE_RATIO 10        # Higher = more features
```

---

## 📊 Build Artifacts

### Android
```
target/android/
├── aar/
│   └── openpano-0.1.0.aar (AAR package)
├── kotlin/
│   ├── Openpano.kt (Kotlin API)
│   └── openpano.kt (UniFFI generated)
└── jni/
    ├── arm64-v8a/libopenpano.so
    ├── armeabi-v7a/libopenpano.so
    └── x86_64/libopenpano.so
```

### iOS
```
target/ios/
├── xcframework/
│   └── OpenPano.xcframework/ (XCFramework package)
├── swift/
│   ├── openpano.swift (Swift API)
│   ├── openpanoFFI.h (C header)
│   └── module.modulemap
└── Static libraries:
    ├── target/aarch64-apple-ios/release/libopenpano.a
    ├── target/aarch64-apple-ios-sim/release/libopenpano.a
    └── target/x86_64-apple-ios/release/libopenpano.a
```

---

## 🚀 Quick Build Commands

### Android (All-in-One)
```bash
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/26.1.10909125
cd rust-wrapper
./build-android.sh && ./create-aar.sh
```

### iOS (All-in-One)
```bash
cd rust-wrapper
./build-ios.sh && ./create-xcframework.sh
```

---

## 📈 Performance Notes

### Build Times (M1/M2 Mac)
- **Android arm64-v8a**: ~7 minutes
- **Android armeabi-v7a**: ~7 minutes
- **Android x86_64**: ~6 minutes
- **iOS device (ARM64)**: ~6 minutes
- **iOS simulator (ARM64)**: ~6 minutes
- **iOS simulator (x86_64)**: ~7 minutes

**Total:** ~40 minutes for all architectures

### Library Sizes
- **Android .so** (per arch): ~1.5 MB
- **iOS .a** (per arch): ~2.0 MB
- **AAR package**: ~4.5 MB
- **XCFramework**: ~6.0 MB

---

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Build Cross-Platform

on: [push, pull_request]

jobs:
  build-android:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Install Android NDK
        run: |
          brew install --cask android-ndk
      - name: Install dependencies
        run: brew install eigen cmake
      - name: Install cargo-ndk
        run: cargo install cargo-ndk
      - name: Add Android targets
        run: |
          rustup target add aarch64-linux-android
          rustup target add armv7-linux-androideabi
          rustup target add x86_64-linux-android
      - name: Build Android
        run: |
          cd rust-wrapper
          ./build-android.sh
          ./create-aar.sh
      - name: Upload AAR
        uses: actions/upload-artifact@v3
        with:
          name: android-aar
          path: rust-wrapper/target/android/*.aar

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Install dependencies
        run: brew install eigen cmake
      - name: Add iOS targets
        run: |
          rustup target add aarch64-apple-ios
          rustup target add x86_64-apple-ios
          rustup target add aarch64-apple-ios-sim
      - name: Build iOS
        run: |
          cd rust-wrapper
          ./build-ios.sh
          ./create-xcframework.sh
      - name: Upload XCFramework
        uses: actions/upload-artifact@v3
        with:
          name: ios-xcframework
          path: rust-wrapper/target/ios/xcframework/
```

---

## 📝 Next Steps

1. ✅ Build libraries for your target platforms
2. ✅ Integrate into your app projects
3. ✅ Copy Swift/Kotlin bindings
4. ✅ Test on physical devices
5. ✅ Deploy to app stores

**Need help?** Check the example apps in `examples/` directory.

