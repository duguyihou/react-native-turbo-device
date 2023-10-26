import Foundation

enum DeviceType: String {
  case Handset = "Handset"
  case Tablet = "Tablet"
  case Tv = "Tv"
  case Desktop = "Desktop"
  case Unknown = "Unknown"
  
  func getDeviceTypeName() -> String {
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
  func getBundleId() -> Any {
    let buildId = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier")
    return buildId ?? "unknown"
  }
  
  func getSystemName() -> Any {
    return UIDevice.current.systemName
  }
  
  func getSystemVersion() -> Any {
    return UIDevice.current.systemVersion
  }
  
  func getAppVersion() -> Any {
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
    return appVersion ?? "unknown"
  }
  
  func getBuildNumber() -> Any {
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
    return buildNumber ?? "unknown"
  }
  
  func getAppName() -> Any {
    let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")
    let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")!
    
    return displayName ?? bundleName
  }
  
  func isTablet() -> Bool {
    return getDeviceType() == .Tablet
  }
  
  func getDeviceTypeName() -> Any {
    let deviceType = getDeviceType()
    let deviceTypeName = DeviceType.getDeviceTypeName(deviceType)
    return deviceTypeName
  }
  
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
  // TODO: - 🐵 use scene
  func isDisplayZoomed() -> Bool {
    return UIScreen.main.scale != UIScreen.main.nativeScale
  }
}
