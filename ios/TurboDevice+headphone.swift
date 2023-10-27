import Foundation
import AVFoundation

extension TurboDevice {
  
  private var isHeadphonesConnected: Bool {
    let currentRoute = AVAudioSession.sharedInstance().currentRoute
    for desc in currentRoute.outputs {
      let portType = desc.portType
      if portType == .headphones || portType == .bluetoothA2DP || portType == .bluetoothHFP {
        return true
      }
    }
    return false
  }
  
  @objc
  func isHeadphonesConnected(_ resolve: @escaping RCTPromiseResolveBlock,
                             reject: @escaping RCTPromiseRejectBlock) {
    resolve(isHeadphonesConnected)
  }
  
  @objc
  func headphoneConnectionDidChange() {
    sendEvent(withName: "TurboDevice_headphoneConnectionDidChange",
              body: ["isConnected": isHeadphonesConnected])
  }
  
}
