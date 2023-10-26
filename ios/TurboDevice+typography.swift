import Foundation

extension TurboDevice {
  @objc
  func getFontScale(_ resolve: @escaping RCTPromiseResolveBlock,
                    reject: @escaping RCTPromiseRejectBlock) {
    let contentSize = UIScreen.main.traitCollection.preferredContentSizeCategory
    let fontScale = {
      switch contentSize {
      case .extraSmall:
        return 0.82
      case .small:
        return 0.88
      case .medium:
        return 0.95
      case .large:
        return 1.0
      case .extraLarge:
        return 1.12
      case .extraExtraLarge:
        return 1.23
      case .extraExtraExtraLarge:
        return 1.35
      case .accessibilityMedium:
        return 1.64
      case .accessibilityLarge:
        return 1.95
      case .accessibilityExtraLarge:
        return 2.35
      case .accessibilityExtraExtraLarge:
        return 2.76
      case .accessibilityExtraExtraExtraLarge:
        return 3.12
      default:
        return 1.0
      }
    }()
    resolve(fontScale)
  }
}
