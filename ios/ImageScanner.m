#import <React/RCTBridgeModule.h>
#import <React/RCTLog.h>

@interface RCT_EXTERN_MODULE(ImageScanner, NSObject)

RCT_EXTERN_METHOD(process:(NSString *)uri
                  options:(NSArray *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
