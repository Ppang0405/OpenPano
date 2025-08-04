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
