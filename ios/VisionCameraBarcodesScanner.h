#ifndef VisionCameraBarcodesScanner_h
#define VisionCameraBarcodesScanner_h

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface VisionCameraBarcodesScanner : RCTEventEmitter <RCTBridgeModule>
+ (NSString*)name;
@end

#endif /* VisionCameraBarcodesScanner_h */
