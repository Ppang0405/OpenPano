package main

import (
	"fmt"
	"log"
	"os"
)

func main() {
	// Test the basic functions first without external dependencies
	fmt.Println("OpenPano CGO Integration Test")
	
	// Test the basic Go functions
	fmt.Printf("Library version: %s\n", GetVersion())
	fmt.Printf("Greetings test: %s\n", Greetings("CGO User"))
	
	// Test config initialization
	fmt.Println("\nTesting configuration initialization...")
	configPath := "config.cfg"
	if InitConfig(configPath) {
		fmt.Println("✅ Configuration initialized successfully!")
	} else {
		fmt.Println("❌ Failed to initialize configuration")
		return
	}
	
	// Show usage if no arguments provided
	if len(os.Args) < 3 {
		fmt.Println("\nUsage for image stitching:")
		fmt.Println("go run basic_test.go <image1> <image2> [output_path]")
		fmt.Println("Example: go run basic_test.go img1.jpg img2.jpg panorama.jpg")
		fmt.Println("\nNote: This test program requires actual image files to stitch.")
		fmt.Println("The current directory should contain config.cfg and input images.")
		return
	}
	
	// If we have images, try to stitch them
	imagePaths := []string{os.Args[1], os.Args[2]}
	outputPath := "test_output.jpg"
	if len(os.Args) > 3 {
		outputPath = os.Args[3]
	}
	
	fmt.Printf("\nAttempting to stitch images: %v\n", imagePaths)
	fmt.Printf("Output path: %s\n", outputPath)
	
	// Check if input files exist
	for _, path := range imagePaths {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			log.Fatalf("Image file does not exist: %s", path)
		}
	}
	
	// Stitch images using the convenient function
	fmt.Println("Starting image stitching...")
	result, err := StitchImages(imagePaths, outputPath, configPath)
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
