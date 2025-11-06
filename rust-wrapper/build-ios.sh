#!/bin/bash
# Build OpenPano for iOS (XCFramework)

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🍎 Building OpenPano for iOS                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Build directory
BUILD_DIR="target/ios"
mkdir -p "$BUILD_DIR"

echo "Building for iOS targets..."
echo ""

# Set Xcode developer directory (handle versioned Xcode installations)
export DEVELOPER_DIR="/Applications/Xcode_16.2.app/Contents/Developer"
if [ ! -d "$DEVELOPER_DIR" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

if [ ! -d "$DEVELOPER_DIR" ]; then
    echo "❌ Error: Xcode not found"
    exit 1
fi

# Set iOS SDK root for linker
export SDKROOT="$DEVELOPER_DIR/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"

echo "✓ Using Xcode at: $DEVELOPER_DIR"
echo "✓ iOS SDK: $SDKROOT"
echo ""

# Build for iOS device (ARM64)
echo "📱 Building for iOS devices (ARM64)..."
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (ARM64 - M1/M2 Macs)
echo "🖥️  Building for iOS Simulator (ARM64)..."
cargo build --release --target aarch64-apple-ios-sim

# Build for iOS simulator (x86_64 - Intel Macs)
echo "🖥️  Building for iOS Simulator (x86_64)..."
cargo build --release --target x86_64-apple-ios

echo ""
echo "📦 Stripping debug symbols..."
for target in "aarch64-apple-ios" "aarch64-apple-ios-sim" "x86_64-apple-ios"; do
    strip -S -x target/$target/release/libopenpano.a 2>/dev/null || true
done

echo "✅ iOS libraries built successfully!"
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ Build Complete!                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Libraries location:"
echo "  • iOS Device:    target/aarch64-apple-ios/release/libopenpano.a"
echo "  • iOS Sim (ARM): target/aarch64-apple-ios-sim/release/libopenpano.a"
echo "  • iOS Sim (x64): target/x86_64-apple-ios/release/libopenpano.a"
echo ""
echo "Next steps:"
echo "1. Run: ./generate-swift.sh (to generate Swift bindings)"
echo "2. Run: ./create-xcframework.sh (to package XCFramework)"
echo "3. Import the XCFramework into your Xcode project"

