//
//  PrimerTheme+Buttons.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public enum ButtonType {
    case main, paymentMethod
}

public final class ButtonTheme {
    public let colorStates: StatefulColor
    public let cornerRadius: CGFloat
    public let border: BorderTheme
    public let text: TextTheme
    public let iconColor: UIColor

    public init(
        colorStates: StatefulColor,
        cornerRadius: CGFloat,
        border: BorderTheme,
        text: TextTheme,
        iconColor: UIColor
    ) {
        self.colorStates = colorStates
        self.cornerRadius = cornerRadius
        self.border = border
        self.text = text
        self.iconColor = iconColor
    }

    public func color(for state: ColorState) -> UIColor {
        colorStates.color(for: state)
    }
}
