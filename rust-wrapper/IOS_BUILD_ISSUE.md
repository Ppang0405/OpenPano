# iOS Build Issue & Solution

## Current Status

✅ **C++ Core builds successfully** for iOS (arm64)  
✅ **CImg system calls** properly disabled  
✅ **Eigen3** found and configured  
✅ **Static libraries** created (`.a` files)  
❌ **Rust linker** fails to find iOS SDK

## The Problem

The Rust iOS target is configured to use `/Applications/Xcode.app` but your Xcode is installed at `/Applications/Xcode_16.2.app`.

### Error Message
```
clang: warning: no such sysroot directory: '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk'
ld: library 'c++' not found
```

### Root Cause
Rust's iOS target configuration is hardcoded at installation time and points to the default Xcode location. The `SDKROOT` environment variable doesn't override this for iOS targets.

## Solutions

### Option 1: Create Xcode Symlink (Recommended)

Create a symlink from the standard Xcode location to your versioned installation:

```bash
sudo ln -s /Applications/Xcode_16.2.app /Applications/Xcode.app
```

Then rebuild:
```bash
cd rust-wrapper
./build-ios.sh
```

**Pros**: Fixes the issue permanently, works for all Rust iOS builds  
**Cons**: Requires sudo, affects system-wide Xcode location

### Option 2: Use `xcode-select`

Switch the active Xcode installation:

```bash
sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer
```

Then rebuild:
```bash
cd rust-wrapper  
./build-ios.sh
```

**Pros**: Official Apple method, clean  
**Cons**: Requires sudo, changes default Xcode for all tools

### Option 3: Configure Rust iOS Target

Create a `.cargo/config.toml` file with explicit linker flags:

```toml
[target.aarch64-apple-ios]
linker = "clang"
rustflags = [
    "-C", "link-arg=-isysroot",
    "-C", "link-arg=/Applications/Xcode_16.2.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk",
    "-C", "link-arg=-L/Applications/Xcode_16.2.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/16/lib/darwin"
]

[target.x86_64-apple-ios]
linker = "clang"
rustflags = [
    "-C", "link-arg=-isysroot",
    "-C", "link-arg=/Applications/Xcode_16.2.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
]

[target.aarch64-apple-ios-sim]
linker = "clang"
rustflags = [
    "-C", "link-arg=-isysroot",
    "-C", "link-arg=/Applications/Xcode_16.2.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
]
```

**Pros**: No sudo needed, project-specific  
**Cons**: Verbose, needs maintenance for Xcode updates

## Verification

After applying any solution, verify the build:

```bash
cd rust-wrapper
./build-ios.sh
```

You should see:
```
✓ aarch64-apple-ios: libopenpano.a
✓ x86_64-apple-ios: libopenpano.a  
✓ aarch64-apple-ios-sim: libopenpano.a
```

## What Was Fixed

Already resolved before hitting this linker issue:

1. ✅ **CImg iOS Compatibility**: Added `-Dcimg_no_system_calls` to disable `system()` calls
2. ✅ **C++14 Upgrade**: Upgraded from C++11 for modern Eigen3
3. ✅ **Cross-Compilation**: Removed `-march=native` flag
4. ✅ **JPEG Disabled**: iOS builds without libjpeg
5. ✅ **Eigen3 Path**: Using Homebrew Eigen3 for iOS builds
6. ✅ **CMake iOS Config**: Proper iOS toolchain configuration

## Technical Details

### Build Flow for iOS
1. `build.rs` detects iOS target
2. CMake configures with iOS toolchain  
3. C++ core compiles to `.a` files ✅
4. Rust attempts to link → **FAILS HERE** ❌
5. Should produce `.dylib` or `.a` for XCFramework

### Files Involved
- `CMakeLists.txt`: C++ compiler flags
- `src/CMakeLists.txt`: iOS-specific CImg config
- `rust-wrapper/build.rs`: CMake invocation, iOS detection
- `rust-wrapper/build-ios.sh`: Build script with `DEVELOPER_DIR`

### Linker Command (for reference)
```bash
cc -lopenpano_core -lopenpano_c -llodepng -lc++ \
   -target arm64-apple-ios10.0.0 \
   -isysroot /Applications/Xcode.app/...  # ← Wrong path!
```

## Next Steps After Fix

Once the iOS build succeeds:

1. **Generate Swift bindings**:
   ```bash
   ./generate-swift.sh
   ```

2. **Create XCFramework**:
   ```bash
   ./create-xcframework.sh
   ```

3. **Use in Xcode**:
   - Drag `Openpano.xcframework` into your Xcode project
   - Import: `import Openpano`
   - Use the Swift API

## Support

### Check Current Xcode
```bash
xcode-select -p
xcrun --show-sdk-path --sdk iphoneos
```

### Check Rust iOS Targets
```bash
rustup target list | grep ios
rustc --print target-list | grep ios
```

### Check Built Libraries
```bash
ls -lh target/aarch64-apple-ios/release/build/openpano-*/out/lib/
```

---

**Issue Date**: November 6, 2025  
**Status**: Ready for user intervention (symlink/xcode-select)  
**Severity**: Blocker for iOS builds only (Android works perfectly!)

