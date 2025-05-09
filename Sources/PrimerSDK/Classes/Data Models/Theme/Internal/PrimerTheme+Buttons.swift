import UIKit

enum ButtonType {
    case main, paymentMethod
}

class ButtonTheme {
    let colorStates: StatefulColor
    let cornerRadius: CGFloat
    let border: BorderTheme
    let text: TextTheme
    let iconColor: UIColor

    init(
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
