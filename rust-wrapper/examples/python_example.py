#!/usr/bin/env python3
"""
Example usage of OpenPano Python bindings

Install: pip install maturin && maturin develop
Usage: python python_example.py img1.jpg img2.jpg img3.jpg
"""

import sys
from pathlib import Path

try:
    from openpano import stitch_panorama, PanoConfig, PanoError
except ImportError:
    print("Error: openpano module not found!")
    print("Install with: cd rust-wrapper && maturin develop")
    sys.exit(1)


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <image1> <image2> [image3] ...")
        print(f"Example: {sys.argv[0]} img1.jpg img2.jpg img3.jpg")
        sys.exit(1)
    
    image_paths = sys.argv[1:]
    
    print("OpenPano Python Example")
    print("=" * 40)
    print()
    
    # Check if files exist
    for path in image_paths:
        if not Path(path).exists():
            print(f"Error: File not found: {path}")
            sys.exit(1)
    
    # Create configuration
    config = PanoConfig(
        cylinder_mode=False,
        estimate_camera=True,
        trans_mode=False,
        ordered_input=False,
        crop=True,
        focal_length=37.0,
        max_output_size=8000
    )
    
    print("Configuration:")
    print(f"  Estimate camera: {config.estimate_camera}")
    print(f"  Cylinder mode: {config.cylinder_mode}")
    print(f"  Crop: {config.crop}")
    print(f"  Max output size: {config.max_output_size}")
    print()
    
    # Add images
    print(f"Adding {len(image_paths)} images:")
    for i, path in enumerate(image_paths, 1):
        print(f"  [{i}] {path}")
    print()
    
    # Stitch
    print("Stitching images... (this may take a while)")
    import time
    start = time.time()
    
    try:
        panorama = stitch_panorama(image_paths, config)
        duration = time.time() - start
        
        print(f"✓ Stitching completed in {duration:.2f}s")
        print()
        
        # Print info
        print("Result:")
        print(f"  Width: {panorama.width()} px")
        print(f"  Height: {panorama.height()} px")
        print(f"  Channels: {panorama.channels()}")
        print(f"  Total pixels: {panorama.width() * panorama.height():,}")
        print()
        
        # Save
        output_path = "panorama_output.jpg"
        print(f"Saving to '{output_path}'...")
        panorama.save(output_path)
        
        print("✓ Done!")
        
        # Optional: Get raw bytes for further processing
        # bytes_data = panorama.to_bytes()
        # print(f"  Raw data size: {len(bytes_data)} bytes")
        
    except PanoError.StitchError as e:
        print(f"Stitching failed: {e}")
        sys.exit(1)
    except PanoError.SaveError as e:
        print(f"Save failed: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

