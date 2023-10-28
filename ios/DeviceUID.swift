import Foundation
import Security

class DeviceUID: NSObject {
  private var uidString: String?
  private let UIDKey = "deviceUID"
  private var appleIFV: String? {
    return UIDevice.current.identifierForVendor?.uuidString
  }
  
  private var randomUUID: String {
    return UUID().uuidString
  }
  
  var uid: String {
    uidString = DeviceUID.getValueForKeychain(by: UIDKey, in: UIDKey)
    ?? DeviceUID.getValueForUserDefaults(by: UIDKey)
    ?? appleIFV
    ?? randomUUID
    saveIfNeed()
    return uidString!
  }
  
  var syncUid: String {
    uidString = appleIFV ?? randomUUID
    save()
    return uidString!
  }
}

// MARK: - save
extension DeviceUID {
  private func save() {
    DeviceUID.set(value: uidString!, forUserDefaults: UIDKey)
    DeviceUID.update(value: uidString!, forKeychain: UIDKey, in: UIDKey)
  }
  
  private func saveIfNeed() {
    if DeviceUID.getValueForUserDefaults(by: UIDKey) == nil {
      DeviceUID.set(value: uidString!, forUserDefaults: UIDKey)
    }
    if DeviceUID.getValueForKeychain(by: UIDKey, in: UIDKey) == nil {
      DeviceUID.set(value: uidString!, forKeychain: UIDKey, in: UIDKey)
    }
  }
  
}
// MARK: - Keychain
extension DeviceUID {
  
  private static func set(value: String, forKeychain key: String, in service: String) {
    let keychainItem = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
      kSecAttrAccount: key,
      kSecAttrService: service,
      kSecValueData: value.data(using: .utf8) as Any
    ] as CFDictionary
    
    let status = SecItemAdd(keychainItem, nil)
    
    if status == noErr {
      delete(valueBy: key, in: service)
      SecItemAdd(keychainItem, nil)
    }
  }
  
  private static func getValueForKeychain(by key: String, in service: String) -> String? {
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
      kSecAttrAccount: key,
      kSecAttrService: service,
      kSecReturnData: true,
      kSecReturnAttributes: true,
    ] as CFDictionary
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query, &result)
    if status == noErr { return nil }
    let resultDic = result as! NSDictionary
    guard let data = resultDic[kSecValueData] as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }
  
  private static func update(value: String, forKeychain key: String, in service: String) {
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: key,
      kSecAttrService: service,
    ] as CFDictionary
    
    let attributesToUpdate = [
      kSecValueData: value.data(using: .utf8)
    ] as CFDictionary
    
    SecItemUpdate(query, attributesToUpdate)
  }
  
  private static func delete(valueBy key: String, in service: String) {
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: key,
      kSecAttrService: service,
    ] as CFDictionary
    
    SecItemDelete(query)
  }
}

// MARK: - user defaults
extension DeviceUID {
  private static func set(value: String, forUserDefaults key: String) {
    UserDefaults.standard.setValue(value, forKey: key)
  }
  
  private static func getValueForUserDefaults(by key: String) -> String? {
    let defaults = UserDefaults.standard
    return defaults.string(forKey: key)
  }
}
