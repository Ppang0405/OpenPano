# OpenPano Go CGO Integration

This implementation provides Go language bindings for the OpenPano panorama stitching library using CGO (C-Go interoperability).

## Overview

The CGO integration allows you to use OpenPano's powerful image stitching capabilities directly from Go programs. The implementation includes:

- C wrapper functions (`src/cgo_wrapper.h` and `src/cgo_wrapper.cc`)
- Go bindings (`openpano.go`) 
- Configuration initialization
- Image stitching functionality
- Memory management

## Prerequisites

1. **Build the C++ library first:**
   ```bash
   cmake -B build
   make -C build
   ```

2. **Required dependencies:**
   - CMake >= 3.20
   - C++ compiler (GCC >= 5, Clang >= 10, or Visual Studio >= 2015)
   - Eigen3
   - libjpeg (optional)
   - Go >= 1.21

## API Reference

### Main Functions

#### `InitConfig(configPath string) bool`
Initializes the OpenPano configuration from a config file.
- `configPath`: Path to config.cfg file (use empty string for default "config.cfg")
- Returns: `true` if successful, `false` otherwise

#### `CreateStitcher(imagePaths []string, outputPath string) (*StitchResult, error)`
Stitches multiple images into a panorama.
- `imagePaths`: Slice of input image file paths (minimum 2 images)
- `outputPath`: Output file path (use empty string to skip file output)
- Returns: `StitchResult` struct and error

#### `StitchImages(imagePaths []string, outputPath string, configPath string) (*StitchResult, error)`
Convenience function that combines config initialization and stitching.

### StitchResult Structure

```go
type StitchResult struct {
    Data     []byte  // RGB image data (width * height * 3 bytes)
    Width    int     // Image width in pixels  
    Height   int     // Image height in pixels
    Channels int     // Number of color channels (typically 3 for RGB)
    Success  bool    // Whether stitching succeeded
    Error    string  // Error message if failed
}
```

## Usage Examples

### Basic Usage

```go
package main

import (
    "fmt"
    "log"
    "openpano"
)

func main() {
    // Initialize configuration
    if !openpano.InitConfig("config.cfg") {
        log.Fatal("Failed to initialize configuration")
    }
    
    // Stitch images
    imagePaths := []string{"image1.jpg", "image2.jpg", "image3.jpg"}
    result, err := openpano.CreateStitcher(imagePaths, "panorama.jpg")
    if err != nil {
        log.Fatalf("Stitching failed: %v", err)
    }
    
    fmt.Printf("Success! Panorama size: %dx%d\n", result.Width, result.Height)
}
```

### One-step Stitching

```go
package main

import (
    "fmt"
    "log" 
    "openpano"
)

func main() {
    imagePaths := []string{"img1.jpg", "img2.jpg"}
    result, err := openpano.StitchImages(imagePaths, "output.jpg", "config.cfg")
    if err != nil {
        log.Fatalf("Failed: %v", err)
    }
    
    fmt.Printf("Stitched %d images into %dx%d panorama\n", 
               len(imagePaths), result.Width, result.Height)
}
```

## Configuration

The library uses OpenPano's standard configuration file format (`config.cfg`). Key settings include:

- `CYLINDER`: Enable cylindrical projection mode
- `ESTIMATE_CAMERA`: Enable camera parameter estimation
- `FOCAL_LENGTH`: Camera focal length (for cylinder mode)
- `CROP`: Enable output cropping
- `ORDERED_INPUT`: Whether input images are ordered sequentially

## Building and Testing

1. **Build the Go library:**
   ```bash
   go build
   ```

2. **Run basic test:**
   ```bash
   go run basic_test.go
   ```

3. **Test with images:**
   ```bash
   go run basic_test.go image1.jpg image2.jpg output.jpg
   ```

## Memory Management

The CGO integration handles memory management automatically:
- C memory is freed using defer statements
- Image data is copied to Go memory space
- Result structs are properly cleaned up

## Error Handling

The library provides comprehensive error handling:
- Configuration errors are reported during initialization
- Stitching errors include descriptive messages
- File I/O errors are handled gracefully
- Memory allocation failures are detected

## Performance Notes

- The library uses OpenMP for parallel processing (if available)
- Large images are automatically downscaled if needed
- Memory usage can be reduced using the `LAZY_READ` option
- Processing time depends on image size and number of features

## Troubleshooting

### Common Issues

1. **"config.cfg not found"**: Ensure the config file is in the working directory
2. **"Cannot find feature in image"**: Input images may be too small or lack features
3. **CGO linking errors**: Ensure the C++ library was built successfully
4. **Memory errors**: Check that input images are valid and readable

### Debug Information

Enable debug output by setting appropriate flags in `config.cfg`:
- Increase verbosity for detailed processing information
- Use debug output files to analyze intermediate results

## Examples Directory

The `examples/` directory contains sample programs demonstrating various use cases:
- `main.go`: Basic CGO integration test
- `test_openpano.go`: Full stitching example

Run examples with:
```bash
cd examples
go run main.go
```
