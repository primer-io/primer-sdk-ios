#if canImport(UIKit)

import UIKit

internal enum TextType {
    case body, title, subtitle, amountLabel, system, error
}

internal class TextStyle {
    let body, title, subtitle, amountLabel, system, error: TextTheme
    
    internal init(
        body: TextTheme,
        title: TextTheme,
        subtitle: TextTheme,
        amountLabel: TextTheme,
        system: TextTheme,
        error: TextTheme
    ) {
        self.body = body
        self.title = title
        self.subtitle = subtitle
        self.amountLabel = amountLabel
        self.system = system
        self.error = error
    }
}

internal class TextTheme {
    let color: UIColor
    let fontSize: Int
    
    internal init(color: UIColor, fontSize: Int) {
        self.color = color
        self.fontSize = fontSize
    }
}

#endif
