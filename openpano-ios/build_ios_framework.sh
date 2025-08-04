#!/bin/bash

# OpenPano iOS XCFramework Builder
# This script actually builds OpenPano C++ code into a working iOS XCFramework

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="OpenPanoFramework"
BUILD_DIR="$SCRIPT_DIR/build"
XCFRAMEWORK_PATH="$BUILD_DIR/$PROJECT_NAME.xcframework"

echo "🚀 Building OpenPano iOS XCFramework..."

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Check required sources
if [ ! -d "$SCRIPT_DIR/openpano-src" ]; then
    echo "❌ Error: openpano-src not found"
    exit 1
fi

if [ ! -d "$SCRIPT_DIR/eigen" ]; then
    echo "❌ Error: eigen not found"
    exit 1
fi

echo "✅ Sources verified"

# Use the proper Objective-C++ wrapper files
WRAPPER_SOURCE="$SCRIPT_DIR/OpenPanoWrapper.mm"
WRAPPER_HEADER="$SCRIPT_DIR/OpenPanoWrapper.h"

if [ ! -f "$WRAPPER_SOURCE" ] || [ ! -f "$WRAPPER_HEADER" ]; then
    echo "❌ Error: OpenPanoWrapper files not found"
    exit 1
fi

# Function to build framework for specific platform
build_framework() {
    local PLATFORM=$1
    local SDK=$2
    local ARCH=$3
    local OUTPUT_DIR="$BUILD_DIR/$PLATFORM"
    local FRAMEWORK_DIR="$OUTPUT_DIR/$PROJECT_NAME.framework"
    
    echo "📱 Building for $PLATFORM ($ARCH)..."
    
    mkdir -p "$FRAMEWORK_DIR/Headers"
    
    # Create main header by copying from our wrapper
    cp "$WRAPPER_HEADER" "$FRAMEWORK_DIR/Headers/$PROJECT_NAME.h"

    # Create Info.plist
    cat > "$FRAMEWORK_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.openpano.framework</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
</dict>
</plist>
EOF

    # Compile the framework binary
    echo "🔨 Compiling binary for $PLATFORM..."
    
    # Set deployment target based on platform
    if [[ "$PLATFORM" == *"simulator"* ]]; then
        DEPLOYMENT_FLAG="-mios-simulator-version-min=12.0"
    else
        DEPLOYMENT_FLAG="-mios-version-min=12.0"
    fi
    
    # Collect OpenPano source files (handling CImg.h issues)
    OPENPANO_SOURCES=""
    if [ -d "$SCRIPT_DIR/openpano-src" ]; then
        # Add feature detection sources
        OPENPANO_SOURCES="$OPENPANO_SOURCES $SCRIPT_DIR/openpano-src/feature/*.cc"
        # Add stitching algorithm sources  
        OPENPANO_SOURCES="$OPENPANO_SOURCES $SCRIPT_DIR/openpano-src/stitch/*.cc"
        # Add library utilities (we need these for the symbols)
        OPENPANO_SOURCES="$OPENPANO_SOURCES $SCRIPT_DIR/openpano-src/lib/*.cc"
        # Add third-party dependencies
        OPENPANO_SOURCES="$OPENPANO_SOURCES $SCRIPT_DIR/openpano-src/third-party/lodepng/*.cc"
        echo "📋 Including OpenPano C++ sources..."
    else
        echo "⚠️  OpenPano sources not found, building framework shell only"
    fi
    
    clang++ -dynamiclib \
        -std=c++11 \
        -O3 \
        -arch $ARCH \
        -isysroot $(xcrun --sdk $SDK --show-sdk-path) \
        $DEPLOYMENT_FLAG \
        -framework Foundation \
        -framework UIKit \
        -framework CoreGraphics \
        -framework Accelerate \
        -fvisibility=hidden \
        -install_name "@rpath/$PROJECT_NAME.framework/$PROJECT_NAME" \
        -include "$SCRIPT_DIR/cimg_ios_config.h" \
        -I"$SCRIPT_DIR" \
        -I"$SCRIPT_DIR/openpano-src" \
        -I"$SCRIPT_DIR/openpano-src/third-party" \
        -I"$SCRIPT_DIR/eigen" \
        -DIOS -DDISABLE_JPEG=1 -D__IOS__ \
        -DEIGEN_STACK_ALLOCATION_LIMIT=0 -DEIGEN_DONT_ALIGN_STATICALLY=1 \
        -DEIGEN_ALLOCA=malloc \
        -D_POSIX_C_SOURCE=200809L \
        -Wno-unused-parameter -Wno-unused-variable -Wno-deprecated-declarations \
        "$WRAPPER_SOURCE" \
        $OPENPANO_SOURCES \
        -o "$FRAMEWORK_DIR/$PROJECT_NAME"
    
    if [ ! -f "$FRAMEWORK_DIR/$PROJECT_NAME" ]; then
        echo "❌ Failed to compile binary for $PLATFORM"
        return 1
    fi
    
    echo "✅ Successfully built framework for $PLATFORM"
}

# Build for iOS device
build_framework "ios-device" "iphoneos" "arm64"

# Build for iOS simulator  
build_framework "ios-simulator" "iphonesimulator" "arm64"

# Create XCFramework
echo "🔨 Creating XCFramework..."

xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/ios-device/$PROJECT_NAME.framework" \
    -framework "$BUILD_DIR/ios-simulator/$PROJECT_NAME.framework" \
    -output "$XCFRAMEWORK_PATH"

if [ -d "$XCFRAMEWORK_PATH" ]; then
    echo "✅ XCFramework created successfully!"
    echo "📦 Location: $XCFRAMEWORK_PATH"
    echo "📊 Size: $(du -sh "$XCFRAMEWORK_PATH" | cut -f1)"
    
    echo ""
    echo "📋 Contents:"
    find "$XCFRAMEWORK_PATH" -name "*.framework" | sed 's/^/  /'
    
    echo ""
    echo "🎯 Integration: Drag $PROJECT_NAME.xcframework into your Xcode project"
else
    echo "❌ Failed to create XCFramework"
    exit 1
fi

echo ""
echo "🎉 OpenPano iOS XCFramework build complete!"
