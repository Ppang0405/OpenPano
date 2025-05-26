#include "cgo_wrapper.h"
#include <iostream>
#include <vector>
#include <string>
#include <memory>
#include <cstring>
#include <exception>

// Include necessary OpenPano headers
#include "lib/config.hh"
#include "lib/timer.hh"
#include "lib/imgproc.hh"
#include "stitch/stitcher.hh"
#include "stitch/cylstitcher.hh"
#include "common/common.hh"

using namespace std;
using namespace pano;
using namespace config;

// Global flag to track initialization
static bool g_initialized = false;

extern "C" {

int init_stitcher_config(const char* config_file_path) {
    try {
        // Initialize random seed
        srand(time(NULL));
        
        // Load configuration
        const char* config_file = config_file_path ? config_file_path : "config.cfg";
        ConfigParser Config(config_file);
        
        // Set all configuration variables (same as init_config() in main.cc)
        #define CFG(x) x = Config.get(#x)
        
        CFG(CYLINDER);
        CFG(TRANS);
        CFG(ESTIMATE_CAMERA);
        
        if (int(CYLINDER) + int(TRANS) + int(ESTIMATE_CAMERA) >= 2) {
            return 0; // Too many modes set
        }
        
        CFG(ORDERED_INPUT);
        if (!ORDERED_INPUT && !ESTIMATE_CAMERA) {
            return 0; // Require ORDERED_INPUT under this mode
        }
        
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
        CFG(LM_LAMBDA);
        CFG(MULTIPASS_BA);
        CFG(MULTIBAND);
        
        #undef CFG
        
        g_initialized = true;
        return 1; // Success
    } catch (const exception& e) {
        return 0; // Failure
    }
}

StitchResult* stitch_images(char** image_paths, int num_images, const char* output_path) {
    StitchResult* result = new StitchResult();
    result->data = nullptr;
    result->width = 0;
    result->height = 0;
    result->channels = 3;
    result->success = 0;
    result->error_message = nullptr;
    
    try {
        // Initialize if not already done
        if (!g_initialized) {
            if (!init_stitcher_config(nullptr)) {
                result->error_message = strdup("Failed to initialize configuration");
                return result;
            }
        }
        
        if (num_images < 2) {
            result->error_message = strdup("Need at least two images to stitch");
            return result;
        }
        
        // Convert image paths to vector of strings
        vector<string> imgs;
        for (int i = 0; i < num_images; i++) {
            imgs.emplace_back(image_paths[i]);
        }
        
        // Create stitcher and build panorama
        Mat32f res;
        TotalTimerGlobalGuard timer_guard;
        
        if (CYLINDER) {
            CylinderStitcher stitcher(move(imgs));
            res = stitcher.build();
        } else {
            Stitcher stitcher(move(imgs));
            res = stitcher.build();
        }
        
        // Apply cropping if enabled
        if (CROP) {
            res = crop(res);
        }
        
        // Convert Mat32f to RGB data
        int width = res.width();
        int height = res.height();
        int channels = 3;
        
        // Allocate memory for image data
        unsigned char* data = new unsigned char[width * height * channels];
        
        // Convert float values to unsigned char (0-255)
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                float* pixel = res.ptr(y, x);
                int idx = (y * width + x) * channels;
                
                // Convert from float [0,1] to unsigned char [0,255]
                // Handle potential negative values (Color::NO)
                for (int c = 0; c < channels; c++) {
                    if (pixel[c] < 0) {
                        data[idx + c] = 0; // Black for missing areas
                    } else {
                        int val = (int)(pixel[c] * 255.0f + 0.5f);
                        data[idx + c] = (unsigned char)max(0, min(255, val));
                    }
                }
            }
        }
        
        // Write output file if path provided
        if (output_path) {
            try {
                write_rgb(output_path, res);
            } catch (const exception& e) {
                // Continue even if file write fails
                result->error_message = strdup(("Warning: Failed to write output file: " + string(e.what())).c_str());
            }
        }
        
        // Set result data
        result->data = data;
        result->width = width;
        result->height = height;
        result->channels = channels;
        result->success = 1;
        
        return result;
        
    } catch (const exception& e) {
        result->error_message = strdup(e.what());
        return result;
    } catch (...) {
        result->error_message = strdup("Unknown error occurred during stitching");
        return result;
    }
}

void free_stitch_result(StitchResult* result) {
    if (result) {
        if (result->data) {
            delete[] result->data;
        }
        if (result->error_message) {
            free(result->error_message);
        }
        delete result;
    }
}

} // extern "C"
