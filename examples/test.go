package main

import (
	"fmt"
	"log"
	"os"
	"strings"

	"openpano"
)

func main() {
	fmt.Println("OpenPano CGO Integration Test")
	fmt.Println("=============================")
	
	// Test basic functions
	fmt.Printf("Library version: %s\n", openpano.GetVersion())
	fmt.Printf("Greetings test: %s\n", openpano.Greetings("CGO Integration"))
	
	// Get parent directory for config
	configPath := "../config.cfg"
	
	fmt.Printf("Looking for config at: %s\n", configPath)
	
	// Test config initialization  
	if openpano.InitConfig(configPath) {
		fmt.Println("✅ Configuration initialized successfully!")
	} else {
		fmt.Println("❌ Failed to initialize configuration")
		fmt.Println("Make sure config.cfg exists in the parent directory")
		return
	}
	
	if len(os.Args) < 3 {
		fmt.Println("\n" + strings.Repeat("=", 50))
		fmt.Println("CGO Integration Test PASSED!")
		fmt.Println(strings.Repeat("=", 50))
		fmt.Println("The OpenPano library has been successfully integrated with Go.")
		fmt.Println("")
		fmt.Println("To test image stitching:")
		fmt.Println("go run test.go <image1> <image2> [output.jpg]")
		fmt.Println("")
		fmt.Println("Example:")
		fmt.Println("go run test.go ../results/apartment.jpg ../results/apple.jpg test_output.jpg")
		return
	}
	
	// Test actual stitching if images provided
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
		fmt.Printf("✓ Found: %s\n", path)
	}
	
	fmt.Println("\nStarting image stitching...")
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
