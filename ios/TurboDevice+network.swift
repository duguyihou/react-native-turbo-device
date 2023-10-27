import Foundation
import CoreTelephony

extension TurboDevice {
  private var carrier: String {
#if os(tvOS) || targetEnvironment(macCatalyst)
    return "unknown"
#else
    let netInfo = CTTelephonyNetworkInfo()
    if #available(iOS 12.0, *) {
      return netInfo.serviceSubscriberCellularProviders?.first?.value.carrierName ?? "unknown"
    } else {
      return netInfo.subscriberCellularProvider?.carrierName ?? "unknown"
    }
#endif
    
  }
  func getCarrier(_ resolve: @escaping RCTPromiseResolveBlock,
                  reject: @escaping RCTPromiseRejectBlock) {
    resolve(carrier)
  }
  
  // copy from https://stackoverflow.com/a/73853838
  func getIpAddress(_ resolve: @escaping RCTPromiseResolveBlock,
                    reject: @escaping RCTPromiseRejectBlock) {
    var address : String?
    
    var ifaddr : UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return reject("getIpAddress failed", nil, nil) }
    guard let firstAddr = ifaddr else { return reject("getIpAddress failed", nil, nil) }
    
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
    
    resolve(address)
  }
}
