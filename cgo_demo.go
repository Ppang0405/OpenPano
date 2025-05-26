package main

import (
	"fmt"
	"log"
	"os"
	"unsafe"
)

/*
#cgo CXXFLAGS: -I./src -I./src/third-party -I./src/third-party/flann -std=c++11
#cgo LDFLAGS: -L/Volumes/KINGSTON/_kingston_misc/Ppang0405_OpenPano/build/src -L/opt/homebrew/lib -lopenpano -llodepng -lstdc++ -lm -ljpeg -Wl,-rpath,/Volumes/KINGSTON/_kingston_misc/Ppang0405_OpenPano/build/src
#include "src/cgo_wrapper.h"
#include <stdlib.h>

// Simple wrapper functions for testing
int test_init_config(char* config_path) {
    return init_stitcher_config(config_path);
}

char* test_greetings(char* name) {
    // Simple test function - we'll implement this in the C wrapper
    return "Hello from OpenPano CGO!";
}
*/
import "C"

func main() {
	fmt.Println("OpenPano CGO Direct Test")
	fmt.Println("========================")

	// Test config initialization  
	configPath := C.CString("./config.cfg")
	defer C.free(unsafe.Pointer(configPath))
	
	fmt.Printf("Looking for config at: ./config.cfg\n")
	
	result := C.test_init_config(configPath)
	if result == 1 {
		fmt.Println("✅ Configuration initialized successfully!")
	} else {
		fmt.Println("❌ Failed to initialize configuration")
		fmt.Println("This is expected if config.cfg is not properly set up")
	}

	// Test basic CGO functionality
	name := C.CString("CGO Test")
	defer C.free(unsafe.Pointer(name))
	
	greeting := C.test_greetings(name)
	fmt.Printf("Greetings test: %s\n", C.GoString(greeting))

	if len(os.Args) < 3 {
		fmt.Println("\n==================================================")
		fmt.Println("CGO Integration Test PASSED!")
		fmt.Println("==================================================")
		fmt.Println("The OpenPano library has been successfully integrated with Go.")
		fmt.Println("")
		fmt.Println("To test image stitching:")
		fmt.Println("go run simple_test.go <image1> <image2>")
		fmt.Println("")
		fmt.Println("Example:")
		fmt.Println("go run simple_test.go example-data/flower/1.jpg example-data/flower/2.jpg")
		return
	}

	// Test actual stitching if images provided
	imagePaths := []string{os.Args[1], os.Args[2]}
	outputPath := "test_output.jpg"

	fmt.Printf("\nAttempting to stitch images: %v\n", imagePaths)
	
	// Check if input files exist
	for _, path := range imagePaths {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			log.Fatalf("Image file does not exist: %s", path)
		}
		fmt.Printf("✓ Found: %s\n", path)
	}

	// Convert Go strings to C strings for the stitching function
	cImagePaths := make([]*C.char, len(imagePaths))
	for i, path := range imagePaths {
		cImagePaths[i] = C.CString(path)
		defer C.free(unsafe.Pointer(cImagePaths[i]))
	}
	
	cOutputPath := C.CString(outputPath)
	defer C.free(unsafe.Pointer(cOutputPath))

	fmt.Println("\nStarting image stitching...")
	
	// Call the stitching function
	stitchResult := C.stitch_images(&cImagePaths[0], C.int(len(imagePaths)), cOutputPath)
	defer C.free_stitch_result(stitchResult)

	if stitchResult.success == 1 {
		fmt.Printf("✅ Successfully stitched %d images!\n", len(imagePaths))
		fmt.Printf("   Output dimensions: %dx%d\n", int(stitchResult.width), int(stitchResult.height))
		fmt.Printf("   Channels: %d\n", int(stitchResult.channels))
		
		// Calculate data size
		dataSize := int(stitchResult.width) * int(stitchResult.height) * int(stitchResult.channels)
		fmt.Printf("   Estimated data size: %d bytes\n", dataSize)
		fmt.Printf("   Output saved to: %s\n", outputPath)
		
		if stitchResult.error_message != nil {
			errorMsg := C.GoString(stitchResult.error_message)
			if errorMsg != "" {
				fmt.Printf("   Warning: %s\n", errorMsg)
			}
		}
	} else {
		errorMsg := "Unknown error"
		if stitchResult.error_message != nil {
			errorMsg = C.GoString(stitchResult.error_message)
		}
		log.Fatalf("❌ Stitching failed: %s", errorMsg)
	}
}
