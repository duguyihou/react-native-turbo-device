import Foundation

extension TurboDevice {
  private var installerPackageName: String {
    let index = Environment.current.rawValue
    let packageName = Environment.values[index]
    return packageName!
  }
  
  @objc
  func getInstallerPackageName(_ resolve: @escaping RCTPromiseResolveBlock,
                               reject: @escaping RCTPromiseRejectBlock) {
    resolve(installerPackageName)
  }
  
  @objc
  func getFirstInstallTime(_ resolve: @escaping RCTPromiseResolveBlock,
                           reject: @escaping RCTPromiseRejectBlock) {
    guard let path = FileManager.default.urls(for:
        .documentDirectory,in:
        .userDomainMask).last
    else { return reject("getFirstInstallTime", nil, nil) }
    var installDate: Date?
    do {
      let attributesOfItem = try FileManager.default.attributesOfItem(atPath: path.absoluteString)
      installDate = attributesOfItem[.creationDate] as? Date
    } catch {
      reject("getFirstInstallTime", nil, nil)
    }
    resolve(Int64(installDate!.timeIntervalSince1970 * 1000))
  }
}
