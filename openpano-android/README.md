# OpenPano Android Integration

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
- **Android NDK** 21.0.6113669 or later
- **CMake** 3.10.2 or later
- **Gradle** 7.0 or later
- **Android SDK** API level 21 (Android 5.0) or later

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/OpenPano.git
cd OpenPano/openpano-android
```

### 2. Open in Android Studio

```bash
# Open Android Studio and select "Open an existing Android Studio project"
# Navigate to the openpano-android directory
```

### 3. Build the Project

1. Click "Sync Project with Gradle Files"
2. Build the project: `Build -> Make Project` or `Build -> Rebuild Project`

The native library will be automatically compiled for all supported architectures.

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
        boolean configOk = OpenPano.initDefaultConfig();
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
            Log.e("OpenPano", "Stitching failed: " + result.getErrorMessage());
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
                    showError(result.getErrorMessage());
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
- `String getErrorMessage()` - Error message if stitching failed
- `String getOutputPath()` - Path where result was saved

## Configuration

The library supports configuration through a config file similar to the desktop version. You can create a config file with the following parameters:

```properties
# General modes
CYLINDER 0
ESTIMATE_CAMERA 1
TRANS 0

# Input settings
ORDERED_INPUT 0
CROP 1
MAX_OUTPUT_SIZE 8000
LAZY_READ 1

# Camera settings
FOCAL_LENGTH 37

# Feature detection parameters
SIFT_WORKING_SIZE 800
NUM_OCTAVE 4
NUM_SCALE 7
SCALE_FACTOR 1.4142135623
GAUSS_SIGMA 1.4142135623
GAUSS_WINDOW_FACTOR 6
CONTRAST_THRES 4e-2
JUDGE_EXTREMA_DIFF_THRES 2e-3
EDGE_RATIO 6

# Matching parameters
MATCH_REJECT_NEXT_RATIO 0.8
```

## Performance Tips

1. **Resize large images** before stitching for better performance
2. **Use background threads** for stitching operations
3. **Cache configuration** - call `initConfig()` once per session
4. **Monitor memory usage** especially with large image sets

## Troubleshooting

### Common Issues

#### Library Not Loading
- Ensure you have the correct NDK version installed
- Check that CMake is properly configured in Android Studio
- Verify that the native library compiled successfully

#### Stitching Failures
- Check that image paths are correct and accessible
- Ensure images are in supported formats (JPEG, PNG)
- Verify that you have proper storage permissions
- Check image sizes - very large images may cause memory issues

#### Performance Issues
- Use smaller images for faster processing
- Enable `LAZY_READ` in configuration to save memory
- Consider processing images in batches for large sets

### Debug Mode

Enable debug logging by adding this to your application:

```java
// Enable debug logging
OpenPano.initConfig("path/to/debug_config.cfg");
```

## Building from Source

### Prerequisites

- Android NDK r21 or later
- CMake 3.10 or later
- Android Studio 4.2 or later

### Build Steps

1. Open the project in Android Studio
2. Sync Gradle files
3. Build the project

The native library will be automatically compiled for all supported architectures.

### Manual NDK Build

If you prefer to build manually:

```bash
cd openpano-android/app/src/main/cpp
cmake -B build -DANDROID_ABI=arm64-v8a -DANDROID_NATIVE_API_LEVEL=21
cmake --build build
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the same terms as the original OpenPano project. See the LICENSE file for details.

## Acknowledgments

- Original OpenPano project by Yuxin Wu
- Android NDK team for the native development tools
- OpenCV community for inspiration on Android computer vision integration
