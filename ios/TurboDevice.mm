#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(TurboDevice, NSObject)

RCT_EXTERN_METHOD(multiply:(float)a withB:(float)b
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

# pragma mark storage

RCT_EXTERN_METHOD(getTotalDiskCapacity:(RCTPromiseResolveBlock)resolve 
                  reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getFreeDiskStorage:(RCTPromiseResolveBlock)resolve 
                  reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getTotalMemory:(RCTPromiseResolveBlock)resolve 
                  reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getUsedMemory:(RCTPromiseResolveBlock)resolve 
                  reject:(RCTPromiseRejectBlock)reject)

@end
