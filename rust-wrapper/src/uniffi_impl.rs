//! UniFFI implementation for cross-platform bindings

use crate::{Image, Stitcher, StitcherConfig, PanoError};
use std::sync::Arc;

/// Configuration for panorama stitching (UniFFI-compatible)
#[derive(Debug, Clone)]
pub struct PanoConfig {
    pub cylinder_mode: bool,
    pub estimate_camera: bool,
    pub trans_mode: bool,
    pub ordered_input: bool,
    pub crop: bool,
    pub focal_length: f32,
    pub max_output_size: i32,
}

impl From<PanoConfig> for StitcherConfig {
    fn from(config: PanoConfig) -> Self {
        StitcherConfig {
            cylinder_mode: config.cylinder_mode,
            estimate_camera: config.estimate_camera,
            trans_mode: config.trans_mode,
            ordered_input: config.ordered_input,
            crop: config.crop,
            focal_length: config.focal_length,
            max_output_size: config.max_output_size,
        }
    }
}

impl Default for PanoConfig {
    fn default() -> Self {
        let config = StitcherConfig::default();
        Self {
            cylinder_mode: config.cylinder_mode,
            estimate_camera: config.estimate_camera,
            trans_mode: config.trans_mode,
            ordered_input: config.ordered_input,
            crop: config.crop,
            focal_length: config.focal_length,
            max_output_size: config.max_output_size,
        }
    }
}

/// Panorama result (UniFFI-compatible wrapper around Image)
pub struct Panorama {
    image: Arc<Image>,
}

impl Panorama {
    pub fn width(&self) -> u32 {
        self.image.width()
    }
    
    pub fn height(&self) -> u32 {
        self.image.height()
    }
    
    pub fn channels(&self) -> u32 {
        self.image.channels()
    }
    
    pub fn save(&self, path: String) -> Result<(), PanoError> {
        self.image.save(path)
    }
    
    pub fn to_bytes(&self) -> Vec<u8> {
        self.image.to_bytes()
    }
}

/// Stitch multiple images into a panorama
pub fn stitch_panorama(
    image_paths: Vec<String>,
    config: Option<PanoConfig>,
) -> Result<Arc<Panorama>, PanoError> {
    if image_paths.len() < 2 {
        return Err(PanoError::NotEnoughImages);
    }
    
    let stitcher_config = config
        .map(|c| c.into())
        .unwrap_or_default();
    
    let mut stitcher = Stitcher::with_config(stitcher_config)?;
    
    for path in image_paths {
        stitcher.add_image(path)?;
    }
    
    let image = stitcher.stitch()?;
    
    Ok(Arc::new(Panorama {
        image: Arc::new(image),
    }))
}

