import Foundation

extension TurboDevice {
  private var userAgent: String {
    let userAgent = WKWebView().value(forKey: "userAgent") as! String
    return userAgent
  }
  
  @objc
  func getUserAgent(_ resolve: @escaping RCTPromiseResolveBlock,
                    reject: @escaping RCTPromiseRejectBlock) {
    resolve(userAgent)
  }
}
