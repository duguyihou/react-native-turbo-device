import AVFoundation

import MachO
import CoreLocation
#if !os(tvOS)
import WebKit
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
  
  @objc
  private func headphoneConnectionDidChange() {
    let isConnected = isHeadphonesConnected()
    sendEvent(withName: "TurboDevice_headphoneConnectionDidChange", body: [isConnected])
    
  }
  
  private func isHeadphonesConnected() -> Bool {
    let currentRoute = AVAudioSession.sharedInstance().currentRoute
    for desc in currentRoute.outputs {
      let portType = desc.portType
      if portType == .headphones || portType == .bluetoothA2DP || portType == .bluetoothHFP {
        return true
      }
    }
    return false
  }
}

// MARK: - brightness
extension TurboDevice {
  @objc
  private func brightnessDidChange() {
    let brightness = getBrightness()
    sendEvent(withName: "TurboDevice_brightnessDidChange", body: [brightness])
  }
  
  private func getBrightness() -> CGFloat {
#if !os(tvOS)
    return UIScreen.main.brightness
#else
    return CGFloat(-1)
#endif
  }
}

extension TurboDevice {
  private func getSupportedAbis() -> String {
    guard let archRaw = NXGetLocalArchInfo().pointee.name else { return "unknown" }
    return String(cString: archRaw)
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
  
  private func getFontScale() -> Double {
    let contentSize = UIScreen.main.traitCollection.preferredContentSizeCategory
    let fontScale = {
      switch contentSize {
      case .extraSmall:
        return 0.82
      case .small:
        return 0.88
      case .medium:
        return 0.95
      case .large:
        return 1.0
      case .extraLarge:
        return 1.12
      case .extraExtraLarge:
        return 1.23
      case .extraExtraExtraLarge:
        return 1.35
      case .accessibilityMedium:
        return 1.64
      case .accessibilityLarge:
        return 1.95
      case .accessibilityExtraLarge:
        return 2.35
      case .accessibilityExtraExtraLarge:
        return 2.76
      case .accessibilityExtraExtraExtraLarge:
        return 3.12
      default:
        return 1.0
      }
    }()
    return fontScale
  }
  
  private func getUserAgent() -> String {
    let userAgent = WKWebView().value(forKey: "userAgent") as! String
    return userAgent
}
}

