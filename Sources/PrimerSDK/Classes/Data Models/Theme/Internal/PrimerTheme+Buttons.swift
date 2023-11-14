import UIKit

internal enum ButtonType {
    case main, paymentMethod
}

internal class ButtonTheme {
    let colorStates: StatefulColor
    let cornerRadius: CGFloat
    let border: BorderTheme
    let text: TextTheme
    let iconColor: UIColor

    internal init(
        colorStates: StatefulColor,
        cornerRadius: CGFloat,
        border: BorderTheme,
        text: TextTheme,
        iconColor: UIColor
    ) {
        self.colorStates = colorStates
        self.cornerRadius = cornerRadius
        self.border = border
        self.text = text
        self.iconColor = iconColor
    }

    func color(for state: ColorState) -> UIColor {
        colorStates.color(for: state)
    }
}
