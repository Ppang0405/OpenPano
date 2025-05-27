#!/bin/bash

# OpenPano Android Validation Script
# This script validates the Android build setup

set -e

echo "🔍 OpenPano Android Build Validation"
echo "===================================="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$SCRIPT_DIR"
OPENPANO_ROOT="$(dirname "$ANDROID_DIR")"

echo "📁 Project directories:"
echo "   Android dir: $ANDROID_DIR"
echo "   OpenPano root: $OPENPANO_ROOT"

# Check directory structure
echo ""
echo "📂 Checking directory structure..."

REQUIRED_DIRS=(
    "$ANDROID_DIR/openpano-android"
    "$ANDROID_DIR/openpano-android/src/main/cpp"
    "$ANDROID_DIR/openpano-android/src/main/java/com/openpano/lib"
    "$OPENPANO_ROOT/src/feature"
    "$OPENPANO_ROOT/src/stitch"
    "$OPENPANO_ROOT/src/lib"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "   ✅ $dir"
    else
        echo "   ❌ $dir (missing)"
        exit 1
    fi
done

# Check required files
echo ""
echo "📄 Checking required files..."

REQUIRED_FILES=(
    "$ANDROID_DIR/build.gradle"
    "$ANDROID_DIR/settings.gradle"
    "$ANDROID_DIR/openpano-android/build.gradle"
    "$ANDROID_DIR/openpano-android/src/main/cpp/CMakeLists.txt"
    "$ANDROID_DIR/openpano-android/src/main/cpp/android_wrapper.cpp"
    "$ANDROID_DIR/openpano-android/src/main/java/com/openpano/lib/OpenPano.java"
    "$ANDROID_DIR/openpano-android/src/main/java/com/openpano/lib/StitchResult.java"
    "$OPENPANO_ROOT/src/feature/sift.cc"
    "$OPENPANO_ROOT/src/stitch/stitcher.cc"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $(basename "$file")"
    else
        echo "   ❌ $(basename "$file") (missing: $file)"
        exit 1
    fi
done

# Check OpenPano source files
echo ""
echo "🔧 Checking OpenPano source files..."

FEATURE_FILES=("$OPENPANO_ROOT/src/feature"/*.cc)
STITCH_FILES=("$OPENPANO_ROOT/src/stitch"/*.cc)
LIB_FILES=("$OPENPANO_ROOT/src/lib"/*.cc)

echo "   Feature files: ${#FEATURE_FILES[@]}"
echo "   Stitch files: ${#STITCH_FILES[@]}"
echo "   Library files: ${#LIB_FILES[@]}"

if [ ${#FEATURE_FILES[@]} -lt 5 ] || [ ${#STITCH_FILES[@]} -lt 10 ] || [ ${#LIB_FILES[@]} -lt 5 ]; then
    echo "   ⚠️  Warning: Some source files may be missing"
else
    echo "   ✅ Source files look complete"
fi

# Check Android SDK
echo ""
echo "📱 Checking Android SDK..."

if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
    echo "   ✅ ANDROID_HOME: $ANDROID_HOME"
else
    echo "   ❌ ANDROID_HOME not set or invalid"
    echo "      Set with: export ANDROID_HOME=/path/to/Android/sdk"
fi

if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME/ndk" ]; then
    NDK_VERSIONS=$(ls "$ANDROID_HOME/ndk" 2>/dev/null || echo "none")
    echo "   NDK versions: $NDK_VERSIONS"
    if [[ "$NDK_VERSIONS" == *"27.1"* ]]; then
        echo "   ✅ Compatible NDK version found"
    else
        echo "   ⚠️  Warning: NDK 27.1+ recommended"
    fi
else
    echo "   ❌ NDK not found"
fi

# Check build tools
echo ""
echo "🛠️  Checking build tools..."

if command -v cmake &> /dev/null; then
    CMAKE_VERSION=$(cmake --version | head -n1)
    echo "   ✅ $CMAKE_VERSION"
else
    echo "   ❌ CMake not found"
fi

if command -v gradle &> /dev/null; then
    GRADLE_VERSION=$(gradle --version | grep "Gradle" | head -n1)
    echo "   ✅ $GRADLE_VERSION"
elif [ -f "$ANDROID_DIR/gradlew" ]; then
    echo "   ✅ Gradle wrapper available"
else
    echo "   ❌ Neither gradle nor gradlew found"
fi

# Check path resolution from CMakeLists.txt location
echo ""
echo "🧭 Checking path resolution..."

CMAKE_DIR="$ANDROID_DIR/openpano-android/src/main/cpp"
RELATIVE_SRC="$CMAKE_DIR/../../../../../src"

if [ -d "$RELATIVE_SRC/feature" ]; then
    echo "   ✅ CMakeLists.txt can find OpenPano sources"
else
    echo "   ❌ CMakeLists.txt path resolution failed"
    echo "      From: $CMAKE_DIR"
    echo "      Looking for: $RELATIVE_SRC/feature"
fi

echo ""
echo "📋 Validation Summary:"
echo "====================="

# Count issues
ISSUES=0

if [ ! -n "$ANDROID_HOME" ] || [ ! -d "$ANDROID_HOME" ]; then
    echo "❌ Android SDK not found"
    ((ISSUES++))
fi

if ! command -v cmake &> /dev/null; then
    echo "❌ CMake not available"
    ((ISSUES++))
fi

if ! command -v gradle &> /dev/null && [ ! -f "$ANDROID_DIR/gradlew" ]; then
    echo "❌ Gradle not available"
    ((ISSUES++))
fi

if [ ! -d "$RELATIVE_SRC/feature" ]; then
    echo "❌ Path resolution issue"
    ((ISSUES++))
fi

if [ $ISSUES -eq 0 ]; then
    echo "✅ All checks passed! Ready to build AAR."
    echo ""
    echo "Next steps:"
    echo "1. cd android"
    echo "2. export ANDROID_HOME=/path/to/Android/sdk"
    echo "3. ./build_aar.sh"
else
    echo "⚠️  Found $ISSUES issue(s) that need to be resolved."
    echo ""
    echo "Setup instructions:"
    echo "1. Install Android Studio with SDK and NDK"
    echo "2. Set ANDROID_HOME environment variable"
    echo "3. Install CMake and Gradle"
    echo "4. Run this script again to validate"
fi

echo ""
echo "📖 For detailed instructions, see:"
echo "   - android/BUILD_INSTRUCTIONS.md"
echo "   - android/README.md"
