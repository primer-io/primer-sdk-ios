internal struct ButtonTheme {
    let colorStates: StatefulColor
    let cornerRadius: CGFloat
    let border: BorderTheme
    let text: TextTheme
    let iconColor: UIColor

    static func main(with data: ButtonThemeData) -> ButtonTheme {
        return ButtonTheme(
            colorStates: StatefulColor(
                data.defaultColor ?? Colors.blue,
                disabled: data.disabledColor ?? Colors.lightGray,
                selected: Colors.blue
            ),
            cornerRadius: data.cornerRadius ?? Layout.MainButton.cornerRadius,
            border: BorderTheme(
                colorStates: StatefulColor(
                    data.border.defaultColor ?? Colors.blue,
                    disabled: data.border.defaultColor ?? Colors.lightGray,
                    selected: data.border.selectedColor ?? Colors.blue
                ),
                width: data.border.width ?? Layout.MainButton.borderWidth
            ),
            text: TextTheme(
                color: data.text.defaultColor ?? Colors.white,
                fontSize: data.text.fontSize ?? Fontsize.buttonLabel
            ),
            iconColor: data.iconColor ?? Colors.white
        )
    }

    static func paymentMethod(with data: ButtonThemeData) -> ButtonTheme {
        return ButtonTheme(
            colorStates: StatefulColor(
                data.defaultColor ?? Colors.white,
                disabled: data.disabledColor ?? Colors.lightGray,
                selected: Colors.white
            ),
            cornerRadius: data.cornerRadius ?? Layout.PaymentMethodButton.cornerRadius,
            border: BorderTheme(
                colorStates: StatefulColor(
                    data.border.defaultColor ?? Colors.black,
                    disabled: data.border.defaultColor ?? Colors.lightGray,
                    selected: data.border.selectedColor ?? Colors.blue
                ),
                width: data.border.width ?? Layout.PaymentMethodButton.borderWidth
            ),
            text: TextTheme(
                color: data.text.defaultColor ?? Colors.black,
                fontSize: data.text.fontSize ?? Fontsize.buttonLabel
            ),
            iconColor: data.iconColor ?? Colors.black
        )
    }

    func color(for state: ColorState) -> UIColor {
        return colorStates.color(for: state)
    }
}
