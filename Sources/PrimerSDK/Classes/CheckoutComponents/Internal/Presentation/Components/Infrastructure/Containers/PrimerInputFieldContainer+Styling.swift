//
//  PrimerInputFieldContainer+Styling.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Colors
@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
    var borderColor: Color {
        if errorMessage?.isEmpty == false {
            errorBorderColor
        } else {
            isFocused ? focusedBorderColor : defaultBorderColor
        }
    }

    var labelForegroundColor: Color {
        styling?.labelColor ?? PrimerCheckoutColors.textPrimary(tokens: tokens)
    }

    var errorMessageForegroundColor: Color {
        PrimerCheckoutColors.textNegative(tokens: tokens)
    }

    var errorBorderColor: Color {
        styling?.errorBorderColor ?? PrimerCheckoutColors.borderError(tokens: tokens)
    }

    var focusedBorderColor: Color {
        styling?.focusedBorderColor ?? PrimerCheckoutColors.borderFocus(tokens: tokens)
    }

    var defaultBorderColor: Color {
        styling?.borderColor ?? PrimerCheckoutColors.borderDefault(tokens: tokens)
    }
}

// MARK: - Fonts
@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
    var errorMessageFont: Font { PrimerFont.bodySmall(tokens: tokens) }
    var labelFont: Font { styling?.labelFont ?? PrimerFont.bodySmall(tokens: tokens) }
}

// MARK: - Spacing & Frame
@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
    var textFieldContainerBackgroundLineWidth: CGFloat { styling?.borderWidth ?? PrimerBorderWidth.standard }
    var errorMessageHeight: CGFloat { hasError ? PrimerComponentHeight.errorMessage : 0 }
    var errorMessageTopPadding: CGFloat { hasError ? PrimerSpacing.xsmall(tokens: tokens) : 0 }
}
