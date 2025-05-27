#!/bin/bash

# OpenPano Android Build Script
# This script builds the OpenPano Android AAR library

set -e

echo "🔨 Building OpenPano Android Library..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$SCRIPT_DIR"

# Check if we're in the correct directory
if [ ! -f "$ANDROID_DIR/settings.gradle" ]; then
    echo "❌ Error: This script must be run from the android directory"
    echo "   Expected to find settings.gradle in current directory"
    exit 1
fi

# Check if Android SDK is available
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    echo "❌ Error: Android SDK not found"
    echo "   Please set ANDROID_HOME or ANDROID_SDK_ROOT environment variable"
    echo "   or install Android Studio with SDK"
    exit 1
fi

# Check if gradlew exists, if not use gradle
GRADLE_CMD="./gradlew"
if [ ! -f "$GRADLE_CMD" ]; then
    GRADLE_CMD="gradle"
    if ! command -v gradle &> /dev/null; then
        echo "❌ Error: Neither gradlew nor gradle found"
        echo "   Please install Gradle or use Android Studio"
        exit 1
    fi
fi

echo "📦 Using Gradle: $GRADLE_CMD"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
$GRADLE_CMD clean

# Build the AAR for all architectures
echo "🏗️  Building AAR for all architectures (arm64-v8a, armeabi-v7a, x86, x86_64)..."
$GRADLE_CMD :openpano-android:assembleRelease

# Check if build was successful
AAR_PATH="$ANDROID_DIR/openpano-android/build/outputs/aar/openpano-android-release.aar"
if [ -f "$AAR_PATH" ]; then
    echo "✅ Build successful!"
    echo "📁 AAR file created at: $AAR_PATH"
    
    # Show file size
    AAR_SIZE=$(ls -lh "$AAR_PATH" | awk '{print $5}')
    echo "📊 AAR file size: $AAR_SIZE"
    
    # Show contained architectures
    echo "🏗️  Checking contained architectures..."
    unzip -l "$AAR_PATH" | grep "jni/" | grep "\.so$" | sed 's/.*jni\//  - /' | sort
    
    echo ""
    echo "🎉 OpenPano Android library build complete!"
    echo ""
    echo "📖 Integration instructions:"
    echo "   1. Copy the AAR file to your Android project's 'libs' directory"
    echo "   2. Add 'implementation fileTree(dir: 'libs', include: ['*.aar'])' to your build.gradle"
    echo "   3. See android/README.md for detailed integration guide"
    
else
    echo "❌ Build failed - AAR file not found"
    echo "   Expected at: $AAR_PATH"
    exit 1
fi
