import UIKit

internal enum ViewType {
    case blurredBackground, main
}

internal struct ViewTheme {
    let backgroundColor: UIColor
    let cornerRadius: CGFloat
    let safeMargin: CGFloat
}
