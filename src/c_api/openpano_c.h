/**
 * @file openpano_c.h
 * @brief C API for OpenPano - enables FFI bindings for Rust, Python, Swift, Kotlin
 * 
 * This is a C-compatible wrapper around the C++ OpenPano library.
 * It provides a stable ABI that can be safely called from other languages.
 */

#ifndef OPENPANO_C_H
#define OPENPANO_C_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle types
typedef struct CStitcher CStitcher;
typedef struct CImage CImage;

// Error codes
typedef enum {
    OPENPANO_OK = 0,
    OPENPANO_ERROR_NULL_POINTER = -1,
    OPENPANO_ERROR_ADD_IMAGE = -2,
    OPENPANO_ERROR_STITCH = -3,
    OPENPANO_ERROR_SAVE = -4,
    OPENPANO_ERROR_INVALID_PATH = -5,
    OPENPANO_ERROR_OUT_OF_MEMORY = -6,
    OPENPANO_ERROR_UNKNOWN = -99
} OpenpanoError;

// Stitcher configuration
typedef struct {
    int cylinder_mode;      // 0 or 1
    int estimate_camera;    // 0 or 1
    int trans_mode;         // 0 or 1
    int ordered_input;      // 0 or 1
    int crop;               // 0 or 1
    float focal_length;     // Focal length in 35mm format
    int max_output_size;    // Maximum output dimension
} OpenpanoConfig;

/**
 * @brief Get default configuration
 */
OpenpanoConfig openpano_default_config(void);

/**
 * @brief Create a new stitcher instance
 * @param config Configuration struct (can be NULL for defaults)
 * @return Pointer to stitcher or NULL on error
 */
CStitcher* openpano_stitcher_create(const OpenpanoConfig* config);

/**
 * @brief Destroy a stitcher instance
 * @param stitcher Stitcher to destroy
 */
void openpano_stitcher_destroy(CStitcher* stitcher);

/**
 * @brief Add an image to the stitcher
 * @param stitcher Stitcher instance
 * @param path Path to image file
 * @return Error code
 */
OpenpanoError openpano_stitcher_add_image(CStitcher* stitcher, const char* path);

/**
 * @brief Stitch all added images together
 * @param stitcher Stitcher instance
 * @return Pointer to result image or NULL on error
 */
CImage* openpano_stitcher_build(CStitcher* stitcher);

/**
 * @brief Get the last error message
 * @param stitcher Stitcher instance
 * @return Error message string (owned by stitcher, don't free)
 */
const char* openpano_stitcher_last_error(CStitcher* stitcher);

// Image operations

/**
 * @brief Destroy an image
 * @param img Image to destroy
 */
void openpano_image_destroy(CImage* img);

/**
 * @brief Save image to file
 * @param img Image to save
 * @param path Output path
 * @return Error code
 */
OpenpanoError openpano_image_save(const CImage* img, const char* path);

/**
 * @brief Get image width
 * @param img Image instance
 * @return Width in pixels
 */
uint32_t openpano_image_width(const CImage* img);

/**
 * @brief Get image height
 * @param img Image instance
 * @return Height in pixels
 */
uint32_t openpano_image_height(const CImage* img);

/**
 * @brief Get image channels
 * @param img Image instance
 * @return Number of channels (typically 3 for RGB)
 */
uint32_t openpano_image_channels(const CImage* img);

/**
 * @brief Get raw image data
 * @param img Image instance
 * @return Pointer to raw pixel data (float array)
 */
const float* openpano_image_data(const CImage* img);

/**
 * @brief Get raw image data size in bytes
 * @param img Image instance
 * @return Size of data buffer
 */
size_t openpano_image_data_size(const CImage* img);

/**
 * @brief Copy image data to a buffer (as uint8_t, 0-255 range)
 * @param img Image instance
 * @param buffer Output buffer (must be pre-allocated)
 * @param buffer_size Size of output buffer
 * @return Error code
 */
OpenpanoError openpano_image_copy_to_u8(const CImage* img, uint8_t* buffer, size_t buffer_size);

#ifdef __cplusplus
}
#endif

#endif // OPENPANO_C_H

