import AVFoundation

@objc(TurboDevice)
class TurboDevice: RCTEventEmitter {
  
  var hasListeners: Bool?
#if !os(tvOS)
  let kLowBatteryThreshold: Float = 0.2
#endif
  
  override func supportedEvents() -> [String]! {
    return [
      "TurboDevice_batteryLevelDidChange",
      "TurboDevice_batteryLevelIsLow",
      "TurboDevice_powerStateDidChange",
      "TurboDevice_headphoneConnectionDidChange",
      "TurboDevice_brightnessDidChange"
    ];
  }
  
  override func constantsToExport() -> [AnyHashable : Any]! {
    let deviceId = UIDevice.identifer
    let model = UIDevice.modelName
    let brand = "Apple"
    return [
      "deviceId": deviceId,
      "model": model,
      "bundleId": bundleId,
      "systemName": systemName,
      "systemVersion": systemVersion,
      "appVersion": appVersion,
      "buildNumber": buildNumber,
      "isTablet": isTablet,
      "appName": appName,
      "brand": brand,
      "deviceType": deviceTypeName,
      "isDisplayZoomed": isDisplayZoomed,
    ];
  }
  
  override init() {
    super.init()
#if !os(tvOS)
    UIDevice.current.isBatteryMonitoringEnabled = true
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(batteryLevelDidChange),
                                           name: UIDevice.batteryLevelDidChangeNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(powerStateDidChange),
                                           name: UIDevice.batteryLevelDidChangeNotification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(powerStateDidChange),
                                           name: Notification.Name.NSProcessInfoPowerStateDidChange,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(headphoneConnectionDidChange),
                                           name: AVAudioSession.routeChangeNotification,
                                           object: AVAudioSession.sharedInstance())
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(brightnessDidChange),
                                           name: UIScreen.brightnessDidChangeNotification,
                                           object: nil)
#endif
  }
}

// MARK: - isEmulator
extension TurboDevice {
  
  @objc
  func isEmulator(_ resolve: @escaping RCTPromiseResolveBlock,
                  reject: @escaping RCTPromiseRejectBlock) {
#if targetEnvironment(simulator)
    resolve(true)
#else
    resolve(false)
#endif
  }
}

