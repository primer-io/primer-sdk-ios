internal enum InputType {
    case outlined, underlined, doublelined
}

internal struct InputTheme {
    let color: UIColor
    let cornerRadius: CGFloat
    let border: BorderTheme
    let text: TextTheme
    let hintText: TextTheme
    let errortext: TextTheme
    let inputType: InputType

    static func `default`(with data: InputThemeData) -> InputTheme {
        return  InputTheme(
            color: data.backgroundColor ?? Colors.Input.Background,
            cornerRadius: data.cornerRadius ?? 0.0,
            border: BorderTheme(
                colorStates: StatefulColor(
                    data.border.defaultColor ?? Colors.Input.BorderDefault,
                    disabled: data.border.defaultColor ?? Colors.Input.BorderDisabled
                ),
                width: data.border.width ?? 1.0
            ),
            text: TextTheme(
                color: data.text.defaultColor ?? Colors.Input.Text,
                fontsize: data.text.fontsize ?? 14
            ),
            hintText: TextTheme(
                color: data.text.defaultColor ?? Colors.Input.HintText,
                fontsize: data.text.fontsize ?? 14
            ),
            errortext: TextTheme(
                color: data.text.defaultColor ?? Colors.Input.ErrorText,
                fontsize: data.text.fontsize ?? 14
            ),
            inputType: InputType.underlined
        )
    }
}
