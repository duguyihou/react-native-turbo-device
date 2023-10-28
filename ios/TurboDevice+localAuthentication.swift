import Foundation
#if !os(tvOS)
import LocalAuthentication
#endif

extension TurboDevice {
  private var isPinOrFingerprintSet: Bool {
#if os(tvOS)
    return false
#else
    let evaluated = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    return evaluated
#endif
  }
  
  @objc
  func isPinOrFingerprintSet(_ resolve: @escaping RCTPromiseResolveBlock,
                             reject: @escaping RCTPromiseRejectBlock) {
    resolve(isPinOrFingerprintSet)
  }
}
