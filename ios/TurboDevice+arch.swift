import Foundation
import MachO

extension TurboDevice {
  
  private var supportedAbis: String {
    guard let archRaw = NXGetLocalArchInfo().pointee.name else { return "unknown" }
    return String(cString: archRaw)
  }
  
  @objc
  func getSupportedAbis(_ resolve: @escaping RCTPromiseResolveBlock,
                        reject: @escaping RCTPromiseRejectBlock) {
    resolve(supportedAbis)
  }
}
