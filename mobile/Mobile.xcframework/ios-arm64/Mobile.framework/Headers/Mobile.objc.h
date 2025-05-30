// Objective-C API for talking to openpano-mobile Go package.
//   gobind -lang=objc openpano-mobile
//
// File is generated by gobind. Do not edit.

#ifndef __Mobile_H__
#define __Mobile_H__

@import Foundation;
#include "ref.h"
#include "Universe.objc.h"


@class MobileMobileStitchResult;

/**
 * MobileStitchResult represents the result of image stitching for mobile platforms
 */
@interface MobileMobileStitchResult : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
@property (nonatomic) long width;
@property (nonatomic) long height;
@property (nonatomic) long channels;
@property (nonatomic) BOOL success;
@property (nonatomic) NSString* _Nonnull error;
/**
 * Base64 encoded image data for easy transfer to mobile platforms
 */
@property (nonatomic) NSString* _Nonnull base64Data;
/**
 * File path where the result was saved
 */
@property (nonatomic) NSString* _Nonnull outputPath;
@end

/**
 * GetTestImagePaths returns paths to test images (for testing on mobile)
 */
FOUNDATION_EXPORT NSString* _Nonnull MobileGetTestImagePaths(void);

/**
 * Greetings returns a greeting message (for testing mobile binding)
 */
FOUNDATION_EXPORT NSString* _Nonnull MobileGreetings(NSString* _Nullable name);

/**
 * StitchImagesFromBase64 stitches images from base64 encoded data
This is useful for mobile apps that work with image data directly
 */
FOUNDATION_EXPORT MobileMobileStitchResult* _Nullable MobileStitchImagesFromBase64(NSString* _Nullable image1Base64, NSString* _Nullable image2Base64, NSString* _Nullable outputPath);

/**
 * StitchImagesFromPaths stitches images from file paths
This is a mobile-friendly interface that takes image file paths
 */
FOUNDATION_EXPORT MobileMobileStitchResult* _Nullable MobileStitchImagesFromPaths(NSString* _Nullable imagePath1, NSString* _Nullable imagePath2, NSString* _Nullable outputPath);

/**
 * ValidateEnvironment checks if the mobile environment is set up correctly
 */
FOUNDATION_EXPORT MobileMobileStitchResult* _Nullable MobileValidateEnvironment(void);

/**
 * Version returns the version of the mobile OpenPano library
 */
FOUNDATION_EXPORT NSString* _Nonnull MobileVersion(void);

#endif
