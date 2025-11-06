// Example usage of OpenPano Swift bindings for iOS/macOS
//
// Build: swift build
// Run: swift run SwiftExample img1.jpg img2.jpg img3.jpg

import Foundation
import OpenPano

func main() {
    let args = CommandLine.arguments
    
    guard args.count >= 3 else {
        print("Usage: \(args[0]) <image1> <image2> [image3] ...")
        print("Example: \(args[0]) img1.jpg img2.jpg img3.jpg")
        exit(1)
    }
    
    let imagePaths = Array(args.dropFirst())
    
    print("OpenPano Swift Example")
    print(String(repeating: "=", count: 40))
    print()
    
    // Check if files exist
    for path in imagePaths {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Error: File not found: \(path)")
            exit(1)
        }
    }
    
    // Create configuration
    let config = PanoConfig(
        cylinderMode: false,
        estimateCamera: true,
        transMode: false,
        orderedInput: false,
        crop: true,
        focalLength: 37.0,
        maxOutputSize: 8000
    )
    
    print("Configuration:")
    print("  Estimate camera: \(config.estimateCamera)")
    print("  Cylinder mode: \(config.cylinderMode)")
    print("  Crop: \(config.crop)")
    print("  Max output size: \(config.maxOutputSize)")
    print()
    
    // Add images
    print("Adding \(imagePaths.count) images:")
    for (i, path) in imagePaths.enumerated() {
        print("  [\(i + 1)] \(path)")
    }
    print()
    
    // Stitch
    print("Stitching images... (this may take a while)")
    let start = Date()
    
    do {
        let panorama = try stitchPanorama(imagePaths: imagePaths, config: config)
        let duration = Date().timeIntervalSince(start)
        
        print(String(format: "✓ Stitching completed in %.2fs", duration))
        print()
        
        // Print info
        print("Result:")
        print("  Width: \(panorama.width()) px")
        print("  Height: \(panorama.height()) px")
        print("  Channels: \(panorama.channels())")
        print("  Total pixels: \(panorama.width() * panorama.height())")
        print()
        
        // Save
        let outputPath = "panorama_output.jpg"
        print("Saving to '\(outputPath)'...")
        try panorama.save(path: outputPath)
        
        print("✓ Done!")
        
        // Optional: Get raw bytes for further processing
        // let bytesData = panorama.toBytes()
        // print("  Raw data size: \(bytesData.count) bytes")
        
    } catch PanoError.StitchError(let message) {
        print("Stitching failed: \(message)")
        exit(1)
    } catch PanoError.SaveError(let message) {
        print("Save failed: \(message)")
        exit(1)
    } catch {
        print("Unexpected error: \(error)")
        exit(1)
    }
}

main()

