import UIKit

enum ColorState {
    case enabled, disabled, selected
}

struct StatefulColor {
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

class ColorSwatch {
    let primary: UIColor
    let error: UIColor

    init(primary: UIColor, error: UIColor) {
        self.primary = primary
        self.error = error
    }
}
