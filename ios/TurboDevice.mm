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
                  reject:(RCTPromiseRejectBlock)reject)

# pragma mark network

RCT_EXTERN_METHOD(getCarrier:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getIpAddress:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

# pragma mark location

RCT_EXTERN_METHOD(isLocationEnabled:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getAvailableLocationProviders:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

# pragma mark headphone

RCT_EXTERN_METHOD(isHeadphonesConnected:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

# pragma mark brightness

RCT_EXTERN_METHOD(getBrightness:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

# pragma mark typography

RCT_EXTERN_METHOD(getFontScale:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

# pragma mark web

RCT_EXTERN_METHOD(getUserAgent:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

# pragma mark arch

RCT_EXTERN_METHOD(getSupportedAbis:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

# pragma mark localAuthentication

RCT_EXTERN_METHOD(isPinOrFingerprintSet:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)


@end
