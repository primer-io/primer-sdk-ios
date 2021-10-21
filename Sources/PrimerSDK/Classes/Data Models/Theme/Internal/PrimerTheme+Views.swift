internal struct ViewTheme {
    let backgroundColor: UIColor
    let cornerRadius: CGFloat
    let safeMargin: CGFloat

    static func `default`(with data: ViewThemeData) -> ViewTheme {
        return ViewTheme(
            backgroundColor: data.backgroundColor ?? Colors.White,
            cornerRadius: data.cornerRadius ?? Layout.View.CornerRadius,
            safeMargin: data.safeMargin ?? Layout.View.SafeArea
        )
    }
}
