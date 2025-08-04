// CImg iOS Configuration Header
// This file must be included before any CImg.h includes

#ifndef CIMG_IOS_CONFIG_H
#define CIMG_IOS_CONFIG_H

// Disable all image format support that requires external libraries
#define cimg_use_png 0
#define cimg_use_jpeg 0
#define cimg_use_tiff 0
#define cimg_use_openexr 0
#define cimg_use_magick 0
#define cimg_use_fftw3 0
#define cimg_use_lapack 0

// Disable system-dependent features
#define cimg_OS 0
#define cimg_display 0

// iOS compatibility
#define cimg_verbosity 0

#endif // CIMG_IOS_CONFIG_H
