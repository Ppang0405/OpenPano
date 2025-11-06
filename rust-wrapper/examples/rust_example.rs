//! Example usage of OpenPano Rust wrapper

use openpano::{Stitcher, StitcherConfig, PanoError};
use std::env;

fn main() -> Result<(), PanoError> {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 3 {
        eprintln!("Usage: {} <image1> <image2> [image3] ...", args[0]);
        eprintln!("Example: {} img1.jpg img2.jpg img3.jpg", args[0]);
        std::process::exit(1);
    }
    
    println!("OpenPano Rust Example");
    println!("====================\n");
    
    // Create custom configuration
    let mut config = StitcherConfig::default();
    config.estimate_camera = true;
    config.crop = true;
    config.max_output_size = 8000;
    
    println!("Configuration:");
    println!("  Estimate camera: {}", config.estimate_camera);
    println!("  Cylinder mode: {}", config.cylinder_mode);
    println!("  Crop: {}", config.crop);
    println!("  Max output size: {}", config.max_output_size);
    println!();
    
    // Create stitcher
    println!("Creating stitcher...");
    let mut stitcher = Stitcher::with_config(config)?;
    
    // Add images
    println!("Adding {} images:", args.len() - 1);
    for (i, image_path) in args[1..].iter().enumerate() {
        println!("  [{}] {}", i + 1, image_path);
        stitcher.add_image(image_path)?;
    }
    println!();
    
    // Stitch
    println!("Stitching images... (this may take a while)");
    let start = std::time::Instant::now();
    let panorama = stitcher.stitch()?;
    let duration = start.elapsed();
    
    println!("✓ Stitching completed in {:.2}s", duration.as_secs_f64());
    println!();
    
    // Print info
    println!("Result:");
    println!("  Width: {} px", panorama.width());
    println!("  Height: {} px", panorama.height());
    println!("  Channels: {}", panorama.channels());
    println!("  Total pixels: {}", panorama.width() * panorama.height());
    println!();
    
    // Save
    let output_path = "panorama_output.jpg";
    println!("Saving to '{}'...", output_path);
    panorama.save(output_path)?;
    
    println!("✓ Done!");
    
    Ok(())
}

