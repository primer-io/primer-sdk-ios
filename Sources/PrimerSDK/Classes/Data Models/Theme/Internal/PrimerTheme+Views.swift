internal struct ViewTheme {
    let backgroundColor: UIColor
    let cornerRadius: CGFloat
    let safeMargin: CGFloat

    static func build(with data: ViewThemeData) -> ViewTheme {
        return ViewTheme(
            backgroundColor: data.backgroundColor ?? Colors.white,
            cornerRadius: data.cornerRadius ?? Layout.View.cornerRadius,
            safeMargin: data.safeMargin ?? Layout.View.safeArea
        )
    }
}
