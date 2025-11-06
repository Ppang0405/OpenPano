//! Command-line panorama stitching tool
//! 
//! Drop-in replacement for the original C++ image-stitching binary.
//! Compatible with the run_test.py script.

use openpano::{Stitcher, StitcherConfig};
use std::env;
use std::process;
use std::time::Instant;

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 3 {
        eprintln!("Usage: {} <image1> <image2> [image3] ...", args[0]);
        eprintln!("Need at least two images to stitch.");
        process::exit(1);
    }
    
    let image_paths: Vec<String> = args[1..].to_vec();
    
    println!("OpenPano - Panorama Image Stitching");
    println!("Stitching {} images...", image_paths.len());
    
    // Create stitcher with default configuration
    let config = StitcherConfig::default();
    let mut stitcher = match Stitcher::with_config(config) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("Error creating stitcher: {}", e);
            process::exit(1);
        }
    };
    
    // Add all images
    for (i, path) in image_paths.iter().enumerate() {
        println!("Adding image {}: {}", i + 1, path);
        if let Err(e) = stitcher.add_image(path) {
            eprintln!("Error adding image '{}': {}", path, e);
            process::exit(1);
        }
    }
    
    // Stitch images
    println!("Building panorama...");
    let start = Instant::now();
    
    let panorama = match stitcher.stitch() {
        Ok(p) => p,
        Err(e) => {
            eprintln!("Error stitching images: {}", e);
            process::exit(1);
        }
    };
    
    let duration = start.elapsed();
    
    let width = panorama.width();
    let height = panorama.height();
    
    // Print in format expected by run_test.py
    println!("Final Image Size ({}, {})", width, height);
    println!("Stitching completed in {:.2}s", duration.as_secs_f64());
    
    // Save output (compatible with original behavior)
    let output_path = "out.jpg";
    println!("Saving to '{}'...", output_path);
    
    if let Err(e) = panorama.save(output_path) {
        eprintln!("Error saving panorama: {}", e);
        process::exit(1);
    }
    
    println!("Done!");
}

