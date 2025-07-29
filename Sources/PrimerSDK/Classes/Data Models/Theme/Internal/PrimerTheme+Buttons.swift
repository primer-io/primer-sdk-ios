//
//  PrimerTheme+Buttons.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

internal enum ButtonType {
    case main, paymentMethod
}

final class ButtonTheme {
    let colorStates: StatefulColor
    let cornerRadius: CGFloat
    let border: BorderTheme
    let text: TextTheme
    let iconColor: UIColor

    internal init(
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

    func color(for state: ColorState) -> UIColor {
        colorStates.color(for: state)
    }
}
