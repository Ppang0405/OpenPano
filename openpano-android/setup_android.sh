#!/bin/bash

# OpenPano Android Setup Script
# This script helps set up the Android development environment

echo "Setting up OpenPano Android project..."

# Check if we're in the correct directory
if [ ! -f "build.gradle" ]; then
    echo "Error: Please run this script from the openpano-android directory"
    exit 1
fi

# Check for Android Studio project structure
if [ ! -d "app" ]; then
    echo "Error: Android project structure not found"
    exit 1
fi

echo "✓ Android project structure found"

# Check if we have the required source files
if [ ! -d "../src" ]; then
    echo "Error: OpenPano source directory not found at ../src"
    echo "Please ensure this script is run from openpano-android/ and that src/ exists in the parent directory"
    exit 1
fi

echo "✓ OpenPano source directory found"

# Create symbolic links to source files if they don't exist
echo "Creating source file links..."

# Link the src directory
if [ ! -L "app/src/main/cpp/src" ]; then
    ln -s "../../../src" "app/src/main/cpp/src"
    echo "✓ Linked source directory"
fi

# Link the third-party directory
if [ ! -L "app/src/main/cpp/third-party" ]; then
    ln -s "../../../third-party" "app/src/main/cpp/third-party"
    echo "✓ Linked third-party directory"
fi

# Check for Android SDK
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    echo "Warning: ANDROID_HOME or ANDROID_SDK_ROOT environment variable not set"
    echo "Please set up your Android SDK path"
else
    echo "✓ Android SDK found at ${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
fi

# Check for NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "Warning: ANDROID_NDK_HOME environment variable not set"
    echo "Please set up your Android NDK path"
else
    echo "✓ Android NDK found at $ANDROID_NDK_HOME"
fi

# Create local.properties file if it doesn't exist
if [ ! -f "local.properties" ]; then
    echo "Creating local.properties file..."
    if [ -n "$ANDROID_HOME" ]; then
        echo "sdk.dir=$ANDROID_HOME" > local.properties
    elif [ -n "$ANDROID_SDK_ROOT" ]; then
        echo "sdk.dir=$ANDROID_SDK_ROOT" > local.properties
    fi
    
    if [ -n "$ANDROID_NDK_HOME" ]; then
        echo "ndk.dir=$ANDROID_NDK_HOME" >> local.properties
    fi
    
    echo "✓ Created local.properties"
fi

# Set executable permissions
chmod +x setup_android.sh

echo ""
echo "Setup complete! Next steps:"
echo "1. Open this project in Android Studio"
echo "2. Click 'Sync Project with Gradle Files'"
echo "3. Build the project (Build -> Make Project)"
echo "4. Run on device or emulator"
echo ""
echo "For troubleshooting, see README.md"
