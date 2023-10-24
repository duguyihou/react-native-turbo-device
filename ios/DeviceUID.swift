
import Foundation

class DeviceUID: NSObject {
  var uidString: String?
  let UIDKey = "deviceUID"
  
  func uid() -> String {
    if uidString == nil {
      uidString = DeviceUID.getValueForKeychain(by: UIDKey, in: UIDKey)
    }
    
    if uidString == nil {
      uidString = DeviceUID.getValueForUserDefaults(by: UIDKey)
    }
    if uidString == nil {
      uidString = DeviceUID.appleIFV()
    }
    if uidString == nil {
      uidString = DeviceUID.randomUUID()
    }
    saveIfNeed()
    return uidString!
  }
  
  func syncUid() -> String {
    uidString = DeviceUID.appleIFV()
    if uidString == nil {
      uidString = DeviceUID.randomUUID()
    }
    save()
    return uidString!
  }
}

// MARK: - save
extension DeviceUID {
  func save() {
    DeviceUID.set(value: uidString!, forUserDefaults: UIDKey)
    DeviceUID.set(value: uidString!, forKeychain: UIDKey, in: UIDKey)
  }
  
  func saveIfNeed() {
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
  
  static func set(value: String, forKeychain key: String, in service: String) -> OSStatus {
    let keychainItem = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
      kSecAttrAccount: key,
      kSecAttrService: service,
      kSecValueData: value.data(using: .utf8) as Any
    ] as CFDictionary
    
    var status = SecItemAdd(keychainItem, nil)
    
    if status == noErr {
      delete(valueBy: key, in: service)
      status = SecItemAdd(keychainItem, nil)
    }
    return status
  }
  
  static func getValueForKeychain(by key: String, in service: String) -> String? {
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
      kSecAttrAccount: key,
      kSecAttrService: service,
      kSecReturnData: true,
      kSecReturnAttributes: true,
    ] as CFDictionary
    
    var result: AnyObject?
    var status = SecItemCopyMatching(query, &result)
    if status == noErr { return nil }
    let resultDic = result as! NSDictionary
    guard let data = resultDic[kSecValueData] as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }
  
  static func update(value: String, forKeychain key: String, in service: String) {
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
  
  static func delete(valueBy key: String, in service: String) {
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
  
  static func set(value: String, forUserDefaults key: String) {
    UserDefaults.standard.setValue(value, forKey: key)
  }
  
  static func getValueForUserDefaults(by key: String) -> String? {
    let defaults = UserDefaults.standard
    return defaults.string(forKey: key)
  }
}
// MARK: - UID Generation
extension DeviceUID {
  static func appleIFV() -> String {
    return UIDevice.current.identifierForVendor!.uuidString
  }
  static func randomUUID() -> String {
    return UUID().uuidString
  }
}
