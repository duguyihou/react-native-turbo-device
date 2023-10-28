import Foundation

extension TurboDevice {
  
  private var brightness: Float {
#if !os(tvOS)
    return Float(UIScreen.main.brightness)
#else
    return CGFloat(-1)
#endif
  }
  @objc
  func brightnessDidChange() {
    let brightness = UIScreen.main.brightness
    sendEvent(withName: "TurboDevice_brightnessDidChange", body: [brightness])
  }
  
  @objc
  func getBrightness(_ resolve: @escaping RCTPromiseResolveBlock,
                     reject: @escaping RCTPromiseRejectBlock) {
    resolve(brightness)
  }
}
