internal struct BorderTheme {
    let colorStates: StatefulColor
    let width: CGFloat

    func color(for state: ColorState) -> UIColor {
        return colorStates.color(for: state)
    }
}
