import Foundation
import MachO

extension TurboDevice {
  private func getSupportedAbis(_ resolve: @escaping RCTPromiseResolveBlock,
                                reject: @escaping RCTPromiseRejectBlock) {
    guard let archRaw = NXGetLocalArchInfo().pointee.name else { return resolve("unknown") }
    resolve(String(cString: archRaw))
  }
}
