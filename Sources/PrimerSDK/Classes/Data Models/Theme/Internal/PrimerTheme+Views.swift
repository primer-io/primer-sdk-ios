//
//  PrimerTheme+Views.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

internal enum ViewType {
    case blurredBackground, main
}

internal struct ViewTheme {
    let backgroundColor: UIColor
    let cornerRadius: CGFloat
    let safeMargin: CGFloat
}
