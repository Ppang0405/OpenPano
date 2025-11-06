#!/bin/bash
# Build OpenPano for Android (AAR)

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🤖 Building OpenPano for Android                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check for Android NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "❌ Error: ANDROID_NDK_HOME is not set"
    echo "Please set ANDROID_NDK_HOME to your Android NDK installation"
    echo "Example: export ANDROID_NDK_HOME=\$HOME/Library/Android/sdk/ndk/26.1.10909125"
    exit 1
fi

echo "✓ Android NDK found at: $ANDROID_NDK_HOME"
echo ""

# Detect host architecture for NDK toolchain
if [ "$(uname -m)" = "arm64" ]; then
    NDK_HOST="darwin-aarch64"
    # Fallback to x86_64 if aarch64 doesn't exist
    if [ ! -d "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$NDK_HOST" ]; then
        NDK_HOST="darwin-x86_64"
    fi
else
    NDK_HOST="darwin-x86_64"
fi

# Add NDK toolchain to PATH
export PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$NDK_HOST/bin:$PATH"
echo "✓ Using NDK toolchain: $NDK_HOST"

# Build directory
BUILD_DIR="target/android"
mkdir -p "$BUILD_DIR"

# Android API level
API_LEVEL=21

echo "Building for Android targets (API $API_LEVEL)..."
echo ""

# Build for each Android architecture
echo "📱 Building for arm64-v8a..."
cargo ndk --target arm64-v8a --platform $API_LEVEL build --release

echo "📱 Building for armeabi-v7a..."
cargo ndk --target armeabi-v7a --platform $API_LEVEL build --release

echo "📱 Building for x86_64..."
cargo ndk --target x86_64 --platform $API_LEVEL build --release

echo ""
echo "✅ Android libraries built successfully!"
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ Build Complete!                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Libraries location:"
echo "  • arm64-v8a:     target/aarch64-linux-android/release/libopenpano.so"
echo "  • armeabi-v7a:   target/armv7-linux-androideabi/release/libopenpano.so"
echo "  • x86_64:        target/x86_64-linux-android/release/libopenpano.so"
echo ""
echo "Next steps:"
echo "1. Run: ./generate-kotlin.sh (to generate Kotlin bindings)"
echo "2. Run: ./create-aar.sh (to package AAR)"
echo "3. Import the AAR into your Android project"

