//! Low-level FFI bindings to the C API
//!
//! This module contains unsafe bindings to the C API.
//! Use the safe wrapper in lib.rs instead.

use std::os::raw::{c_char, c_float, c_int};

#[repr(C)]
pub struct CStitcher {
    _private: [u8; 0],
}

#[repr(C)]
pub struct CImage {
    _private: [u8; 0],
}

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct OpenpanoConfig {
    pub cylinder_mode: c_int,
    pub estimate_camera: c_int,
    pub trans_mode: c_int,
    pub ordered_input: c_int,
    pub crop: c_int,
    pub focal_length: c_float,
    pub max_output_size: c_int,
}

pub type OpenpanoError = c_int;

pub const OPENPANO_OK: OpenpanoError = 0;
pub const OPENPANO_ERROR_NULL_POINTER: OpenpanoError = -1;
pub const OPENPANO_ERROR_ADD_IMAGE: OpenpanoError = -2;
pub const OPENPANO_ERROR_STITCH: OpenpanoError = -3;
pub const OPENPANO_ERROR_SAVE: OpenpanoError = -4;
pub const OPENPANO_ERROR_INVALID_PATH: OpenpanoError = -5;
pub const OPENPANO_ERROR_OUT_OF_MEMORY: OpenpanoError = -6;

#[link(name = "openpano_c")]
extern "C" {
    pub fn openpano_default_config() -> OpenpanoConfig;
    
    pub fn openpano_stitcher_create(config: *const OpenpanoConfig) -> *mut CStitcher;
    pub fn openpano_stitcher_destroy(stitcher: *mut CStitcher);
    pub fn openpano_stitcher_add_image(stitcher: *mut CStitcher, path: *const c_char) -> OpenpanoError;
    pub fn openpano_stitcher_build(stitcher: *mut CStitcher) -> *mut CImage;
    pub fn openpano_stitcher_last_error(stitcher: *mut CStitcher) -> *const c_char;
    
    pub fn openpano_image_destroy(img: *mut CImage);
    pub fn openpano_image_save(img: *const CImage, path: *const c_char) -> OpenpanoError;
    pub fn openpano_image_width(img: *const CImage) -> u32;
    pub fn openpano_image_height(img: *const CImage) -> u32;
    pub fn openpano_image_channels(img: *const CImage) -> u32;
    pub fn openpano_image_data(img: *const CImage) -> *const c_float;
    pub fn openpano_image_data_size(img: *const CImage) -> usize;
    pub fn openpano_image_copy_to_u8(
        img: *const CImage,
        buffer: *mut u8,
        buffer_size: usize,
    ) -> OpenpanoError;
}

