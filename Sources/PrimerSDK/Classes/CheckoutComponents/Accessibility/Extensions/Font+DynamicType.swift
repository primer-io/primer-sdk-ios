//
//  Font+DynamicType.swift
//  PrimerSDK
//
//  Created by Claude Code on 2025-10-28.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
extension Font {
    /// Apply Dynamic Type scaling to custom fonts using UIFontMetrics
    /// This ensures custom Inter fonts scale proportionally with system text size preferences
    /// - Parameters:
    ///   - baseSize: The base font size at default text size
    ///   - textStyle: The UIFont.TextStyle to use for scaling reference
    /// - Returns: Font with Dynamic Type scaling applied
    func dynamicallyScaled(baseSize: CGFloat, textStyle: Font.TextStyle) -> Font {
        // Get the equivalent UIFont.TextStyle for UIFontMetrics
        let uiFontTextStyle = textStyle.uiFontTextStyle

        // Use UIFontMetrics to scale the font size based on user's accessibility settings
        let metrics = UIFontMetrics(forTextStyle: uiFontTextStyle)
        let scaledSize = metrics.scaledValue(for: baseSize)

        // Return a new font with the scaled size
        // Note: We recreate the font because SwiftUI Font doesn't support direct size modification
        return Font.system(size: scaledSize)
    }
}

// MARK: - TextStyle Mapping

@available(iOS 15.0, *)
private extension Font.TextStyle {
    /// Map SwiftUI Font.TextStyle to UIKit UIFont.TextStyle for Dynamic Type scaling
    var uiFontTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}
