//
//  PrimerTheme+Borders.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public final class BorderTheme {
    let colorStates: StatefulColor
    public let width: CGFloat

    public init(colorStates: StatefulColor, width: CGFloat) {
        self.colorStates = colorStates
        self.width = width
    }

    public func color(for state: ColorState) -> UIColor {
        colorStates.color(for: state)
    }
}
