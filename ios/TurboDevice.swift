import AVFoundation
import CoreTelephony
import MachO
import CoreLocation
#if !os(tvOS)
import WebKit
import LocalAuthentication
#endif

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

@objc(TurboDevice)
class TurboDevice: RCTEventEmitter {
  
  var hasListeners: Bool?
#if !os(tvOS)
  let lowBatteryThreshold: Float = 0.2
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
  private func getBundleId() -> Any {
    let buildId = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier")
    return buildId ?? "unknown"
  }
  
  private func getSystemName() -> Any {
    return UIDevice.current.systemName
  }
  
  private func getSystemVersion() -> Any {
    return UIDevice.current.systemVersion
  }
  private func getAppVersion() -> Any {
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
    return appVersion ?? "unknown"
  }
  
  private func getBuildNumber() -> Any {
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
    return buildNumber ?? "unknown"
  }
  
  private func isTablet() -> Bool {
    return getDeviceType() == .Tablet
  }
  
  private func isEmulator() -> Bool {
#if targetEnvironment(simulator)
    return true
#else
    return false
#endif
  }
  
  private func getAppName() -> Any {
    let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")
    let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")!
    
    return displayName ?? bundleName
  }
  
  private func getDeviceTypeName() -> Any {
    let deviceType = getDeviceType()
    let deviceTypeName = DeviceType.getDeviceTypeName(deviceType)
    return deviceTypeName
  }
  
  // TODO: - 🐵 use scene
  private func isDisplayZoomed() -> Bool {
    return UIScreen.main.scale != UIScreen.main.nativeScale
  }
}

// MARK: - battery
extension TurboDevice {
  
  var powerState: [String:Any] {
    
#if RCT_DEV && !targetEnvironment(simulator) && !os(tvOS)
    if !UIDevice.current.isBatteryMonitoringEnabled {
      RCTLogWarn("Battery monitoring is not enabled. You need to enable monitoring with `UIDevice.current.isBatteryMonitoringEnabled = true`")
    }
#endif
#if RCT_DEV && targetEnvironment(simulator) && !os(tvOS)
    if UIDevice.current.batteryState == .unknown {
      RCTLogWarn("Battery state `unknown` and monitoring disabled, this is normal for simulators and tvOS.")
    }
#endif
    let batteryLevel = getBatteryLevel()
#if os(tvOS)
    return [
      "batteryLevel": batteryLevel,
      "batteryState": "full"
    ]
#else
    let batteryState = {
      let state = UIDevice.current.batteryState
      switch state {
      case .full:
        return "full"
      case .charging:
        return "charging"
      case .unplugged:
        return "unplugged"
      default:
        return "unknown"
      }
    }()
    let lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    return [
      "batteryLevel": batteryLevel,
      "batteryState": batteryState,
      "lowPowerMode": lowPowerMode,
    ]
#endif
  }
  @objc
  private func batteryLevelDidChange(_ notification: Notification) {
    let batteryLevel = getBatteryLevel()
    sendEvent(withName: "TurboDevice_batteryLevelDidChange", body: [batteryLevel])
    
    if batteryLevel <= lowBatteryThreshold {
      sendEvent(withName: "TurboDevice_batteryLevelIsLow", body: [batteryLevel])
    }
  }
  
  private func getBatteryLevel() -> Float {
#if os(tvOS)
    return Float(1)
#else
    return UIDevice.current.batteryLevel
#endif
  }
  
  @objc
  private func powerStateDidChange() {
    sendEvent(withName: "TurboDevice_powerStateDidChange", body: [powerState])
  }
  
  @objc
  private func headphoneConnectionDidChange() {
    let isConnected = isHeadphonesConnected()
    sendEvent(withName: "TurboDevice_headphoneConnectionDidChange", body: [isConnected])
    
  }
  
  @objc
  private func isBatteryCharging() -> Bool {
    return powerState["batteryState"] as! UIDevice.BatteryState == .charging
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

// MARK: - storage
extension TurboDevice {
  
  private func getTotalDiskCapacity() -> Double {
    let storage = getStorage()
    let fileSystemSize = storage[.systemSize] as! Int
    let totalSpace = UInt64(fileSystemSize)
    return Double(totalSpace)
  }
  
  private func getFreeDiskStorage() -> Double {
    let storage = getStorage()
    let fileSystemSize = storage[.systemFreeSize] as! Int
    let freeSpace = UInt64(fileSystemSize)
    return Double(freeSpace)
  }
  
  private func getTotalMemory() -> Double {
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    return Double(totalMemory)
  }
  private func getUsedMemory() -> UInt64 {
    // TODO: - 🐵 todo
    return UInt64()
  }
  
  private func getStorage() -> [FileAttributeKey : Any] {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let storage = try! FileManager.default.attributesOfFileSystem(forPath: paths.last!)
    // TODO: - 🐵 catch
    return storage
  }
}

extension TurboDevice {
  private func getSupportedAbis() -> [String] {
    let archInfo = NXGetLocalArchInfo() // MARK: - deprecated in iOS 16
    // TODO: - 🐵 todo
    return [""]
  }
  
  
}
// MARK: - location
extension TurboDevice {
  private func isLocationEnabled() -> Bool {
    return CLLocationManager.locationServicesEnabled()
  }
  private func getAvailableLocationProviders() -> [String: Any] {
#if !os(tvOS)
    let locationServicesEnabled = isLocationEnabled()
    let significantLocationChangeMonitoringAvailable = CLLocationManager.significantLocationChangeMonitoringAvailable()
    let headingAvailable = CLLocationManager.headingAvailable()
    let isRangingAvailable = CLLocationManager.isRangingAvailable()
    return [
      "locationServicesEnabled": locationServicesEnabled,
      "significantLocationChangeMonitoringAvailable": significantLocationChangeMonitoringAvailable,
      "headingAvailable": headingAvailable,
      "isRangingAvailable": isRangingAvailable,
    ]
#else
    let locationServicesEnabled = isLocationEnabled()
    return [
      "locationServicesEnabled": locationServicesEnabled,
    ]
#endif
  }
}

extension TurboDevice {
  private func getCarrier() -> String {
    
#if os(tvOS) || targetEnvironment(macCatalyst)
    return "unknown"
#else
    let netInfo = CTTelephonyNetworkInfo()
    if #available(iOS 12.0, *) {
      return  netInfo.serviceSubscriberCellularProviders?["home"]?.carrierName ?? "unknown" // TODO: - 🐵 not sure home
    } else {
      return netInfo.subscriberCellularProvider?.carrierName ?? "unknown"
    }
#endif
  }
}
extension TurboDevice {
  private func getDeviceType() -> DeviceType {
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
  
  private func isPinOrFingerprintSet() -> Bool {
    #if os(tvOS)
    return false
    #else
    let context = LAContext()
    return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    #endif
  }
  
  private func getFirstInstallTime() {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    let path = String(url)
    let installDate: Date = FileManager.default.attributesOfItem(atPath: path)[.creationDate]
    
    return installDate.timeIntervalSince1970 * 1000
  }
}
