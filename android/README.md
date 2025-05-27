# OpenPano Android Integration

This document provides instructions for integrating OpenPano image stitching functionality into Android applications.

## Overview

OpenPano Android provides native image stitching capabilities for Android applications. The library supports all major Android architectures (arm64-v8a, armeabi-v7a, x86, x86_64) and provides a simple Java API for seamless integration.

## Features

- **High-performance image stitching** using native C++ code
- **Multi-architecture support** for all Android devices
- **Simple Java API** for easy integration
- **Memory efficient** processing
- **Support for various image formats** via lodepng
- **Configurable stitching parameters**

## Build Requirements

- **Android Studio** 4.2 or later
- **Android NDK** 27.1.12297006 or later
- **CMake** 3.22.1 or later
- **Gradle** 8.0 or later
- **Android SDK** API level 21 (Android 5.0) or later

## Building the AAR

### Prerequisites

1. Ensure you have Android Studio with NDK support installed
2. Install CMake through Android Studio SDK Manager
3. Clone the OpenPano repository with all source files

### Build Steps

1. **Navigate to Android directory:**
   ```bash
   cd android
   ```

2. **Build the AAR file:**
   ```bash
   ./gradlew :openpano-android:assembleRelease
   ```

3. **Find the generated AAR:**
   The AAR file will be generated at:
   ```
   android/openpano-android/build/outputs/aar/openpano-android-release.aar
   ```

### Build for All Architectures

The build system automatically compiles for all supported architectures:
- **arm64-v8a** - 64-bit ARM (most modern devices)
- **armeabi-v7a** - 32-bit ARM (older devices)
- **x86** - 32-bit Intel (emulators)
- **x86_64** - 64-bit Intel (emulators and some tablets)

## Integration into Android Project

### 1. Add AAR to Your Project

Copy the generated AAR file to your Android project:

```bash
cp android/openpano-android/build/outputs/aar/openpano-android-release.aar /path/to/your/android/project/libs/
```

### 2. Update Module build.gradle

Add the following to your app's `build.gradle` file:

```gradle
android {
    // ... existing configuration ...
    
    packagingOptions {
        pickFirst '**/libc++_shared.so'
        pickFirst '**/libjsc.so'
    }
}

dependencies {
    implementation fileTree(dir: 'libs', include: ['*.aar'])
    // ... other dependencies ...
}
```

### 3. Add Required Permissions

Add these permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

For Android 10+ (API 29+), also consider adding:

```xml
<application
    android:requestLegacyExternalStorage="true"
    ... >
</application>
```

## Usage Examples

### Basic Image Stitching

```java
import com.openpano.lib.OpenPano;
import com.openpano.lib.StitchResult;

public class PanoramaActivity extends AppCompatActivity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Check if library is ready
        if (!OpenPano.isLibraryReady()) {
            Log.e("OpenPano", "Library not loaded properly");
            return;
        }
        
        // Initialize with default configuration
        boolean configOk = OpenPano.initConfig(null);
        if (!configOk) {
            Log.e("OpenPano", "Failed to initialize configuration");
            return;
        }
        
        // Prepare image paths
        String[] imagePaths = {
            "/sdcard/Pictures/image1.jpg",
            "/sdcard/Pictures/image2.jpg"
        };
        
        String outputPath = "/sdcard/Pictures/panorama_output.jpg";
        
        // Perform stitching
        StitchResult result = OpenPano.stitchImages(imagePaths, outputPath);
        
        if (result.isSuccess()) {
            Log.i("OpenPano", "Stitching successful: " + result.getWidth() + "x" + result.getHeight());
            Log.i("OpenPano", "Output saved to: " + result.getOutputPath());
        } else {
            Log.e("OpenPano", "Stitching failed: " + result.getMessage());
        }
    }
}
```

### Asynchronous Stitching

```java
public class AsyncStitchingExample {
    
    public void stitchImagesAsync(String[] imagePaths, String outputPath) {
        new AsyncTask<Void, Void, StitchResult>() {
            @Override
            protected StitchResult doInBackground(Void... params) {
                return OpenPano.stitchImages(imagePaths, outputPath);
            }
            
            @Override
            protected void onPostExecute(StitchResult result) {
                if (result.isSuccess()) {
                    // Handle success
                    showResult(result);
                } else {
                    // Handle error
                    showError(result.getMessage());
                }
            }
        }.execute();
    }
}
```

### Using with Modern Android Architecture

```java
// Repository class
public class PanoramaRepository {
    
    public LiveData<StitchResult> stitchImages(String[] imagePaths, String outputPath) {
        MutableLiveData<StitchResult> resultLiveData = new MutableLiveData<>();
        
        ExecutorService executor = Executors.newSingleThreadExecutor();
        executor.execute(() -> {
            StitchResult result = OpenPano.stitchImages(imagePaths, outputPath);
            resultLiveData.postValue(result);
        });
        
        return resultLiveData;
    }
}

// ViewModel class
public class PanoramaViewModel extends ViewModel {
    private PanoramaRepository repository;
    
    public LiveData<StitchResult> stitchImages(String[] imagePaths, String outputPath) {
        return repository.stitchImages(imagePaths, outputPath);
    }
}
```

## API Reference

### OpenPano Class

#### Static Methods

- `String getVersion()` - Returns the library version
- `boolean initConfig(String configPath)` - Initialize configuration (null for default)
- `StitchResult stitchImages(String[] imagePaths, String outputPath)` - Stitch multiple images
- `StitchResult stitchTwoImages(String image1, String image2, String outputPath)` - Convenience method for two images
- `String getSystemInfo()` - Get system and library information
- `boolean isLibraryReady()` - Check if library is properly loaded

### StitchResult Class

#### Methods

- `int getWidth()` - Width of stitched image
- `int getHeight()` - Height of stitched image
- `int getChannels()` - Number of color channels
- `boolean isSuccess()` - Whether stitching was successful
- `String getMessage()` - Success or error message
- `String getOutputPath()` - Path where result was saved

## Configuration

The library supports custom configuration files. Create a configuration file with the following parameters:

```
# SIFT Configuration
SIFT_WORKING_SIZE 800
CONTRAST_THRES 4e-2
EDGE_THRES 10.0
SIFT_MAXKEYPOINTS 4000

# Camera Configuration
ESTIMATE_CAMERA 1
FOCAL_LENGTH 1200

# Bundle Adjustment
MULTIPASS_BA 1
MAX_BA_ITERATION 20

# Output Configuration
STRAIGHTEN 1
CROP 1
```

Pass the configuration file path to `initConfig()`:

```java
boolean success = OpenPano.initConfig("/path/to/config.cfg");
```

## Troubleshooting

### Common Issues

1. **Library not loading:**
   - Ensure all required ABIs are included
   - Check that NDK version matches build requirements
   - Verify that c++_shared STL is properly included

2. **Stitching failures:**
   - Ensure images have sufficient overlap (20-30%)
   - Check image quality and focus
   - Verify file paths are accessible
   - Try adjusting configuration parameters

3. **Memory issues:**
   - Reduce image size before stitching
   - Ensure sufficient free storage space
   - Monitor memory usage during processing

4. **Permission errors:**
   - Request runtime permissions for file access (API 23+)
   - Use scoped storage for Android 10+ if needed

### Debug Information

Enable detailed logging by checking system info:

```java
String info = OpenPano.getSystemInfo();
Log.d("OpenPano", "System Info: " + info);
```

### Performance Tips

1. **Resize large images** before stitching for better performance
2. **Use background threads** for stitching operations
3. **Cache configuration** - call `initConfig()` once per session
4. **Monitor memory usage** especially with large image sets

## Build Configuration Details

### Supported Architectures

| Architecture | Description | Devices |
|-------------|-------------|---------|
| arm64-v8a | 64-bit ARM | Modern Android devices |
| armeabi-v7a | 32-bit ARM | Older Android devices |
| x86 | 32-bit Intel | Android emulators |
| x86_64 | 64-bit Intel | Intel-based tablets, emulators |

### Build Parameters

- **NDK Version:** 27.1.12297006
- **CMake Version:** 3.22.1
- **C++ Standard:** C++11
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** 34 (Android 14)
- **STL:** c++_shared

## License

This Android integration follows the same license as the main OpenPano project. Please refer to the main project LICENSE file for details.

## Contributing

To contribute to the Android integration:

1. Fork the repository
2. Create a feature branch
3. Make your changes to the Android-specific code
4. Test on multiple architectures
5. Submit a pull request

## Support

For issues specific to Android integration, please:

1. Check this README for common solutions
2. Review the troubleshooting section
3. Check existing GitHub issues
4. Create a new issue with detailed reproduction steps

Include the following information when reporting issues:
- Android version and device model
- Library version (`OpenPano.getVersion()`)
- Build configuration
- Error messages and stack traces
- Sample images (if applicable)
