# OpenPano Android Build Instructions

## Quick Start

Follow these steps to build the OpenPano Android AAR library:

### Prerequisites

1. **Install Android Studio** with NDK support
2. **Install Android NDK** version 27.1.12297006 or later
3. **Install CMake** 3.22.1 or later (available through Android Studio SDK Manager)
4. **Set Android SDK environment variables:**
   ```bash
   export ANDROID_HOME=/path/to/Android/sdk
   export ANDROID_SDK_ROOT=$ANDROID_HOME
   ```

### Build Commands

```bash
# Navigate to the android directory
cd android

# Build the AAR (automated script)
./build_aar.sh

# Or manually using Gradle
./gradlew :openpano-android:assembleRelease
```

### Output

The build will generate:
- **AAR file:** `android/openpano-android/build/outputs/aar/openpano-android-release.aar`
- **Native libraries for all architectures:**
  - arm64-v8a (64-bit ARM)
  - armeabi-v7a (32-bit ARM) 
  - x86 (32-bit Intel)
  - x86_64 (64-bit Intel)

## Architecture Support

The Android build supports all major Android architectures:

| Architecture | Target Devices | Description |
|-------------|----------------|-------------|
| **arm64-v8a** | Modern Android phones/tablets | 64-bit ARM (recommended) |
| **armeabi-v7a** | Older Android devices | 32-bit ARM |
| **x86** | Android emulators | 32-bit Intel |
| **x86_64** | Intel tablets, emulators | 64-bit Intel |

## Integration into Your Android Project

### 1. Copy AAR to Your Project

```bash
cp android/openpano-android/build/outputs/aar/openpano-android-release.aar /path/to/your/project/app/libs/
```

### 2. Update Your build.gradle

```gradle
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.aar'])
    // ... other dependencies
}

android {
    packagingOptions {
        pickFirst '**/libc++_shared.so'
        pickFirst '**/libjsc.so'
    }
}
```

### 3. Add Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 4. Basic Usage Example

```java
import com.openpano.lib.OpenPano;
import com.openpano.lib.StitchResult;

// Initialize
OpenPano.initConfig(null); // Use default config

// Stitch images
String[] imagePaths = {"/path/to/image1.jpg", "/path/to/image2.jpg"};
String outputPath = "/path/to/output.jpg";
StitchResult result = OpenPano.stitchImages(imagePaths, outputPath);

if (result.isSuccess()) {
    Log.i("OpenPano", "Success: " + result.getWidth() + "x" + result.getHeight());
} else {
    Log.e("OpenPano", "Failed: " + result.getMessage());
}
```

## Build Configuration Details

### CMake Configuration

The Android build uses the following key settings:

```cmake
# C++ Standard
set(CMAKE_CXX_STANDARD 11)

# Android Flags
-DANDROID -DUSE_JPEG=0 -frtti -fexceptions

# Libraries
android, log, jnigraphics, m, pthread
```

### Native Dependencies

- **No JPEG dependency** - Uses lodepng for image I/O
- **STL:** c++_shared (shared C++ standard library)
- **Threading:** pthread support enabled
- **Logging:** Android log system integration

## Troubleshooting

### Common Build Issues

1. **NDK not found:**
   ```
   Solution: Install NDK via Android Studio SDK Manager
   Verify: $ANDROID_HOME/ndk/{version} exists
   ```

2. **CMake not found:**
   ```
   Solution: Install CMake via SDK Manager
   Verify: Android Studio > SDK Manager > SDK Tools > CMake
   ```

3. **Source files not found:**
   ```
   Solution: Ensure you're building from the correct directory
   Verify: The android/ directory is in the OpenPano root
   ```

4. **Library loading fails:**
   ```
   Solution: Check ABI filtering in build.gradle
   Verify: Target device architecture is included in build
   ```

### Build Verification

After building, verify the AAR contains all architectures:

```bash
unzip -l openpano-android-release.aar | grep "\.so$"
```

Expected output:
```
jni/arm64-v8a/libopenpano-android.so
jni/armeabi-v7a/libopenpano-android.so  
jni/x86/libopenpano-android.so
jni/x86_64/libopenpano-android.so
```

### Runtime Verification

Test library loading in your Android app:

```java
if (OpenPano.isLibraryReady()) {
    String version = OpenPano.getVersion();
    String systemInfo = OpenPano.getSystemInfo();
    Log.i("OpenPano", "Library ready: " + version);
} else {
    Log.e("OpenPano", "Library failed to load");
}
```

## Performance Optimization

### Image Size Recommendations

- **Input images:** Resize to 1000-2000px width for optimal performance
- **Memory usage:** ~100-200MB for typical panorama stitching
- **Processing time:** 5-15 seconds for 2-4 images on modern devices

### Threading Best Practices

```java
// Always run stitching on background thread
ExecutorService executor = Executors.newSingleThreadExecutor();
executor.execute(() -> {
    StitchResult result = OpenPano.stitchImages(imagePaths, outputPath);
    // Handle result on main thread
    runOnUiThread(() -> updateUI(result));
});
```

## Sample App

A complete sample Android application is included in `android/sample-app/`. 

To build and run:

```bash
# Include sample app in build
./gradlew :sample-app:assembleDebug

# Install on connected device
adb install sample-app/build/outputs/apk/debug/sample-app-debug.apk
```

## File Structure

```
android/
├── build_aar.sh                 # Automated build script
├── gradlew                      # Gradle wrapper
├── build.gradle                 # Root build configuration
├── settings.gradle              # Project settings
├── gradle.properties            # Gradle properties
├── README.md                    # This file
├── openpano-android/            # Main library module
│   ├── build.gradle            # Library build config
│   ├── src/main/
│   │   ├── AndroidManifest.xml # Library manifest
│   │   ├── java/com/openpano/lib/
│   │   │   ├── OpenPano.java   # Main API class
│   │   │   └── StitchResult.java # Result class
│   │   └── cpp/
│   │       ├── CMakeLists.txt  # Native build config
│   │       └── android_wrapper.cpp # JNI wrapper
│   └── proguard-rules.pro      # ProGuard rules
└── sample-app/                  # Example application
    ├── build.gradle            # App build config
    ├── src/main/
    │   ├── AndroidManifest.xml # App manifest
    │   ├── java/com/openpano/sample/
    │   │   └── MainActivity.java # Sample activity
    │   └── res/                # App resources
    └── proguard-rules.pro      # App ProGuard rules
```

## Next Steps

1. **Build the AAR:** Run `./build_aar.sh` 
2. **Test integration:** Use the sample app as reference
3. **Customize configuration:** Modify OpenPano parameters as needed
4. **Optimize performance:** Adjust image sizes and processing settings
5. **Deploy:** Integrate into your production Android application

For detailed API documentation and usage examples, see the main `android/README.md` file.
