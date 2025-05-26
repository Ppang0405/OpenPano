package main

import (
	"fmt"
	"log"
	"os"

	"openpano"
)

// Simple test program to demonstrate the OpenPano CGO integration
func main() {
	fmt.Println("OpenPano CGO Integration Test")
	fmt.Printf("Library version: %s\n", openpano.GetVersion())
	
	// Check if we have enough arguments
	if len(os.Args) < 3 {
		fmt.Println("Usage: go run test_openpano.go <image1> <image2> [image3...] [output_path]")
		fmt.Println("Example: go run test_openpano.go img1.jpg img2.jpg panorama.jpg")
		return
	}
	
	// Parse arguments
	var imagePaths []string
	var outputPath string
	
	if len(os.Args) == 3 {
		// Two images, no output path specified
		imagePaths = os.Args[1:3]
		outputPath = "out.jpg"
	} else {
		// Multiple images, last argument is output path
		imagePaths = os.Args[1 : len(os.Args)-1]
		outputPath = os.Args[len(os.Args)-1]
	}
	
	fmt.Printf("Input images: %v\n", imagePaths)
	fmt.Printf("Output path: %s\n", outputPath)
	
	// Check if input files exist
	for _, path := range imagePaths {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			log.Fatalf("Image file does not exist: %s", path)
		}
	}
	
	// Initialize configuration
	fmt.Println("Initializing configuration...")
	configPath := "config.cfg"
	if !openpano.InitConfig(configPath) {
		log.Fatal("Failed to initialize configuration")
	}
	
	// Stitch images
	fmt.Println("Starting image stitching...")
	result, err := openpano.CreateStitcher(imagePaths, outputPath)
	if err != nil {
		log.Fatalf("Failed to stitch images: %v", err)
	}
	
	if result.Success {
		fmt.Printf("✅ Successfully stitched %d images!\n", len(imagePaths))
		fmt.Printf("   Output dimensions: %dx%d\n", result.Width, result.Height)
		fmt.Printf("   Channels: %d\n", result.Channels)
		fmt.Printf("   Data size: %d bytes\n", len(result.Data))
		fmt.Printf("   Output saved to: %s\n", outputPath)
		
		if result.Error != "" {
			fmt.Printf("   Warning: %s\n", result.Error)
		}
	} else {
		log.Fatalf("❌ Stitching failed: %s", result.Error)
	}
}
