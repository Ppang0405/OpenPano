#!/bin/bash

# OpenPano Android AAR Build Script
# This script builds the OpenPano Android library as an AAR file

set -e

echo "🚀 Building OpenPano Android AAR Library..."

# Check if we're in the correct directory
if [ ! -f "build.gradle" ]; then
    echo "❌ Error: Please run this script from the openpano-android directory"
    exit 1
fi

# Check if gradlew exists
if [ ! -f "gradlew" ]; then
    echo "❌ Error: gradlew not found. Please ensure Gradle wrapper is set up."
    exit 1
fi

# Make gradlew executable
chmod +x gradlew

echo "📋 Project Configuration:"
echo "  - Building AAR library for OpenPano Android"
echo "  - Target architectures: arm64-v8a, armeabi-v7a, x86_64, x86"
echo "  - Output: AAR file for distribution"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
./gradlew clean

# Sync project (equivalent to "Sync Project with Gradle Files" in Android Studio)
echo "🔄 Syncing project dependencies..."

# Build the AAR
echo "🔨 Building AAR library..."
echo "This may take several minutes depending on your system..."

# Build release AAR
./gradlew assembleRelease

# Also build debug AAR
echo "🔨 Building debug AAR..."
./gradlew assembleDebug

# Check if AAR files were created
AAR_DIR="app/build/outputs/aar"
if [ -d "$AAR_DIR" ]; then
    echo ""
    echo "✅ Build completed successfully!"
    echo ""
    echo "📦 Generated AAR files:"
    ls -la "$AAR_DIR"/*.aar
    echo ""
    echo "📍 Location: $(pwd)/$AAR_DIR/"
    echo ""
    echo "🎯 Next steps:"
    echo "  1. The AAR files are ready for distribution"
    echo "  2. Import the AAR into your Android project"
    echo "  3. Add dependencies in your app's build.gradle"
    echo "  4. Use the OpenPano.* APIs in your Java/Kotlin code"
    echo ""
    echo "📚 Integration example:"
    echo "  // In your app's build.gradle:"
    echo "  implementation files('libs/app-release.aar')"
    echo ""
    echo "  // In your Java code:"
    echo "  import com.openpano.lib.OpenPano;"
    echo "  import com.openpano.lib.StitchResult;"
    echo "  StitchResult result = OpenPano.stitchImages(imagePaths, outputPath);"
    echo ""
else
    echo "❌ Error: AAR files not found. Build may have failed."
    echo "Check the build output above for errors."
    exit 1
fi

# Optional: Create a distribution package
echo "📦 Creating distribution package..."
DIST_DIR="dist"
mkdir -p "$DIST_DIR"

# Copy AAR files
cp "$AAR_DIR"/*.aar "$DIST_DIR/"

# Copy documentation
cp README.md "$DIST_DIR/"
cp ANDROID_PORT_SUMMARY.md "$DIST_DIR/" 2>/dev/null || true

# Create integration guide
cat > "$DIST_DIR/INTEGRATION_GUIDE.md" << 'EOF'
# OpenPano Android AAR Integration Guide

## Quick Start

1. **Add AAR to your project:**
   - Copy the AAR file to your app's `libs/` directory
   - Add to your app's `build.gradle`:
   ```gradle
   dependencies {
       implementation files('libs/app-release.aar')
       implementation 'androidx.annotation:annotation:1.7.0'
   }
   ```

2. **Initialize in your code:**
   ```java
   import com.openpano.lib.OpenPano;
   import com.openpano.lib.StitchResult;
   
   // Initialize library
   if (!OpenPano.initDefaultConfig()) {
       // Handle initialization error
       return;
   }
   
   // Stitch images
   String[] imagePaths = {"/path/to/image1.jpg", "/path/to/image2.jpg"};
   StitchResult result = OpenPano.stitchImages(imagePaths, "/path/to/output.jpg");
   
   if (result.isSuccess()) {
       // Success: result.getWidth(), result.getHeight(), result.getOutputPath()
   } else {
       // Error: result.getErrorMessage()
   }
   ```

3. **Add permissions to AndroidManifest.xml:**
   ```xml
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   ```

## API Reference

See README.md for complete API documentation.

## Performance Tips

- Resize large images before stitching for better performance
- Use background threads for stitching operations
- Cache configuration by calling initDefaultConfig() once

## Troubleshooting

- Ensure proper storage permissions
- Check image paths are accessible
- Monitor memory usage with large images
- Enable debug logging for detailed error information
EOF

echo "📁 Distribution package created in: $(pwd)/$DIST_DIR/"
echo ""
echo "🎉 Build process complete!"
echo "The OpenPano Android library is ready for integration into Android projects."
