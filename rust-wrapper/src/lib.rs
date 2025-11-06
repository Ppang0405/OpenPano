//! OpenPano Rust Wrapper
//!
//! This crate provides safe Rust bindings to the OpenPano panorama stitching library.
//! It wraps the C++ implementation with a safe Rust API and provides cross-platform
//! bindings via UniFFI for Python, Swift (iOS), and Kotlin (Android).

mod ffi;
mod uniffi_impl;

pub use uniffi_impl::{PanoConfig, Panorama, stitch_panorama};

use std::ffi::{CStr, CString};
use std::path::Path;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum PanoError {
    #[error("Failed to add image: {0}")]
    AddImageError(String),
    
    #[error("Failed to stitch images: {0}")]
    StitchError(String),
    
    #[error("Failed to save image: {0}")]
    SaveError(String),
    
    #[error("Invalid path: {0}")]
    InvalidPath(String),
    
    #[error("Null pointer error")]
    NullPointer,
    
    #[error("Not enough images (need at least 2)")]
    NotEnoughImages,
}

/// Configuration for the panorama stitcher
#[derive(Debug, Clone)]
pub struct StitcherConfig {
    /// Use cylinder mode (images taken by rotating camera)
    pub cylinder_mode: bool,
    
    /// Estimate camera parameters automatically
    pub estimate_camera: bool,
    
    /// Use translation mode (camera moving, not rotating)
    pub trans_mode: bool,
    
    /// Input images are ordered sequentially
    pub ordered_input: bool,
    
    /// Crop result to remove black borders
    pub crop: bool,
    
    /// Focal length in 35mm equivalent format
    pub focal_length: f32,
    
    /// Maximum output size (width or height)
    pub max_output_size: i32,
}

impl Default for StitcherConfig {
    fn default() -> Self {
        let c_config = unsafe { ffi::openpano_default_config() };
        Self::from_c_config(c_config)
    }
}

impl StitcherConfig {
    fn to_c_config(&self) -> ffi::OpenpanoConfig {
        ffi::OpenpanoConfig {
            cylinder_mode: self.cylinder_mode as i32,
            estimate_camera: self.estimate_camera as i32,
            trans_mode: self.trans_mode as i32,
            ordered_input: self.ordered_input as i32,
            crop: self.crop as i32,
            focal_length: self.focal_length,
            max_output_size: self.max_output_size,
        }
    }
    
    fn from_c_config(c: ffi::OpenpanoConfig) -> Self {
        Self {
            cylinder_mode: c.cylinder_mode != 0,
            estimate_camera: c.estimate_camera != 0,
            trans_mode: c.trans_mode != 0,
            ordered_input: c.ordered_input != 0,
            crop: c.crop != 0,
            focal_length: c.focal_length,
            max_output_size: c.max_output_size,
        }
    }
}

/// Panorama stitcher - builds panoramic images from multiple photos
pub struct Stitcher {
    inner: *mut ffi::CStitcher,
}

impl Stitcher {
    /// Create a new stitcher with default configuration
    pub fn new() -> Result<Self, PanoError> {
        Self::with_config(StitcherConfig::default())
    }
    
    /// Create a new stitcher with custom configuration
    pub fn with_config(config: StitcherConfig) -> Result<Self, PanoError> {
        let c_config = config.to_c_config();
        let inner = unsafe { ffi::openpano_stitcher_create(&c_config as *const _) };
        
        if inner.is_null() {
            Err(PanoError::NullPointer)
        } else {
            Ok(Self { inner })
        }
    }
    
    /// Add an image to be stitched
    pub fn add_image<P: AsRef<Path>>(&mut self, path: P) -> Result<(), PanoError> {
        let path_str = path.as_ref()
            .to_str()
            .ok_or_else(|| PanoError::InvalidPath(format!("{:?}", path.as_ref())))?;
        
        let c_path = CString::new(path_str)
            .map_err(|_| PanoError::InvalidPath(path_str.to_string()))?;
        
        let result = unsafe {
            ffi::openpano_stitcher_add_image(self.inner, c_path.as_ptr())
        };
        
        if result == ffi::OPENPANO_OK {
            Ok(())
        } else {
            let error_msg = self.last_error();
            Err(PanoError::AddImageError(error_msg))
        }
    }
    
    /// Stitch all added images together
    pub fn stitch(self) -> Result<Image, PanoError> {
        let img_ptr = unsafe { ffi::openpano_stitcher_build(self.inner) };
        
        if img_ptr.is_null() {
            let error_msg = self.last_error();
            Err(PanoError::StitchError(error_msg))
        } else {
            Ok(Image { inner: img_ptr })
        }
    }
    
    fn last_error(&self) -> String {
        unsafe {
            let c_str = ffi::openpano_stitcher_last_error(self.inner);
            if c_str.is_null() {
                "Unknown error".to_string()
            } else {
                CStr::from_ptr(c_str)
                    .to_string_lossy()
                    .into_owned()
            }
        }
    }
}

impl Drop for Stitcher {
    fn drop(&mut self) {
        unsafe {
            ffi::openpano_stitcher_destroy(self.inner);
        }
    }
}

// Safety: The C++ library handles thread-safety internally
unsafe impl Send for Stitcher {}

/// A panoramic image
pub struct Image {
    inner: *mut ffi::CImage,
}

impl Image {
    /// Get image width in pixels
    pub fn width(&self) -> u32 {
        unsafe { ffi::openpano_image_width(self.inner) }
    }
    
    /// Get image height in pixels
    pub fn height(&self) -> u32 {
        unsafe { ffi::openpano_image_height(self.inner) }
    }
    
    /// Get number of color channels (typically 3 for RGB)
    pub fn channels(&self) -> u32 {
        unsafe { ffi::openpano_image_channels(self.inner) }
    }
    
    /// Save image to a file
    pub fn save<P: AsRef<Path>>(&self, path: P) -> Result<(), PanoError> {
        let path_str = path.as_ref()
            .to_str()
            .ok_or_else(|| PanoError::InvalidPath(format!("{:?}", path.as_ref())))?;
        
        let c_path = CString::new(path_str)
            .map_err(|_| PanoError::InvalidPath(path_str.to_string()))?;
        
        let result = unsafe {
            ffi::openpano_image_save(self.inner, c_path.as_ptr())
        };
        
        if result == ffi::OPENPANO_OK {
            Ok(())
        } else {
            Err(PanoError::SaveError(path_str.to_string()))
        }
    }
    
    /// Get image data as bytes (RGB, 0-255 range)
    pub fn to_bytes(&self) -> Vec<u8> {
        let size = (self.width() * self.height() * self.channels()) as usize;
        let mut buffer = vec![0u8; size];
        
        unsafe {
            ffi::openpano_image_copy_to_u8(
                self.inner,
                buffer.as_mut_ptr(),
                buffer.len(),
            );
        }
        
        buffer
    }
    
    /// Get raw floating-point image data (0.0-1.0 range)
    pub fn as_floats(&self) -> &[f32] {
        let size = (self.width() * self.height() * self.channels()) as usize;
        unsafe {
            let ptr = ffi::openpano_image_data(self.inner);
            std::slice::from_raw_parts(ptr, size)
        }
    }
}

impl Drop for Image {
    fn drop(&mut self) {
        unsafe {
            ffi::openpano_image_destroy(self.inner);
        }
    }
}

unsafe impl Send for Image {}
unsafe impl Sync for Image {}

/// High-level function to stitch multiple images
///
/// # Example
/// ```no_run
/// use openpano::stitch_images;
///
/// let result = stitch_images(&["img1.jpg", "img2.jpg", "img3.jpg"])?;
/// result.save("panorama.jpg")?;
/// # Ok::<(), openpano::PanoError>(())
/// ```
pub fn stitch_images<P: AsRef<Path>>(image_paths: &[P]) -> Result<Image, PanoError> {
    if image_paths.len() < 2 {
        return Err(PanoError::NotEnoughImages);
    }
    
    let mut stitcher = Stitcher::new()?;
    
    for path in image_paths {
        stitcher.add_image(path)?;
    }
    
    stitcher.stitch()
}

// UniFFI bindings module
uniffi::include_scaffolding!("openpano");

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_config_default() {
        let config = StitcherConfig::default();
        assert!(!config.cylinder_mode);
        assert!(config.estimate_camera);
        assert!(!config.trans_mode);
    }
    
    #[test]
    fn test_stitcher_create() {
        let stitcher = Stitcher::new();
        assert!(stitcher.is_ok());
    }
}

