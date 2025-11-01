//
//  PrimerLayout.swift
//  PrimerSDK - CheckoutComponents
//
//  Layout utilities for sizes, spacing, and radii
//

import CoreGraphics

// MARK: - Primer Spacing

/// Centralized spacing values with automatic token fallbacks
struct PrimerSpacing {
    /// Extra extra small spacing (2px)
    static func xxsmall(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceXxsmall ?? 2
    }

    /// Extra small spacing (4px)
    static func xsmall(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceXsmall ?? 4
    }

    /// Small spacing (8px)
    static func small(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceSmall ?? 8
    }

    /// Medium spacing (12px)
    static func medium(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceMedium ?? 12
    }

    /// Large spacing (16px)
    static func large(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceLarge ?? 16
    }

    /// Extra large spacing (20px)
    static func xlarge(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceXlarge ?? 20
    }

    /// Extra extra large spacing (24px)
    static func xxlarge(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceXxlarge ?? 24
    }
}

// MARK: - Primer Size

/// Centralized size values with automatic token fallbacks
struct PrimerSize {
    /// Small size (16px)
    static func small(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSizeSmall ?? 16
    }

    /// Medium size (20px)
    static func medium(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSizeMedium ?? 20
    }

    /// Large size (24px)
    static func large(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSizeLarge ?? 24
    }

    /// Extra large size (32px)
    static func xlarge(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSizeXlarge ?? 32
    }

    /// Extra extra large size (44px)
    static func xxlarge(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSizeXxlarge ?? 44
    }

    /// Extra extra extra large size (56px)
    static func xxxlarge(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSizeXxxlarge ?? 56
    }
}

// MARK: - Primer Radius

/// Centralized border radius values with automatic token fallbacks
struct PrimerRadius {
    /// Extra small radius (2px)
    static func xsmall(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerRadiusXsmall ?? 2
    }

    /// Small radius (4px)
    static func small(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerRadiusSmall ?? 4
    }

    /// Medium radius (8px)
    static func medium(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerRadiusMedium ?? 8
    }

    /// Large radius (12px)
    static func large(tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerRadiusLarge ?? 12
    }
}

// MARK: - Primer Component Heights

/// Centralized component-specific height values
struct PrimerComponentHeight {
    /// Label height (16px)
    /// Matches bodySmall line-height from design tokens
    static let label: CGFloat = 16

    /// Error message container height (16px)
    /// Fixed height prevents layout shifts when error appears/disappears
    /// Matches bodySmall line-height from design tokens
    static let errorMessage: CGFloat = 16

    /// Keyboard accessory view height (44px)
    /// Standard toolbar height for iOS keyboard accessories
    static let keyboardAccessory: CGFloat = 44

    /// Payment method card height (44px)
    /// Height for payment method selection cards
    static let paymentMethodCard: CGFloat = 44

    /// Progress indicator container height (56px)
    /// Container size for loading spinner
    static let progressIndicator: CGFloat = 56
}

// MARK: - Primer Component Widths

/// Centralized component-specific width values
struct PrimerComponentWidth {
    /// Payment method icon width (32px)
    /// Width for payment method logos
    static let paymentMethodIcon: CGFloat = 32

    /// CVV field maximum width (120px)
    /// Max width constraint for CVV input field
    static let cvvFieldMax: CGFloat = 120
}

// MARK: - Primer Border Widths

/// Centralized border width values
struct PrimerBorderWidth {
    /// Thin border (0.5px)
    /// Subtle borders for delicate UI elements
    static let thin: CGFloat = 0.5

    /// Standard border (1px)
    /// Default border width for most components
    static let standard: CGFloat = 1
}

// MARK: - Primer Scale Factors

/// Scale factors for UI transformations
struct PrimerScale {
    /// Large scale (2.0)
    /// Used for enlarged elements like splash screen loader
    static let large: CGFloat = 2.0

    /// Small scale (0.8)
    /// Used for reduced elements like button loaders
    static let small: CGFloat = 0.8
}
