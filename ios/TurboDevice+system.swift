import Foundation
import DeviceCheck

enum DeviceType: String {
  case Handset = "Handset"
  case Tablet = "Tablet"
  case Tv = "Tv"
  case Desktop = "Desktop"
  case Unknown = "Unknown"
  
  func getName() -> String {
    switch self {
    case .Handset:
      return DeviceType.Handset.rawValue
    case .Tablet:
      return DeviceType.Tablet.rawValue
    case .Tv:
      return DeviceType.Tv.rawValue
    case .Desktop:
      return DeviceType.Desktop.rawValue
    default:
      return DeviceType.Unknown.rawValue
    }
  }
}

extension TurboDevice {
  var bundleId: String {
    let buildId = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String
    return buildId
  }
  
  var systemName: String {
    return UIDevice.current.systemName
  }
  
  var systemVersion: String {
    return UIDevice.current.systemVersion
  }
  
  var appVersion: String {
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    return appVersion
  }
  
  var appName: String {
    let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
    
    return displayName ?? bundleName!
  }
  
  var isTablet: Bool {
    return getDeviceType() == .Tablet
  }
  
  var deviceTypeName: String {
    let deviceType = getDeviceType()
    let deviceTypeName = DeviceType.getName(deviceType)
    return deviceTypeName()
  }
  
  // TODO: - 🐵 use scene
  var isDisplayZoomed: Bool {
    return UIScreen.main.scale != UIScreen.main.nativeScale
  }
  
  var buildNumber: String {
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
    return (buildNumber as? String) ?? "unknown"
  }
  
  var deviceName: String {
    let deviceName = UIDevice.current.name
    return deviceName
  }
  
  var buildId: String {
#if os(tvOS)
    return "unknown"
#else
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    return buildNumber
#endif
  }
}

extension TurboDevice {
  
  func getDeviceType() -> DeviceType {
    let userInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    switch userInterfaceIdiom {
    case .phone:
      return .Handset
    case .pad:
#if targetEnvironment(macCatalyst)
      return .Desktop
#endif
      if #available(iOS 14, *) {
        if ProcessInfo.processInfo.isiOSAppOnMac {
          return .Desktop
        }
      }
      return .Tablet
    case .tv:
      return .Tv
    case .mac:
      return .Desktop
    default:
      return .Unknown
    }
  }
  
  @objc
  func getDeviceToken(_ resolve: @escaping RCTPromiseResolveBlock,
                      reject: @escaping RCTPromiseRejectBlock) {
#if targetEnvironment(simulator)
    reject("NOT AVAILABLE", "Device check is only available for physical devices", nil)
    return
#else
    let isSupported = DCDevice.current.isSupported
    if isSupported {
      DCDevice.current.generateToken { token, error in
        if error != nil {
          reject("ERROR GENERATING TOKEN", error?.localizedDescription, error)
        }
        resolve(token?.base64EncodedString())
      }
    } else {
      reject("NOT SUPPORTED", "Device check is not supported by this device", nil);
    }
    
#endif
  }
  
  @objc
  func getUniqueId(_ resolve: @escaping RCTPromiseResolveBlock,
                   reject: @escaping RCTPromiseRejectBlock) {
    let uniqueId = DeviceUID().uid()
    resolve(uniqueId)
  }
  
  @objc
  func syncUniqueId(_ resolve: @escaping RCTPromiseResolveBlock,
                    reject: @escaping RCTPromiseRejectBlock) {
    let uniqueId = DeviceUID().syncUid()
    resolve(uniqueId)
  }
  
  @objc
  func getDeviceName(_ resolve: @escaping RCTPromiseResolveBlock,
                     reject: @escaping RCTPromiseRejectBlock) {
    resolve(deviceName)
  }
  
  @objc
  func getBuildNumber(_ resolve: @escaping RCTPromiseResolveBlock,
                      reject: @escaping RCTPromiseRejectBlock) {
    resolve(buildNumber)
  }
}
