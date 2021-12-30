#if canImport(UIKit)

import UIKit

internal enum InputType {
    case outlined, underlined, doublelined
}

internal class InputTheme {
    let color: UIColor
    let cornerRadius: CGFloat
    let border: BorderTheme
    let text: TextTheme
    let hintText: TextTheme
    let errortext: TextTheme
    let inputType: InputType
    
    internal init(
        color: UIColor,
        cornerRadius: CGFloat,
        border: BorderTheme,
        text: TextTheme,
        hintText: TextTheme,
        errortext: TextTheme,
        inputType: InputType
    ) {
        self.color = color
        self.cornerRadius = cornerRadius
        self.border = border
        self.text = text
        self.hintText = hintText
        self.errortext = errortext
        self.inputType = inputType
    }
}

#endif
