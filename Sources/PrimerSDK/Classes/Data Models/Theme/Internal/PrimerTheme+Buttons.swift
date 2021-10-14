internal struct ButtonTheme {
    let colorStates: StatefulColor
    let cornerRadius: CGFloat
    let border: BorderTheme
    let text: TextTheme

    static func main(with data: ButtonThemeData) -> ButtonTheme {
        return ButtonTheme(
            colorStates: StatefulColor(
                data.defaultColor ?? Colors.Buttons.MainDefault,
                disabled: data.disabledColor ?? Colors.Buttons.MainDisabled,
                selected: Colors.Buttons.MainSelected
            ),
            cornerRadius: data.cornerRadius ?? Layout.MainButton.CornerRadius,
            border: BorderTheme(
                colorStates: StatefulColor(
                    data.border.defaultColor ?? Colors.Buttons.MainBorderDefault,
                    disabled: data.border.defaultColor ?? Colors.Buttons.MainBorderDisabled,
                    selected: data.border.selectedColor ?? Colors.Buttons.MainBorderSelected
                ),
                width: data.border.width ?? Layout.MainButton.BorderWidth
            ),
            text: TextTheme(
                color: data.text.defaultColor ?? Colors.Buttons.MainTextEnabled,
                fontsize: data.text.fontsize ?? Fontsize.MainButtonTitle
            )
        )
    }

    static func paymentMethod(with data: ButtonThemeData) -> ButtonTheme {
        return ButtonTheme(
            colorStates: StatefulColor(
                data.defaultColor ?? Colors.Buttons.PaymentMethodDefault,
                disabled: data.disabledColor ?? Colors.Buttons.PaymentMethodDisabled,
                selected: Colors.Buttons.PaymentMethodSelected
            ),
            cornerRadius: data.cornerRadius ?? Layout.PaymentMethodButton.CornerRadius,
            border: BorderTheme(
                colorStates: StatefulColor(
                    data.border.defaultColor ?? Colors.Buttons.PaymentMethodBorderDefault,
                    disabled: data.border.defaultColor ?? Colors.Buttons.PaymentMethodBorderDisabled,
                    selected: data.border.selectedColor ?? Colors.Buttons.PaymentMethodBorderSelected
                ),
                width: data.border.width ?? Layout.PaymentMethodButton.BorderWidth
            ),
            text: TextTheme(
                color: data.text.defaultColor ?? Colors.Buttons.PaymentMethodTextEnabled,
                fontsize: data.text.fontsize ?? Fontsize.PaymentMethodButtonTitle
            )
        )
    }

    func color(for state: ColorState) -> UIColor {
        return colorStates.color(for: state)
    }
}
