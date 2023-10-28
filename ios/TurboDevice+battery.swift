import Foundation

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
    let batteryLevel = UIDevice.current.batteryLevel
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
  
  var batteryLevel: Float {
#if os(tvOS)
    return Float(1)
#else
    return UIDevice.current.batteryLevel
#endif
  }
  
  @objc
  func batteryLevelDidChange(_ notification: Notification) {
    sendEvent(withName: "TurboDevice_batteryLevelDidChange", body: [batteryLevel])
    
    if batteryLevel <= kLowBatteryThreshold {
      sendEvent(withName: "TurboDevice_batteryLevelIsLow", body: [batteryLevel])
    }
  }
  
  @objc
  private func getBatteryLevel(_ resolve: @escaping RCTPromiseResolveBlock,
                               reject: @escaping RCTPromiseRejectBlock) {
    resolve(batteryLevel)
  }
  
  @objc
  func powerStateDidChange() {
    sendEvent(withName: "TurboDevice_powerStateDidChange", body: [powerState])
  }
  
  @objc
  func isBatteryCharging(_ resolve: @escaping RCTPromiseResolveBlock,
                         reject: @escaping RCTPromiseRejectBlock) {
    guard let batteryState = powerState["batteryState"] as? UIDevice.BatteryState
    else { return reject("isBatteryCharging failed", nil, nil)}
    let isCharging = batteryState == .charging
    resolve(isCharging)
  }
  
  @objc
  func getPowerState(_ resolve: @escaping RCTPromiseResolveBlock,
                     reject: @escaping RCTPromiseRejectBlock) {
    resolve(powerState)
  }
}
