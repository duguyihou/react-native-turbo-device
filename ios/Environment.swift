import Foundation

enum MSACEnvironment: Int {
  case AppStore
  case TestFlight
  case Other
}

struct Environment {
  static let values = ["AppStore", "TestFlight", "Other", nil]
  static var current: MSACEnvironment {
#if targetEnvironment(simulator) || targetEnvironment(macCatalyst)
    return MSACEnvironment.Other
#else
    if hasEmbeddedMobileProvision() {
      return MSACEnvironment.Other
    }
    
    if isAppStoreReceiptSandbox() {
      return MSACEnvironment.TestFlight
    }
    return MSACEnvironment.AppStore
#endif
  }
  
  private func hasEmbeddedMobileProvision() -> Bool {
    return (Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil)
  }
  
  private func isAppStoreReceiptSandbox() -> Bool {
#if targetEnvironment(simulator)
    return false
#else
    if Bundle.main.responds(to: appStoreReceiptURL) {
      return false
    }
    let url = Bundle.main.appStoreReceiptURL
    let appStoreReceiptLastComponent = url?.lastPathComponent
    
    return appStoreReceiptLastComponent == "sandboxReceipt"
#endif
  }
}




