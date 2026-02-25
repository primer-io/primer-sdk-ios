//
//  PrimerTheme+Views.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public enum ViewType {
    case blurredBackground, main
}

public struct ViewTheme {
    public let backgroundColor: UIColor
    public let cornerRadius: CGFloat
    public let safeMargin: CGFloat
    
    public init(
        backgroundColor: UIColor,
        cornerRadius: CGFloat,
        safeMargin: CGFloat
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.safeMargin = safeMargin
    }
}
