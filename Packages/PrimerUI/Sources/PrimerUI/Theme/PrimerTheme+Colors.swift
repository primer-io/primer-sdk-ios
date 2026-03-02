//
//  PrimerTheme+Colors.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public enum ColorState {
    case enabled, disabled, selected
}

public struct StatefulColor {
    private let enabled: UIColor
    private let disabled: UIColor
    private let selected: UIColor

    public init(
        _ enabled: UIColor,
        disabled: UIColor? = nil,
        selected: UIColor? = nil
    ) {
        self.enabled = enabled
        self.disabled = disabled ?? enabled
        self.selected = selected ?? enabled
    }

    public func color(for state: ColorState) -> UIColor {
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

public final class ColorSwatch {
    public let primary: UIColor
    public let error: UIColor

    public init(primary: UIColor, error: UIColor) {
        self.primary = primary
        self.error = error
    }
}
