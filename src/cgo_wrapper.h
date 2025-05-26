#ifndef CGO_WRAPPER_H
#define CGO_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Structure to return stitching result
typedef struct {
    unsigned char* data;  // RGB image data
    int width;
    int height;
    int channels;
    int success;          // 1 for success, 0 for failure
    char* error_message;  // Error message if failed
} StitchResult;

// Function to stitch images from file paths
StitchResult* stitch_images(char** image_paths, int num_images, const char* output_path);

// Function to free the result
void free_stitch_result(StitchResult* result);

// Function to initialize the stitcher configuration
int init_stitcher_config(const char* config_file_path);

#ifdef __cplusplus
}
#endif

#endif // CGO_WRAPPER_H
