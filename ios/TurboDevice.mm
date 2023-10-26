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

# pragma mark battery

RCT_EXTERN_METHOD(getBatteryLevel:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(isBatteryCharging:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

# pragma mark network

RCT_EXTERN_METHOD(getCarrier:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getIpAddress:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

# pragma mark location

RCT_EXTERN_METHOD(isLocationEnabled:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getAvailableLocationProviders:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
@end
