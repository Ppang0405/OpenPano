#!/bin/bash
# Create iOS XCFramework from built libraries

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🍎 Creating iOS XCFramework                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if libraries exist
if [ ! -f "target/aarch64-apple-ios/release/libopenpano.a" ]; then
    echo "❌ Error: Libraries not built yet"
    echo "Run ./build-ios.sh first"
    exit 1
fi

FRAMEWORK_NAME="OpenPano"
BUILD_DIR="target/ios"
XCF_DIR="$BUILD_DIR/xcframework"

echo "Creating XCFramework structure..."
rm -rf "$XCF_DIR"
mkdir -p "$XCF_DIR"

# Create fat library for iOS Simulator (combine ARM64 and x86_64)
echo "🔨 Creating universal simulator library..."
lipo -create \
    target/aarch64-apple-ios-sim/release/libopenpano.a \
    target/x86_64-apple-ios/release/libopenpano.a \
    -output "$BUILD_DIR/libopenpano-sim.a"

# Create framework structure for iOS device
echo "📦 Creating iOS device framework..."
IOS_FRAMEWORK="$BUILD_DIR/ios-arm64/$FRAMEWORK_NAME.framework"
mkdir -p "$IOS_FRAMEWORK/Headers"
mkdir -p "$IOS_FRAMEWORK/Modules"

cp target/aarch64-apple-ios/release/libopenpano.a "$IOS_FRAMEWORK/$FRAMEWORK_NAME"
cp "$BUILD_DIR/swift/openpanoFFI.h" "$IOS_FRAMEWORK/Headers/" 2>/dev/null || touch "$IOS_FRAMEWORK/Headers/$FRAMEWORK_NAME.h"
cp "$BUILD_DIR/swift/module.modulemap" "$IOS_FRAMEWORK/Modules/" 2>/dev/null || true

# Create Info.plist for device
cat > "$IOS_FRAMEWORK/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.openpano.$FRAMEWORK_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
PLIST

# Create framework structure for iOS Simulator
echo "📦 Creating iOS simulator framework..."
SIM_FRAMEWORK="$BUILD_DIR/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework"
mkdir -p "$SIM_FRAMEWORK/Headers"
mkdir -p "$SIM_FRAMEWORK/Modules"

cp "$BUILD_DIR/libopenpano-sim.a" "$SIM_FRAMEWORK/$FRAMEWORK_NAME"
cp "$BUILD_DIR/swift/openpanoFFI.h" "$SIM_FRAMEWORK/Headers/" 2>/dev/null || touch "$SIM_FRAMEWORK/Headers/$FRAMEWORK_NAME.h"
cp "$BUILD_DIR/swift/module.modulemap" "$SIM_FRAMEWORK/Modules/" 2>/dev/null || true
cp "$IOS_FRAMEWORK/Info.plist" "$SIM_FRAMEWORK/"

# Create XCFramework
echo "🔨 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$IOS_FRAMEWORK" \
    -framework "$SIM_FRAMEWORK" \
    -output "$XCF_DIR/$FRAMEWORK_NAME.xcframework"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ XCFramework Created Successfully!                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "XCFramework location: $XCF_DIR/$FRAMEWORK_NAME.xcframework"
echo "Size: $(du -sh "$XCF_DIR/$FRAMEWORK_NAME.xcframework" | cut -f1)"
echo ""
echo "Swift bindings: $BUILD_DIR/swift/"
echo ""
echo "To use in your iOS project:"
echo "1. Drag $FRAMEWORK_NAME.xcframework into your Xcode project"
echo "2. Copy Swift files from $BUILD_DIR/swift/ to your project"
echo "3. Import: import $FRAMEWORK_NAME"

