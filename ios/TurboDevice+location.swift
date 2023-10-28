import Foundation
import CoreLocation

extension TurboDevice {
  
  private var isLocationEnabled: Bool {
    let enabled = CLLocationManager.locationServicesEnabled()
    return enabled
  }
  
  private var availableLocationProviders: [String: Bool] {
#if !os(tvOS)
    let locationServicesEnabled = CLLocationManager.locationServicesEnabled()
    let significantLocationChangeMonitoringAvailable = CLLocationManager.significantLocationChangeMonitoringAvailable()
    let headingAvailable = CLLocationManager.headingAvailable()
    let isRangingAvailable = CLLocationManager.isRangingAvailable()
    let providers = [
      "locationServicesEnabled": locationServicesEnabled,
      "significantLocationChangeMonitoringAvailable": significantLocationChangeMonitoringAvailable,
      "headingAvailable": headingAvailable,
      "isRangingAvailable": isRangingAvailable,
    ]
    return providers
#else
    let locationServicesEnabled = isLocationEnabled()
    let providers = [
      "locationServicesEnabled": locationServicesEnabled,
    ]
    return providers
#endif
  }
  
  @objc
  func isLocationEnabled(_ resolve: @escaping RCTPromiseResolveBlock,
                         reject: @escaping RCTPromiseRejectBlock) {
    resolve(isLocationEnabled)
  }
  
  @objc
  func getAvailableLocationProviders(_ resolve: @escaping RCTPromiseResolveBlock,
                                     reject: @escaping RCTPromiseRejectBlock) {
    resolve(availableLocationProviders)
  }
}
