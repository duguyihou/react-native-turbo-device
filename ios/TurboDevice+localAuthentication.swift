import Foundation
#if !os(tvOS)
import LocalAuthentication
#endif

extension TurboDevice {
  private func isPinOrFingerprintSet(_ resolve: @escaping RCTPromiseResolveBlock,
                                     reject: @escaping RCTPromiseRejectBlock) {
#if os(tvOS)
    resolve(false)
#else
    let evaluated = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    resolve(evaluated)
#endif
  }
}
