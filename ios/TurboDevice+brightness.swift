import Foundation

extension TurboDevice {
  @objc
  func brightnessDidChange() {
    let brightness = UIScreen.main.brightness
    sendEvent(withName: "TurboDevice_brightnessDidChange", body: [brightness])
  }
  
  @objc
  func getBrightness(_ resolve: @escaping RCTPromiseResolveBlock,
                     reject: @escaping RCTPromiseRejectBlock) {
#if !os(tvOS)
    resolve(UIScreen.main.brightness)
#else
    resolve(CGFloat(-1))
#endif
  }
}
