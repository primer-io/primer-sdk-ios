#if canImport(UIKit)

import UIKit

internal enum ViewType {
    case blurredBackground, main
}

internal struct ViewTheme {
    let backgroundColor: UIColor
    let cornerRadius: CGFloat
    let safeMargin: CGFloat
    
    internal init(
        backgroundColor: UIColor,
        cornerRadius: CGFloat,
        safeMargin: CGFloat
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.safeMargin = safeMargin
    }
}

#endif
