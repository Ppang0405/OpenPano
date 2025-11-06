/**
 * @file openpano_c.cc
 * @brief C API implementation for OpenPano
 */

#include "openpano_c.h"
#include "../stitch/stitcher.hh"
#include "../stitch/cylstitcher.hh"
#include "../lib/config.hh"
#include "../lib/imgproc.hh"
#include <vector>
#include <string>
#include <memory>
#include <cstring>
#include <algorithm>
#include <iostream>
#include <ctime>
#include <cstdlib>

using namespace pano;

// Load full configuration from config.cfg like main.cc does
static void load_config_from_file() {
    using namespace config;
    
    const char* config_file = "config.cfg";
    ConfigParser Config(config_file);
    
    #define CFG(x) x = Config.get(#x)
    
    CFG(CYLINDER);
    CFG(TRANS);
    CFG(ESTIMATE_CAMERA);
    CFG(ORDERED_INPUT);
    CFG(CROP);
    CFG(STRAIGHTEN);
    CFG(FOCAL_LENGTH);
    CFG(MAX_OUTPUT_SIZE);
    CFG(LAZY_READ);
    
    CFG(SIFT_WORKING_SIZE);
    CFG(NUM_OCTAVE);
    CFG(NUM_SCALE);
    CFG(SCALE_FACTOR);
    CFG(GAUSS_SIGMA);
    CFG(GAUSS_WINDOW_FACTOR);
    CFG(JUDGE_EXTREMA_DIFF_THRES);
    CFG(CONTRAST_THRES);
    CFG(PRE_COLOR_THRES);
    CFG(EDGE_RATIO);
    CFG(CALC_OFFSET_DEPTH);
    CFG(OFFSET_THRES);
    CFG(ORI_RADIUS);
    CFG(ORI_HIST_SMOOTH_COUNT);
    CFG(DESC_HIST_SCALE_FACTOR);
    CFG(DESC_INT_FACTOR);
    
    CFG(MATCH_REJECT_NEXT_RATIO);
    CFG(RANSAC_ITERATIONS);
    CFG(RANSAC_INLIER_THRES);
    CFG(INLIER_IN_MATCH_RATIO);
    CFG(INLIER_IN_POINTS_RATIO);
    CFG(SLOPE_PLAIN);
    
    CFG(MULTIPASS_BA);
    CFG(MULTIBAND);
    
    #undef CFG
}

// Internal structures
struct CStitcher {
    std::vector<std::string> image_paths;
    OpenpanoConfig config;
    std::string last_error;
    
    CStitcher(const OpenpanoConfig& cfg) : config(cfg) {}
};

struct CImage {
    Mat32f data;
    
    explicit CImage(Mat32f&& mat) : data(std::move(mat)) {}
};

// Helper to set config values
static void apply_config(const OpenpanoConfig* config) {
    if (!config) return;
    
    config::CYLINDER = config->cylinder_mode;
    config::ESTIMATE_CAMERA = config->estimate_camera;
    config::TRANS = config->trans_mode;
    config::ORDERED_INPUT = config->ordered_input;
    config::CROP = config->crop;
    config::FOCAL_LENGTH = config->focal_length;
    config::MAX_OUTPUT_SIZE = config->max_output_size;
}

extern "C" {

OpenpanoConfig openpano_default_config(void) {
    OpenpanoConfig config;
    config.cylinder_mode = 0;
    config.estimate_camera = 1;
    config.trans_mode = 0;
    config.ordered_input = 0;
    config.crop = 1;
    config.focal_length = 37.0f;
    config.max_output_size = 8000;
    return config;
}

CStitcher* openpano_stitcher_create(const OpenpanoConfig* config) {
    try {
        OpenpanoConfig cfg = config ? *config : openpano_default_config();
        return new CStitcher(cfg);
    } catch (const std::exception& e) {
        return nullptr;
    } catch (...) {
        return nullptr;
    }
}

void openpano_stitcher_destroy(CStitcher* stitcher) {
    delete stitcher;
}

OpenpanoError openpano_stitcher_add_image(CStitcher* stitcher, const char* path) {
    if (!stitcher) return OPENPANO_ERROR_NULL_POINTER;
    if (!path) return OPENPANO_ERROR_INVALID_PATH;
    
    try {
        stitcher->image_paths.emplace_back(path);
        return OPENPANO_OK;
    } catch (const std::exception& e) {
        stitcher->last_error = e.what();
        return OPENPANO_ERROR_ADD_IMAGE;
    } catch (...) {
        stitcher->last_error = "Unknown error adding image";
        return OPENPANO_ERROR_ADD_IMAGE;
    }
}

CImage* openpano_stitcher_build(CStitcher* stitcher) {
    if (!stitcher) return nullptr;
    if (stitcher->image_paths.size() < 2) {
        stitcher->last_error = "Need at least 2 images to stitch";
        return nullptr;
    }
    
    try {
        // Initialize random seed for RANSAC (same as main.cc)
        std::srand(std::time(NULL));
        
        // Load full configuration from config.cfg (including SIFT parameters!)
        load_config_from_file();
        
        // Then override with user-provided settings
        apply_config(&stitcher->config);
        
        // Copy paths because stitcher moves them
        std::vector<std::string> paths = stitcher->image_paths;
        
        Mat32f result;
        if (stitcher->config.cylinder_mode) {
            CylinderStitcher s(std::move(paths));
            result = s.build();
        } else {
            Stitcher s(std::move(paths));
            result = s.build();
        }
        
        // Crop if requested
        if (stitcher->config.crop) {
            result = crop(result);
        }
        
        return new CImage(std::move(result));
    } catch (const std::exception& e) {
        stitcher->last_error = std::string("Stitching failed: ") + e.what();
        return nullptr;
    } catch (...) {
        stitcher->last_error = "Unknown error during stitching";
        return nullptr;
    }
}

const char* openpano_stitcher_last_error(CStitcher* stitcher) {
    if (!stitcher) return "Invalid stitcher pointer";
    return stitcher->last_error.c_str();
}

void openpano_image_destroy(CImage* img) {
    delete img;
}

OpenpanoError openpano_image_save(const CImage* img, const char* path) {
    if (!img) return OPENPANO_ERROR_NULL_POINTER;
    if (!path) return OPENPANO_ERROR_INVALID_PATH;
    
    try {
        write_rgb(path, img->data);
        return OPENPANO_OK;
    } catch (const std::exception& e) {
        return OPENPANO_ERROR_SAVE;
    } catch (...) {
        return OPENPANO_ERROR_SAVE;
    }
}

uint32_t openpano_image_width(const CImage* img) {
    return img ? img->data.width() : 0;
}

uint32_t openpano_image_height(const CImage* img) {
    return img ? img->data.height() : 0;
}

uint32_t openpano_image_channels(const CImage* img) {
    return img ? img->data.channels() : 0;
}

const float* openpano_image_data(const CImage* img) {
    return img ? img->data.ptr() : nullptr;
}

size_t openpano_image_data_size(const CImage* img) {
    if (!img) return 0;
    return img->data.width() * img->data.height() * img->data.channels() * sizeof(float);
}

OpenpanoError openpano_image_copy_to_u8(const CImage* img, uint8_t* buffer, size_t buffer_size) {
    if (!img || !buffer) return OPENPANO_ERROR_NULL_POINTER;
    
    const size_t w = img->data.width();
    const size_t h = img->data.height();
    const size_t c = img->data.channels();
    const size_t required_size = w * h * c;
    
    if (buffer_size < required_size) {
        return OPENPANO_ERROR_UNKNOWN;
    }
    
    const float* src = img->data.ptr();
    for (size_t i = 0; i < required_size; ++i) {
        // Clamp to [0, 1] and convert to [0, 255]
        float val = std::max(0.0f, std::min(1.0f, src[i]));
        buffer[i] = static_cast<uint8_t>(val * 255.0f);
    }
    
    return OPENPANO_OK;
}

} // extern "C"

