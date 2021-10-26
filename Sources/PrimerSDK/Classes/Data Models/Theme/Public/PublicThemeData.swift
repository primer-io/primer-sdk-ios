import UIKit
public class PrimerThemeData {
    public var colors: ColorSwatchData
    public var view: ViewThemeData
    public var text: TextStyleData
    public var buttons: ButtonStyleData
    public var input: InputThemeData
    
    public init(
        colors: ColorSwatchData = ColorSwatchData(),
        view: ViewThemeData = ViewThemeData(),
        text: TextStyleData = TextStyleData(),
        buttons: ButtonStyleData = ButtonStyleData(),
        input: InputThemeData = InputThemeData()
    ) {
        self.colors = colors
        self.view = view
        self.text = text
        self.buttons = buttons
        self.input = input
    }
}

public class ButtonStyleData {
    public var main: ButtonThemeData
    public var paymentMethod: ButtonThemeData
    
    public init(
        main: ButtonThemeData = ButtonThemeData(),
        paymentMethod: ButtonThemeData = ButtonThemeData()
    ) {
        self.main = main
        self.paymentMethod = paymentMethod
    }
}

public class ButtonThemeData {
    public var defaultColor: UIColor?
    public var disabledColor: UIColor?
    public var errorColor: UIColor?
    public var cornerRadius: CGFloat?
    public var text: TextThemeData
    public var border: BorderThemeData
    public var iconColor: UIColor?

    public init(
        defaultColor: UIColor? = nil,
        disabledColor: UIColor? = nil,
        errorColor: UIColor? = nil,
        cornerRadius: CGFloat? = nil,
        text: TextThemeData = TextThemeData(),
        border: BorderThemeData = BorderThemeData(),
        iconColor: UIColor? = nil
    ) {
        self.defaultColor = defaultColor
        self.disabledColor = disabledColor
        self.errorColor = errorColor
        self.text = text
        self.border = border
        self.cornerRadius = cornerRadius
        self.iconColor = iconColor ?? text.defaultColor
    }
}

public class ViewThemeData {
    public var backgroundColor: UIColor?
    public var cornerRadius: CGFloat?
    public var safeMargin: CGFloat?
    
    public init(
        backgroundColor: UIColor? = nil,
        cornerRadius: CGFloat? = nil,
        safeMargin: CGFloat? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.safeMargin = safeMargin
    }
}

public class TextStyleData {
    public var body: TextThemeData
    public var title: TextThemeData
    public var subtitle: TextThemeData
    public var amountLabel: TextThemeData
    public var system: TextThemeData
    public var error: TextThemeData

    public init(
        body: TextThemeData = TextThemeData(),
        title: TextThemeData = TextThemeData(),
        subtitle: TextThemeData = TextThemeData(),
        amountLabel: TextThemeData = TextThemeData(),
        system: TextThemeData = TextThemeData(),
        error: TextThemeData = TextThemeData()
    ) {
        self.body = body
        self.title = title
        self.subtitle = subtitle
        self.amountLabel = amountLabel
        self.system = system
        self.error = error
    }
}

public class TextThemeData {
    public var defaultColor: UIColor?
    public var fontSize: Int?

    public init(defaultColor: UIColor? = nil, fontsize: Int? = nil) {
        self.defaultColor = defaultColor
        self.fontSize = fontsize
    }
}

public class BorderThemeData {
    public var defaultColor: UIColor?
    public var selectedColor: UIColor?
    public var errorColor: UIColor?
    public var width: CGFloat?

    public init(
        defaultColor: UIColor? = nil,
        selectedColor: UIColor? = nil,
        errorColor: UIColor? = nil,
        width: CGFloat? = nil
    ) {
        self.defaultColor = defaultColor
        self.selectedColor = selectedColor
        self.errorColor = errorColor
        self.width = width
    }
}

public class InputThemeData {
    public var backgroundColor: UIColor?
    public var text: TextThemeData
    public var border: BorderThemeData
    public var cornerRadius: CGFloat?

    public init(
        backgroundColor: UIColor? = nil,
        text: TextThemeData = TextThemeData(),
        border: BorderThemeData = BorderThemeData(),
        cornerRadius: CGFloat? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.text = text
        self.border = border
        self.cornerRadius = cornerRadius
    }
}

public class ColorSwatchData {
    public var primary: UIColor?
    public var error: UIColor?
    
    public init(primary: UIColor? = nil, error: UIColor? = nil) {
        self.primary = primary
        self.error = error
    }
}
