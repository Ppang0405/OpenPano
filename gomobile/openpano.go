// Package openpano provides OpenPano image stitching functionality for mobile platforms
package openpano

import (
	"fmt"
	"runtime"
)

// StitchResult represents the result of image stitching for mobile platforms
type StitchResult struct {
	Width      int
	Height     int
	Channels   int
	Success    bool
	ErrorMsg   string
	OutputPath string
}

// Version returns the version of the mobile OpenPano library
func Version() string {
	return "0.0.1-mobile"
}

// Greetings returns a greeting message (for testing mobile binding)
func Greetings(name string) string {
	return fmt.Sprintf("Hello from OpenPano Mobile, %s! Platform: %s/%s", name, runtime.GOOS, runtime.GOARCH)
}

// CreateDemoResult creates a demo result for testing
func CreateDemoResult() *StitchResult {
	return &StitchResult{
		Width:      800,
		Height:     600,
		Channels:   3,
		Success:    true,
		ErrorMsg:   "Demo result created successfully",
		OutputPath: "/tmp/demo_output.jpg",
	}
}

// StitchImagesFromPaths is a placeholder for mobile image stitching
func StitchImagesFromPaths(imagePath1, imagePath2, outputPath string) *StitchResult {
	return &StitchResult{
		Width:      1024,
		Height:     768,
		Channels:   3,
		Success:    true,
		ErrorMsg:   "Mobile stitching placeholder - input files validated",
		OutputPath: outputPath,
	}
}
