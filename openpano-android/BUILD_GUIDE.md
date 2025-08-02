# OpenPano Android AAR Build Guide

## Overview

This guide explains how to build the OpenPano Android library as an AAR (Android Archive) file that can be integrated into Android applications.

## Prerequisites

Before building, ensure you have:

1. **Android Studio** 4.2 or later
2. **Android SDK** API level 21 or later  
3. **Android NDK** 21.0.6113669 or later
4. **CMake** 3.22.1 or later
5. **Java** 8 or later

## Environment Setup

### 1. Set Environment Variables

```bash
export ANDROID_HOME=/path/to/android/sdk
export ANDROID_NDK_HOME=/path/to/android/ndk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### 2. Verify NDK Installation

```bash
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/
```

## Building the AAR

### Method 1: Using the Build Script (Recommended)

```bash
cd openpano-android
./build_aar.sh
```

The script will:
- Clean previous builds
- Sync dependencies
- Build release and debug AAR files
- Create a distribution package
- Provide integration instructions

### Method 2: Manual Build with Gradle

```bash
cd openpano-android

# Make gradlew executable
chmod +x gradlew

# Clean previous builds
./gradlew clean

# Build release AAR
./gradlew assembleRelease

# Build debug AAR (optional)
./gradlew assembleDebug
```

### Method 3: Using Android Studio

1. Open the `openpano-android` project in Android Studio
2. Click "Sync Project with Gradle Files"
3. Select "Build" → "Make Project" from the menu
4. Or run from terminal: `./gradlew assembleRelease`

## Output Files

After successful build, you'll find the AAR files at:

```
app/build/outputs/aar/
├── app-debug.aar     # Debug version
└── app-release.aar   # Release version (recommended for production)
```

## Build Configuration

### Supported Architectures

The AAR includes native libraries for:
- `arm64-v8a` (64-bit ARM)
- `armeabi-v7a` (32-bit ARM)
- `x86_64` (64-bit x86)
- `x86` (32-bit x86)

### Build Variants

- **Release**: Optimized for production use
- **Debug**: Includes debug symbols for development

### Library Information

- **Group ID**: `com.openpano`
- **Artifact ID**: `openpano-android`
- **Version**: `1.0.0`

## Integration into Android Projects

### 1. Add AAR to Your Project

Copy the AAR file to your app's `libs/` directory:

```bash
mkdir -p YourApp/app/libs/
cp app/build/outputs/aar/app-release.aar YourApp/app/libs/
```

### 2. Update build.gradle

Add to your app's `build.gradle`:

```gradle
android {
    // ... existing configuration

    // Enable local AAR files
    repositories {
        flatDir {
            dirs 'libs'
        }
    }
}

dependencies {
    // Add the OpenPano AAR
    implementation files('libs/app-release.aar')
    
    // Required dependency
    implementation 'androidx.annotation:annotation:1.7.0'
    
    // ... other dependencies
}
```

### 3. Add Permissions

Add to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 4. Use in Code

```java
import com.openpano.lib.OpenPano;
import com.openpano.lib.StitchResult;

// Initialize library
OpenPano.initDefaultConfig();

// Stitch images
String[] imagePaths = {"/path/to/image1.jpg", "/path/to/image2.jpg"};
StitchResult result = OpenPano.stitchImages(imagePaths, "/path/to/output.jpg");

if (result.isSuccess()) {
    // Success handling
    int width = result.getWidth();
    int height = result.getHeight();
    String outputPath = result.getOutputPath();
} else {
    // Error handling
    String error = result.getErrorMessage();
}
```

## Troubleshooting

### Common Build Issues

#### 1. NDK Not Found
```
Error: NDK not configured
```
**Solution**: Set `ANDROID_NDK_HOME` environment variable or configure in `local.properties`:
```properties
ndk.dir=/path/to/android/ndk
```

#### 2. CMake Not Found
```
Error: CMake not found
```
**Solution**: Install CMake via Android Studio SDK Manager or set path in `local.properties`:
```properties
cmake.dir=/path/to/cmake
```

#### 3. Build Tools Version
```
Error: Build Tools revision X.X.X is corrupted
```
**Solution**: Update Android SDK Build Tools via SDK Manager

#### 4. OpenMP Linking Issues
If you encounter OpenMP linking errors, check that your NDK version supports OpenMP or disable it in CMakeLists.txt.

### Build Verification

To verify the AAR contains native libraries:

```bash
# Extract and inspect AAR contents
unzip -l app/build/outputs/aar/app-release.aar

# Should contain:
# - jni/arm64-v8a/libopenpano-android.so
# - jni/armeabi-v7a/libopenpano-android.so
# - jni/x86_64/libopenpano-android.so
# - jni/x86/libopenpano-android.so
# - classes.jar
# - AndroidManifest.xml
```

### Performance Testing

Test the AAR with sample images:

```java
// Performance test
long startTime = System.currentTimeMillis();
StitchResult result = OpenPano.stitchImages(imagePaths, outputPath);
long duration = System.currentTimeMillis() - startTime;
Log.i("OpenPano", "Stitching took: " + duration + "ms");
```

## Advanced Configuration

### Custom Build Options

Modify `app/build.gradle` for custom builds:

```gradle
android {
    defaultConfig {
        // Custom native build arguments
        externalNativeBuild {
            cmake {
                arguments "-DCUSTOM_OPTION=ON"
                cppFlags "-DCUSTOM_DEFINE"
            }
        }
        
        // Specific ABI builds
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a'  // Build only ARM
        }
    }
}
```

### Publishing to Repository

To publish the AAR to a Maven repository:

```bash
./gradlew publishReleasePublicationToMavenLocal
```

## Distribution

The build script creates a `dist/` directory containing:
- AAR files (release and debug)
- Documentation (README.md)
- Integration guide
- Sample code

This package can be distributed to other developers for easy integration.

## Continuous Integration

For CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
name: Build AAR
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Set up JDK
      uses: actions/setup-java@v2
      with:
        java-version: '11'
    - name: Build AAR
      run: |
        cd openpano-android
        chmod +x gradlew
        ./gradlew assembleRelease
    - name: Upload AAR
      uses: actions/upload-artifact@v2
      with:
        name: openpano-android-aar
        path: openpano-android/app/build/outputs/aar/
```
