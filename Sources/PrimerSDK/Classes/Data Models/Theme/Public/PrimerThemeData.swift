// swiftlint:disable type_body_length
import UIKit

public class PrimerThemeData {
    public var colors: ColorSwatch
    public var dimensions: Dimensions
    public var blurView: View
    public var view: View
    public var text: TextStyle
    public var buttons: ButtonStyle
    public var input: Input

    public init(
        colors: ColorSwatch = ColorSwatch(),
        dimensions: Dimensions = Dimensions(),
        blurView: View = View(),
        view: View = View(),
        text: TextStyle = TextStyle(),
        buttons: ButtonStyle = ButtonStyle(),
        input: Input = Input()
    ) {
        self.colors = colors
        self.dimensions = dimensions
        self.blurView = blurView
        self.view = view
        self.text = text
        self.buttons = buttons
        self.input = input
    }

    public class ButtonStyle {
        public var main: Button
        public var paymentMethod: Button

        public init(
            main: Button = Button(),
            paymentMethod: Button = Button()
        ) {
            self.main = main
            self.paymentMethod = paymentMethod
        }

        internal func theme(for type: ButtonType, with data: PrimerThemeData) -> ButtonTheme {
            switch type {
            case .main:
                let button = main
                return ButtonTheme(
                    colorStates: StatefulColor(
                        button.defaultColor ?? data.colors.primary,
                        disabled: button.disabledColor ?? data.colors.lightGray,
                        selected: button.selectedColor ?? data.colors.primary
                    ),
                    cornerRadius: main.cornerRadius ?? PrimerDimensions.Component.cornerRadius,
                    border: BorderTheme(
                        colorStates: StatefulColor(
                            button.border.defaultColor ?? data.colors.primary,
                            selected: button.border.selectedColor ?? data.colors.primary
                        ),
                        width: button.border.width ?? PrimerDimensions.Component.borderWidth
                    ),
                    text: TextTheme(
                        color: button.text.defaultColor ?? data.colors.light,
                        fontSize: button.text.fontSize ?? Int(PrimerDimensions.Font.body)
                    ),
                    iconColor: button.iconColor ?? data.colors.light
                )
            case .paymentMethod:
                let button = paymentMethod
                return ButtonTheme(
                    colorStates: StatefulColor(
                        button.defaultColor ?? data.colors.light,
                        disabled: button.disabledColor ?? data.colors.lightGray,
                        selected: button.selectedColor ?? data.colors.primary
                    ),
                    cornerRadius: button.cornerRadius ?? PrimerDimensions.Component.cornerRadius,
                    border: BorderTheme(
                        colorStates: StatefulColor(
                            button.border.defaultColor ?? data.colors.dark,
                            selected: button.border.selectedColor ?? data.colors.primary
                        ),
                        width: button.border.width ?? PrimerDimensions.Component.borderWidth
                    ),
                    text: TextTheme(
                        color: button.text.defaultColor ?? data.colors.dark,
                        fontSize: button.text.fontSize ?? Int(PrimerDimensions.Font.body)
                    ),
                    iconColor: button.iconColor ?? data.colors.dark
                )
            }
        }
    }

    public class Button {
        public var defaultColor: UIColor?
        public var disabledColor: UIColor?
        public var selectedColor: UIColor?
        public var errorColor: UIColor?
        public var cornerRadius: CGFloat?
        public var text: Text
        public var border: Border
        public var iconColor: UIColor?

        public init(
            defaultColor: UIColor? = nil,
            disabledColor: UIColor? = nil,
            selectedColor: UIColor? = nil,
            errorColor: UIColor? = nil,
            cornerRadius: CGFloat? = nil,
            text: Text = Text(),
            border: Border = Border(),
            iconColor: UIColor? = nil
        ) {
            self.defaultColor = defaultColor
            self.disabledColor = disabledColor
            self.selectedColor = selectedColor
            self.errorColor = errorColor
            self.text = text
            self.border = border
            self.cornerRadius = cornerRadius
            self.iconColor = iconColor
        }
    }

    public class View {
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

        internal func theme(for viewType: ViewType, with data: PrimerThemeData) -> ViewTheme {
            switch viewType {
            case .blurredBackground:
                return ViewTheme(
                    backgroundColor: data.blurView.backgroundColor ?? PrimerColors.blurredBackground,
                    cornerRadius: PrimerDimensions.zero,
                    safeMargin: PrimerDimensions.zero
                )
            case .main:
                return ViewTheme(
                    backgroundColor: data.view.backgroundColor ?? data.colors.light,
                    cornerRadius: data.view.cornerRadius ?? PrimerDimensions.cornerRadius,
                    safeMargin: data.view.safeMargin ?? PrimerDimensions.safeArea
                )
            }
        }
    }

    public class TextStyle {
        public var body: Text
        public var title: Text
        public var subtitle: Text
        public var amountLabel: Text
        public var system: Text
        public var error: Text

        public init(
            body: Text = Text(),
            title: Text = Text(),
            subtitle: Text = Text(),
            amountLabel: Text = Text(),
            system: Text = Text(),
            error: Text = Text()
        ) {
            self.body = body
            self.title = title
            self.subtitle = subtitle
            self.amountLabel = amountLabel
            self.system = system
            self.error = error
        }

        internal func theme(for type: TextType, with data: PrimerThemeData) -> TextTheme {
            switch type {
            case .body:
                return TextTheme(
                    color: body.defaultColor ?? data.colors.dark,
                    fontSize: body.fontSize ?? Int(PrimerDimensions.Font.body)
                )
            case .subtitle:
                return TextTheme(
                    color: subtitle.defaultColor ?? data.colors.gray,
                    fontSize: subtitle.fontSize ?? Int(PrimerDimensions.Font.subtitle)
                )
            case .title:
                return TextTheme(
                    color: title.defaultColor ?? data.colors.dark,
                    fontSize: title.fontSize ?? Int(PrimerDimensions.Font.title)
                )
            case .amountLabel:
                return TextTheme(
                    color: amountLabel.defaultColor ?? data.colors.dark,
                    fontSize: amountLabel.fontSize ?? Int(PrimerDimensions.Font.amountLabel)
                )
            case .system:
                return TextTheme(
                    color: system.defaultColor ?? data.colors.primary,
                    fontSize: system.fontSize ?? Int(PrimerDimensions.Font.system)
                )
            case .error:
                return TextTheme(
                    color: error.defaultColor ?? data.colors.error,
                    fontSize: error.fontSize ?? Int(PrimerDimensions.Font.error)
                )
            }
        }
    }

    public class Text {
        public var defaultColor: UIColor?
        public var fontSize: Int?

        public init(defaultColor: UIColor? = nil, fontsize: Int? = nil) {
            self.defaultColor = defaultColor
            self.fontSize = fontsize
        }
    }

    public class Border {
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

    public class Input {
        public var backgroundColor: UIColor?
        public var text: Text
        public var border: Border
        public var cornerRadius: CGFloat?

        public init(
            backgroundColor: UIColor? = nil,
            text: Text = Text(),
            border: Border = Border(),
            cornerRadius: CGFloat? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.text = text
            self.border = border
            self.cornerRadius = cornerRadius
        }

        internal func theme(with data: PrimerThemeData) -> InputTheme {
            InputTheme(
                color: backgroundColor ?? data.colors.light,
                cornerRadius: cornerRadius ?? PrimerDimensions.Component.cornerRadius,
                border: BorderTheme(
                    colorStates: StatefulColor(
                        border.defaultColor ?? data.colors.dark,
                        disabled: border.selectedColor,
                        selected: border.selectedColor ?? data.colors.primary
                    ),
                    width: border.width ?? PrimerDimensions.Component.borderWidth
                ),
                text: TextTheme(
                    color: text.defaultColor ?? data.colors.dark,
                    fontSize: text.fontSize ?? Int(PrimerDimensions.Font.body)
                ),
                hintText: TextTheme(
                    color: text.defaultColor ?? data.colors.gray,
                    fontSize: text.fontSize ?? Int(PrimerDimensions.Font.body)
                ),
                errortext: TextTheme(
                    color: text.defaultColor ?? data.colors.error,
                    fontSize: text.fontSize ?? Int(PrimerDimensions.Font.body)
                ),
                inputType: .underlined
            )
        }
    }

    public class ColorSwatch {
        public var primary: UIColor
        public var error: UIColor
        public var dark: UIColor
        public var light: UIColor
        public var gray: UIColor
        public var lightGray: UIColor

        public init(
            primary: UIColor = PrimerColors.blue,
            error: UIColor = PrimerColors.red,
            dark: UIColor = PrimerColors.black, // light in dark mode
            light: UIColor = PrimerColors.white, // dark in dark mode
            gray: UIColor = PrimerColors.gray,
            lightGray: UIColor = PrimerColors.lightGray
        ) {
            self.primary = primary
            self.error = error
            self.dark = dark
            self.light = light
            self.gray = gray
            self.lightGray = lightGray
        }
    }

    public class Dimensions {
        public var cornerRadius: CGFloat
        public var safeArea: CGFloat

        public init(
            cornerRadius: CGFloat = PrimerDimensions.cornerRadius,
            safeArea: CGFloat = PrimerDimensions.safeArea
        ) {
            self.cornerRadius = cornerRadius
            self.safeArea = safeArea
        }
    }
}
// swiftlint:enable type_body_length
