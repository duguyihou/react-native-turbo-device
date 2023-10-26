import Foundation
import AVFoundation

extension TurboDevice {
  @objc
  func isHeadphonesConnected(_ resolve: @escaping RCTPromiseResolveBlock,
                               reject: @escaping RCTPromiseRejectBlock) {
    let currentRoute = AVAudioSession.sharedInstance().currentRoute
    for desc in currentRoute.outputs {
      let portType = desc.portType
      if portType == .headphones || portType == .bluetoothA2DP || portType == .bluetoothHFP {
        resolve(true)
      }
    }
    resolve(false)
  }
  
  @objc
  func headphoneConnectionDidChange() {
    let isConnected = {
      let currentRoute = AVAudioSession.sharedInstance().currentRoute
      for desc in currentRoute.outputs {
        let portType = desc.portType
        if portType == .headphones || portType == .bluetoothA2DP || portType == .bluetoothHFP {
          return true
        }
      }
      return false
    }()
    sendEvent(withName: "TurboDevice_headphoneConnectionDidChange", body: [isConnected])
  }

}
