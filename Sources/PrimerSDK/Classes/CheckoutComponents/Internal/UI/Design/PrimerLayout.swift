//
//  PrimerLayout.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CoreGraphics

// MARK: - Primer Spacing

struct PrimerSpacing {
    static func xxsmall(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSpaceXxsmall ?? 2
    }

    static func xsmall(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSpaceXsmall ?? 4
    }

    static func small(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSpaceSmall ?? 8
    }

    static func medium(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSpaceMedium ?? 12
    }

    static func large(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSpaceLarge ?? 16
    }

    static func xlarge(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSpaceXlarge ?? 20
    }

    static func xxlarge(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSpaceXxlarge ?? 24
    }
}

// MARK: - Primer Size

struct PrimerSize {
    static func small(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSizeSmall ?? 16
    }

    static func medium(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSizeMedium ?? 20
    }

    static func large(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSizeLarge ?? 24
    }

    static func xlarge(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSizeXlarge ?? 32
    }

    static func xxlarge(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSizeXxlarge ?? 44
    }

    static func xxxlarge(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerSizeXxxlarge ?? 56
    }
}

// MARK: - Primer Radius

struct PrimerRadius {
    static func xsmall(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerRadiusXsmall ?? 2
    }

    static func small(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerRadiusSmall ?? 4
    }

    static func medium(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerRadiusMedium ?? 8
    }

    static func large(tokens: DesignTokens?) -> CGFloat {
        tokens?.primerRadiusLarge ?? 12
    }
}

// MARK: - Primer Component Heights

struct PrimerComponentHeight {
    static let label: CGFloat = 16
    static let errorMessage: CGFloat = 16
    static let keyboardAccessory: CGFloat = 44
    static let paymentMethodCard: CGFloat = 44
    static let progressIndicator: CGFloat = 56
}

// MARK: - Primer Component Widths

struct PrimerComponentWidth {
    static let paymentMethodIcon: CGFloat = 32
    static let cvvFieldMax: CGFloat = 120
}

// MARK: - Primer Border Widths

struct PrimerBorderWidth {
    static let thin: CGFloat = 0.5
    static let standard: CGFloat = 1
}

// MARK: - Primer Scale Factors

struct PrimerScale {
    static let large: CGFloat = 2.0
    static let small: CGFloat = 0.8
}

// MARK: - Primer Card Network Selector

struct PrimerCardNetworkSelector {
    static let badgeWidth: CGFloat = 28
    static let badgeHeight: CGFloat = 20
    static let buttonFrameWidth: CGFloat = 34
    static let buttonFrameHeight: CGFloat = 26
    static let buttonTotalWidth: CGFloat = 36
    static let selectedBorderHeight: CGFloat = 28
    static let chevronSize: CGFloat = 20
    static let chevronFontSize: CGFloat = 10
}
