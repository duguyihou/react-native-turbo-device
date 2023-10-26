import Foundation
// MARK: - disk
extension TurboDevice {
  @objc
  func getTotalDiskCapacity(_ resolve: @escaping RCTPromiseResolveBlock,
                                    reject: @escaping RCTPromiseRejectBlock) {
    guard let storage = getStorage() else { return reject("get total disk capacity failed", nil, nil) }
    let fileSystemSize = storage[.systemSize] as? Int ?? 0
    let totalSpace = UInt64(fileSystemSize)
    resolve(Double(totalSpace))
  }
  
  @objc
  private func getFreeDiskStorage(_ resolve: @escaping RCTPromiseResolveBlock,
                                  reject: @escaping RCTPromiseRejectBlock) {
    guard let storage = getStorage() else { return reject("get total disk capacity failed", nil, nil) }
    let fileSystemSize = storage[.systemFreeSize] as? Int ?? 0
    let freeSpace = UInt64(fileSystemSize)
    resolve(Double(freeSpace))
  }
  
  private func getStorage() -> [FileAttributeKey : Any]? {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    do {
      let storage = try FileManager.default.attributesOfFileSystem(forPath: paths.last!)
      return storage
    } catch {
      return nil
    }
  }
}

// MARK: - memory
extension TurboDevice {
  @objc
  private func getTotalMemory(_ resolve: @escaping RCTPromiseResolveBlock,
                              reject: @escaping RCTPromiseRejectBlock) {
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    resolve(Double(totalMemory))
  }
  
  @objc
  private func getUsedMemory(_ resolve: @escaping RCTPromiseResolveBlock,
                             reject: @escaping RCTPromiseRejectBlock) {
    var taskInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    if  kerr != KERN_SUCCESS {
      reject("get used memory failed", nil, nil)
    }
    resolve(UInt64(taskInfo.resident_size))
  }
}
