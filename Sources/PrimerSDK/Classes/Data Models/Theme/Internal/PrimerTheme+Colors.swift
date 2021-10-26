internal enum ColorState {
    case enabled, disabled, selected
}

internal struct StatefulColor {
    private let enabled: UIColor
    private let disabled: UIColor
    private let selected: UIColor

    init(
        _ enabled: UIColor,
        disabled: UIColor? = nil,
        selected: UIColor? = nil
    ) {
        self.enabled = enabled
        self.disabled = disabled ?? enabled
        self.selected = selected ?? enabled
    }

    func color(for state: ColorState) -> UIColor {
        switch state {
        case .enabled:
            return enabled
        case .disabled:
            return disabled
        case .selected:
            return selected
        }
    }
}

internal struct ColorSwatch {
    let primary: UIColor
    let error: UIColor

    static func build(with data: ColorSwatchData) -> ColorSwatch {
        return ColorSwatch(
            primary: data.primary ?? UIColor.systemBlue,
            error: data.error ?? UIColor.systemRed
        )
    }
}
