//
//  CheckoutColors.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Primer Colors

/// Centralized color values with automatic token fallbacks for CheckoutComponents
enum CheckoutColors {
    // MARK: - Public Color Helpers

    /// Primary text color (for main content)
    static func textPrimary(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorTextPrimary ?? .primary
    }

    /// Secondary text color (for labels, placeholders)
    static func textSecondary(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorTextSecondary ?? .secondary
    }

    /// Negative/error text color
    static func textNegative(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorTextNegative ?? .red
    }

    /// Negative/error icon color
    static func iconNegative(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorIconNegative ?? .red
    }

    /// Default border color
    static func borderDefault(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorBorderOutlinedDefault ?? .gray
    }

    /// Error state border color
    static func borderError(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorBorderOutlinedError ?? .red
    }

    /// Focus state border color
    static func borderFocus(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorBorderOutlinedFocus ?? .blue
    }

    /// Background color
    static func background(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorBackground ?? .white
    }

    /// Gray 100 color (lightest gray)
    static func gray100(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorGray100 ?? Color(.systemGray6)
    }

    /// Gray 200 color (light gray)
    static func gray200(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorGray200 ?? Color(.systemGray5)
    }

    /// Gray 300 color (medium light gray)
    static func gray300(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorGray300 ?? Color(.systemGray4)
    }

    /// Placeholder text color
    static func textPlaceholder(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorTextPlaceholder ?? Color(.tertiaryLabel)
    }

    /// Positive/success icon color
    static func iconPositive(tokens: DesignTokens?) -> Color {
        return tokens?.primerColorIconPositive ?? Color(.systemGreen)
    }

    // MARK: - Semantic UI Colors (for components without token mappings)

    /// White color (for button text on dark backgrounds)
    static func white(tokens _: DesignTokens?) -> Color {
        return .white
    }

    /// Gray color (generic gray for subtle elements)
    static func gray(tokens _: DesignTokens?) -> Color {
        return .gray
    }

    /// Blue color (for links and action elements)
    static func blue(tokens _: DesignTokens?) -> Color {
        return .blue
    }

    /// Green color (for success states)
    static func green(tokens _: DesignTokens?) -> Color {
        return .green
    }

    /// Orange color (for warning states)
    static func orange(tokens _: DesignTokens?) -> Color {
        return .orange
    }

    /// Primary system color (for main UI elements)
    static func primary(tokens _: DesignTokens?) -> Color {
        return .primary
    }

    /// Secondary system color (for supporting UI elements)
    static func secondary(tokens _: DesignTokens?) -> Color {
        return .secondary
    }

    /// Clear color (for transparent backgrounds)
    static func clear(tokens _: DesignTokens?) -> Color {
        return .clear
    }
}
