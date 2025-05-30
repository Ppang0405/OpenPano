// Objective-C API for talking to openpano-mobile Go package.
//   gobind -lang=objc openpano-mobile
//
// File is generated by gobind. Do not edit.

#ifndef __Openpano_H__
#define __Openpano_H__

@import Foundation;
#include "ref.h"
#include "Universe.objc.h"


@class OpenpanoStitchResult;

/**
 * StitchResult represents the result of image stitching
 */
@interface OpenpanoStitchResult : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
@property (nonatomic) NSData* _Nullable data;
@property (nonatomic) long width;
@property (nonatomic) long height;
@property (nonatomic) long channels;
@property (nonatomic) BOOL success;
@property (nonatomic) NSString* _Nonnull error;
@end

// skipped function CreateStitcher with unsupported parameter or return types


/**
 * Get Version of the library
 */
FOUNDATION_EXPORT NSString* _Nonnull OpenpanoGetVersion(void);

FOUNDATION_EXPORT NSString* _Nonnull OpenpanoGreetings(NSString* _Nullable name);

/**
 * InitConfig initializes the stitcher configuration
 */
FOUNDATION_EXPORT BOOL OpenpanoInitConfig(NSString* _Nullable configPath);

// skipped function StitchImages with unsupported parameter or return types


#endif
