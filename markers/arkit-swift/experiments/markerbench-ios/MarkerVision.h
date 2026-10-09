#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
NS_ASSUME_NONNULL_BEGIN
@interface MarkerVision : NSObject
+ (NSArray<NSDictionary *> *)detect:(CVPixelBufferRef)buffer mode:(NSString *)mode fx:(double)fx fy:(double)fy cx:(double)cx cy:(double)cy extent:(double)extent;
@end
NS_ASSUME_NONNULL_END
