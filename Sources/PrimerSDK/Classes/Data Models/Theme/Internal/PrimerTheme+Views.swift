internal struct ViewTheme {
    let backgroundColor: UIColor
    let cornerRadius: CGFloat
    let safeMargin: CGFloat

    static func `default`(with data: ViewThemeData?) -> ViewTheme {
        return ViewTheme(
            backgroundColor: data?.backgroundColor ?? UIColor.white,
            cornerRadius: data?.cornerRadius ?? CGFloat(0.0),
            safeMargin: data?.safeMargin ?? CGFloat(10.0)
        )
    }
}
