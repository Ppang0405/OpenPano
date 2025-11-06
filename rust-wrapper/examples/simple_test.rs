//! Simple test to verify the library compiles and basic API works
//! 
//! This doesn't actually stitch images (you need test images for that)
//! but verifies the library is working correctly.

use openpano::{Stitcher, StitcherConfig};

fn main() {
    println!("OpenPano Rust Wrapper - Simple Test");
    println!("====================================\n");
    
    // Test 1: Create default config
    println!("Test 1: Creating default configuration...");
    let config = StitcherConfig::default();
    println!("✓ Config created:");
    println!("  - Estimate camera: {}", config.estimate_camera);
    println!("  - Cylinder mode: {}", config.cylinder_mode);
    println!("  - Crop: {}", config.crop);
    println!("  - Focal length: {}", config.focal_length);
    println!();
    
    // Test 2: Create stitcher
    println!("Test 2: Creating stitcher instance...");
    match Stitcher::new() {
        Ok(_stitcher) => {
            println!("✓ Stitcher created successfully!");
        }
        Err(e) => {
            println!("✗ Failed to create stitcher: {}", e);
            return;
        }
    }
    println!();
    
    // Test 3: Create with custom config
    println!("Test 3: Creating stitcher with custom config...");
    let mut custom_config = StitcherConfig::default();
    custom_config.cylinder_mode = true;
    custom_config.crop = false;
    custom_config.max_output_size = 4000;
    
    match Stitcher::with_config(custom_config) {
        Ok(_stitcher) => {
            println!("✓ Stitcher with custom config created!");
        }
        Err(e) => {
            println!("✗ Failed: {}", e);
            return;
        }
    }
    println!();
    
    println!("═══════════════════════════════════");
    println!("✅ All tests passed!");
    println!("═══════════════════════════════════");
    println!();
    println!("To test with actual images:");
    println!("1. Download test data from:");
    println!("   https://github.com/ppwwyyxx/OpenPano/releases/tag/0.1");
    println!();
    println!("2. Run with images:");
    println!("   cargo run --example rust_example -- img1.jpg img2.jpg img3.jpg");
    println!();
    println!("Or use any 2-3 overlapping photos you have!");
}

