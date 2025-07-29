//
//  PrimerTheme+Colors.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

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

final class ColorSwatch {
    let primary: UIColor
    let error: UIColor

    internal init(primary: UIColor, error: UIColor) {
        self.primary = primary
        self.error = error
    }
}
