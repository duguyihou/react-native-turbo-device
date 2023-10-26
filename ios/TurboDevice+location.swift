import Foundation
import CoreLocation

extension TurboDevice {
  @objc
  func isLocationEnabled(_ resolve: @escaping RCTPromiseResolveBlock,
                         reject: @escaping RCTPromiseRejectBlock) {
    let enabled = CLLocationManager.locationServicesEnabled()
    resolve(enabled)
  }
  
  @objc
  func getAvailableLocationProviders(_ resolve: @escaping RCTPromiseResolveBlock,
                                             reject: @escaping RCTPromiseRejectBlock) {
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
    resolve(providers)
#else
    let locationServicesEnabled = isLocationEnabled()
    let providers = [
      "locationServicesEnabled": locationServicesEnabled,
    ]
    resolve(providers)
#endif
  }
}
