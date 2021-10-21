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
            color: data.backgroundColor ?? Colors.White,
            cornerRadius: data.cornerRadius ?? 0.0,
            border: BorderTheme(
                colorStates: StatefulColor(
                    data.border.defaultColor ?? Colors.Blue,
                    disabled: data.border.defaultColor ?? Colors.LightGray
                ),
                width: data.border.width ?? 1.0
            ),
            text: TextTheme(
                color: data.text.defaultColor ?? Colors.Black,
                fontSize: data.text.fontSize ?? 14
            ),
            hintText: TextTheme(
                color: data.text.defaultColor ?? Colors.Gray,
                fontSize: data.text.fontSize ?? 14
            ),
            errortext: TextTheme(
                color: data.text.defaultColor ?? Colors.Red,
                fontSize: data.text.fontSize ?? 14
            ),
            inputType: InputType.underlined
        )
    }
}
