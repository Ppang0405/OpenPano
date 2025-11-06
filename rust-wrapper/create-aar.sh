#!/bin/bash
# Create Android AAR from built libraries

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📦 Creating Android AAR                                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if libraries exist
if [ ! -f "target/aarch64-linux-android/release/libopenpano.so" ]; then
    echo "❌ Error: Libraries not built yet"
    echo "Run ./build-android.sh first"
    exit 1
fi

# AAR structure
AAR_DIR="target/android/aar"
AAR_NAME="openpano"
VERSION="0.1.0"

echo "Creating AAR structure..."
rm -rf "$AAR_DIR"
mkdir -p "$AAR_DIR"/{classes,jni/{arm64-v8a,armeabi-v7a,x86_64}}

# Copy native libraries
echo "📦 Copying native libraries..."
cp target/aarch64-linux-android/release/libopenpano.so "$AAR_DIR/jni/arm64-v8a/"
cp target/armv7-linux-androideabi/release/libopenpano.so "$AAR_DIR/jni/armeabi-v7a/"
cp target/x86_64-linux-android/release/libopenpano.so "$AAR_DIR/jni/x86_64/"

# Copy Kotlin bindings
echo "📝 Copying Kotlin bindings..."
KOTLIN_DIR="target/android/kotlin"
if [ -d "$KOTLIN_DIR" ]; then
    mkdir -p "$AAR_DIR/classes/com/openpano"
    cp -r "$KOTLIN_DIR"/* "$AAR_DIR/classes/com/openpano/" 2>/dev/null || true
fi

# Create AndroidManifest.xml
echo "📝 Creating AndroidManifest.xml..."
cat > "$AAR_DIR/AndroidManifest.xml" << 'MANIFEST'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.openpano"
    android:versionCode="1"
    android:versionName="0.1.0">
    
    <uses-sdk 
        android:minSdkVersion="21"
        android:targetSdkVersion="34" />
</manifest>
MANIFEST

# Create empty classes.jar (using zip instead of jar command)
echo "📦 Creating classes.jar..."
cd "$AAR_DIR/classes" && zip -q ../classes.jar META-INF/MANIFEST.MF 2>/dev/null || touch ../classes.jar && cd - >/dev/null

# Create R.txt
mkdir -p "$AAR_DIR"
touch "$AAR_DIR/R.txt"

# Create proguard.txt
cat > "$AAR_DIR/proguard.txt" << 'PROGUARD'
# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep OpenPano classes
-keep class com.openpano.** { *; }
PROGUARD

# Package into AAR
echo "📦 Packaging AAR..."
cd "$AAR_DIR"
OUTPUT="../${AAR_NAME}-${VERSION}.aar"
zip -r "$OUTPUT" AndroidManifest.xml classes.jar jni/ R.txt proguard.txt >/dev/null
cd - >/dev/null

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ AAR Created Successfully!                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "AAR location: target/android/${AAR_NAME}-${VERSION}.aar"
echo "Size: $(du -h target/android/${AAR_NAME}-${VERSION}.aar | cut -f1)"
echo ""
echo "To use in your Android project:"
echo "1. Copy the AAR to your app/libs/ directory"
echo "2. Add to build.gradle:"
echo "   implementation files('libs/${AAR_NAME}-${VERSION}.aar')"
echo "3. Import: import com.openpano.*"

