//
//  PrimerTheme+Borders.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class BorderTheme {
    let colorStates: StatefulColor
    let width: CGFloat

    init(colorStates: StatefulColor, width: CGFloat) {
        self.colorStates = colorStates
        self.width = width
    }

    func color(for state: ColorState) -> UIColor {
        return colorStates.color(for: state)
    }
}
