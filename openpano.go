package openpano

/*
#cgo CXXFLAGS: -I./src -I./src/third-party -I./src/third-party/flann -std=c++11
#cgo LDFLAGS: -L/Volumes/KINGSTON/_kingston_misc/Ppang0405_OpenPano/build/src -L/opt/homebrew/lib -lopenpano -llodepng -lstdc++ -lm -ljpeg -Wl,-rpath,/Volumes/KINGSTON/_kingston_misc/Ppang0405_OpenPano/build/src
#include "src/cgo_wrapper.h"
#include <stdlib.h>
*/
import "C"

import (
	"fmt"
	"runtime"
	"unsafe"
)

// StitchResult represents the result of image stitching
type StitchResult struct {
	Data     []byte
	Width    int
	Height   int
	Channels int
	Success  bool
	Error    string
}

// Get Version of the library
func GetVersion() string {
	return "0.0.1"
}

func Greetings(name string) string {
	return fmt.Sprintf("Hello, %s!", name)
}

// InitConfig initializes the stitcher configuration
func InitConfig(configPath string) bool {
	var cConfigPath *C.char
	if configPath != "" {
		cConfigPath = C.CString(configPath)
		defer C.free(unsafe.Pointer(cConfigPath))
	} else {
		cConfigPath = nil
	}
	
	result := C.init_stitcher_config(cConfigPath)
	return int(result) == 1
}

// CreateStitcher stitches multiple images into a panorama
func CreateStitcher(imagePaths []string, outputPath string) (*StitchResult, error) {
	if len(imagePaths) < 2 {
		return nil, fmt.Errorf("need at least two images to stitch")
	}
	
	// Convert Go strings to C strings
	cImagePaths := make([]*C.char, len(imagePaths))
	for i, path := range imagePaths {
		cImagePaths[i] = C.CString(path)
		defer C.free(unsafe.Pointer(cImagePaths[i]))
	}
	
	var cOutputPath *C.char
	if outputPath != "" {
		cOutputPath = C.CString(outputPath)
		defer C.free(unsafe.Pointer(cOutputPath))
	} else {
		cOutputPath = nil
	}
	
	// Call the C function
	cResult := C.stitch_images(&cImagePaths[0], C.int(len(imagePaths)), cOutputPath)
	defer C.free_stitch_result(cResult)
	
	// Convert C result to Go result
	result := &StitchResult{
		Width:    int(cResult.width),
		Height:   int(cResult.height),
		Channels: int(cResult.channels),
		Success:  int(cResult.success) == 1,
	}
	
	// Copy image data if successful
	if result.Success && cResult.data != nil {
		dataSize := result.Width * result.Height * result.Channels
		result.Data = C.GoBytes(unsafe.Pointer(cResult.data), C.int(dataSize))
	}
	
	// Copy error message if present
	if cResult.error_message != nil {
		result.Error = C.GoString(cResult.error_message)
	}
	
	if !result.Success {
		return result, fmt.Errorf("stitching failed: %s", result.Error)
	}
	
	return result, nil
}

// StitchImages is a convenience function that initializes config and stitches images
func StitchImages(imagePaths []string, outputPath string, configPath string) (*StitchResult, error) {
	// Initialize configuration
	if !InitConfig(configPath) {
		return nil, fmt.Errorf("failed to initialize stitcher configuration")
	}
	
	// Create stitcher and process images
	return CreateStitcher(imagePaths, outputPath)
}

// Finalizer to ensure cleanup
func init() {
	// Force garbage collection to clean up C memory when Go objects are finalized
	runtime.GC()
}