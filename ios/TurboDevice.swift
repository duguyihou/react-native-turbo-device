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
    
    if batteryLevel <= kLowBatteryThreshold {
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
  private func getTotalMemory() -> Double {
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    return Double(totalMemory)
  }
  private func getUsedMemory() -> UInt64 {
    var taskInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    if  kerr != KERN_SUCCESS {
      return 0
    }
    return UInt64(taskInfo.resident_size)
  }
}

extension TurboDevice {
  private func getSupportedAbis() -> String {
    guard let archRaw = NXGetLocalArchInfo().pointee.name else { return "unknown" }
    return String(cString: archRaw)
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
      return  netInfo.serviceSubscriberCellularProviders?.first?.value.carrierName ?? "unknown"
    } else {
      return netInfo.subscriberCellularProvider?.carrierName ?? "unknown"
    }
#endif
  }
  // copy from https://stackoverflow.com/a/73853838
  private func getIpAddress() -> String? {
    var address : String?
    
    var ifaddr : UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return nil }
    guard let firstAddr = ifaddr else { return nil }
    
    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
      let interface = ifptr.pointee
      
      let addrFamily = interface.ifa_addr.pointee.sa_family
      if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
        
        // Check interface name:
        // wifi = ["en0"]
        // wired = ["en2", "en3", "en4"]
        // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
        let name = String(cString: interface.ifa_name)
        if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
          var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
          getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                      &hostname, socklen_t(hostname.count),
                      nil, socklen_t(0), NI_NUMERICHOST)
          address = String(cString: hostname)
        }
      }
    }
    freeifaddrs(ifaddr)
    
    return address
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
  
  private func getBuildId() -> String {
    #if os(tvOS)
    return "unknown"
    #else
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    return buildNumber
    #endif
  }
  
  private func getUserAgent() -> String {
    let userAgent = WKWebView().value(forKey: "userAgent") as! String
    return userAgent
}
}

