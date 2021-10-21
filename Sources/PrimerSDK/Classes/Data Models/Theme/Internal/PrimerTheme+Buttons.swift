internal struct ButtonTheme {
    let colorStates: StatefulColor
    let cornerRadius: CGFloat
    let border: BorderTheme
    let text: TextTheme

    static func main(with data: ButtonThemeData) -> ButtonTheme {
        return ButtonTheme(
            colorStates: StatefulColor(
                data.defaultColor ?? Colors.Blue,
                disabled: data.disabledColor ?? Colors.LightGray,
                selected: Colors.Blue
            ),
            cornerRadius: data.cornerRadius ?? Layout.MainButton.CornerRadius,
            border: BorderTheme(
                colorStates: StatefulColor(
                    data.border.defaultColor ?? Colors.Blue,
                    disabled: data.border.defaultColor ?? Colors.LightGray,
                    selected: data.border.selectedColor ?? Colors.Blue
                ),
                width: data.border.width ?? Layout.MainButton.BorderWidth
            ),
            text: TextTheme(
                color: data.text.defaultColor ?? Colors.White,
                fontSize: data.text.fontSize ?? Fontsize.MainButtonTitle
            )
        )
    }

    static func paymentMethod(with data: ButtonThemeData) -> ButtonTheme {
        return ButtonTheme(
            colorStates: StatefulColor(
                data.defaultColor ?? Colors.White,
                disabled: data.disabledColor ?? Colors.LightGray,
                selected: Colors.White
            ),
            cornerRadius: data.cornerRadius ?? Layout.PaymentMethodButton.CornerRadius,
            border: BorderTheme(
                colorStates: StatefulColor(
                    data.border.defaultColor ?? Colors.Black,
                    disabled: data.border.defaultColor ?? Colors.LightGray,
                    selected: data.border.selectedColor ?? Colors.Blue
                ),
                width: data.border.width ?? Layout.PaymentMethodButton.BorderWidth
            ),
            text: TextTheme(
                color: data.text.defaultColor ?? Colors.Black,
                fontSize: data.text.fontSize ?? Fontsize.PaymentMethodButtonTitle
            )
        )
    }

    func color(for state: ColorState) -> UIColor {
        return colorStates.color(for: state)
    }
}
