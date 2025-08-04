#import <Foundation/Foundation.h>

// OpenPano result class
@interface OpenPanoStitchResult : NSObject
@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong) NSString *outputPath;
@property (nonatomic, strong) NSString *errorMessage;
@property (nonatomic, assign) NSTimeInterval processingTime;
@end

// Main wrapper class
@interface OpenPanoWrapper : NSObject
+ (NSString *)getVersion;
+ (BOOL)initConfig;
+ (OpenPanoStitchResult *)stitchImages:(NSArray<NSString *> *)imagePaths outputPath:(NSString *)outputPath;
+ (NSString *)getSystemInfo;
+ (BOOL)isLibraryReady;
@end

// Framework main class
@interface OpenPanoFramework : NSObject
+ (NSString *)version;
+ (BOOL)initialize;
@end
