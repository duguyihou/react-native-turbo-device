import AVFoundation
import CoreLocation
#if !os(tvOS)
import LocalAuthentication
#endif

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
    return [
      "deviceId": UIDevice.identifer,
      "model": UIDevice.modelName,
      "bundleId": getBundleId(),
      "systemName": getSystemName(),
      "systemVersion": getSystemVersion(),
      "appVersion": getAppVersion(),
      "buildNumber": getBuildNumber(),
      "isTablet": isTablet(),
      "appName": getAppName(),
      "brand": "Apple",
      "deviceType": getDeviceTypeName(),
      "isDisplayZoomed": isDisplayZoomed(),
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
  
  @objc(multiply:withB:withResolver:withRejecter:)
  func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    resolve(a*b)
  }
}

extension TurboDevice {

  private func isEmulator() -> Bool {
#if targetEnvironment(simulator)
    return true
#else
    return false
#endif
  }
}

extension TurboDevice {
  
  private func isPinOrFingerprintSet() -> Bool {
#if os(tvOS)
    return false
#else
    return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
#endif
  }
  
  private func getFirstInstallTime() -> Int64? {
    guard let path = FileManager.default.urls(for:
        .documentDirectory,in:
        .userDomainMask).last
    else { return nil }
    var installDate: Date?
    do {
      let attributesOfItem = try FileManager.default.attributesOfItem(atPath: path.absoluteString)
      installDate = attributesOfItem[.creationDate] as? Date
    } catch {
      print("🐵 ---- error")
    }
    return Int64(installDate!.timeIntervalSince1970 * 1000)
  }
  

}

