import UIKit

enum ViewType {
    case blurredBackground, main
}

struct ViewTheme {
    let backgroundColor: UIColor
    let cornerRadius: CGFloat
    let safeMargin: CGFloat
}
