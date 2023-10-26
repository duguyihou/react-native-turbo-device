import Foundation

extension TurboDevice {
  @objc
  func getUserAgent(_ resolve: @escaping RCTPromiseResolveBlock,
                    reject: @escaping RCTPromiseRejectBlock) {
    let userAgent = WKWebView().value(forKey: "userAgent") as! String
    resolve(userAgent)
  }
}
