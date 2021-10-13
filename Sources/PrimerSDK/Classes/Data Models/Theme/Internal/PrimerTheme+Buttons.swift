internal struct ButtonTheme {
    let colorStates: StatefulColor
    let cornerRadius: CGFloat
    let border: BorderTheme
    let text: TextTheme

    static func main(with data: ButtonThemeData?) -> ButtonTheme {
        return ButtonTheme(
            colorStates: StatefulColor(
                data?.defaultColor ?? Colors.Buttons.Main.Default,
                disabled: data?.disabledColor ?? Colors.Buttons.Main.Disabled,
                selected: Colors.Buttons.Main.Selected
            ),
            cornerRadius: data?.cornerRadius ?? Layout.MainButton.CornerRadius,
            border: BorderTheme(
                colorStates: StatefulColor(
                    data?.defaultColor ?? Colors.Buttons.Main.Border.Default,
                    disabled: data?.disabledColor ?? Colors.Buttons.Main.Border.Disabled,
                    selected: data?.disabledColor ?? Colors.Buttons.Main.Border.Selected
                ),
                width: data?.border?.width ?? Layout.MainButton.BorderWidth
            ),
            text: TextTheme(
                color: data?.text?.defaultColor ?? Colors.Buttons.Main.Text.Enabled,
                fontsize: data?.text?.fontsize ?? Fontsize.MainButtonTitle
            )
        )
    }

    static func paymentMethod(with data: ButtonThemeData?) -> ButtonTheme {
        return ButtonTheme(
            colorStates: StatefulColor(
                data?.defaultColor ?? Colors.Buttons.PaymentMethod.Default,
                disabled: data?.disabledColor ?? Colors.Buttons.PaymentMethod.Disabled,
                selected: Colors.Buttons.PaymentMethod.Selected
            ),
            cornerRadius: data?.cornerRadius ?? Layout.PaymentMethodButton.CornerRadius,
            border: BorderTheme(
                colorStates: StatefulColor(
                    data?.defaultColor ?? Colors.Buttons.PaymentMethod.Border.Default,
                    disabled: data?.disabledColor ?? Colors.Buttons.PaymentMethod.Border.Disabled,
                    selected: Colors.Buttons.PaymentMethod.Border.Selected
                ),
                width: data?.border?.width ?? Layout.PaymentMethodButton.BorderWidth
            ),
            text: TextTheme(
                color: data?.text?.defaultColor ?? Colors.Buttons.PaymentMethod.Text.Enabled,
                fontsize: data?.text?.fontsize ?? Fontsize.PaymentMethodButtonTitle
            )
        )
    }

    func color(for state: ColorState) -> UIColor {
        return colorStates.color(for: state)
    }
}
