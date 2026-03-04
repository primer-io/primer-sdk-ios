//
//  PrimerInputFieldContainer+Styling.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
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
    styling?.labelColor ?? CheckoutColors.textPrimary(tokens: tokens)
  }

  var errorMessageForegroundColor: Color {
    CheckoutColors.textNegative(tokens: tokens)
  }

  var errorBorderColor: Color {
    styling?.errorBorderColor ?? CheckoutColors.borderError(tokens: tokens)
  }

  var focusedBorderColor: Color {
    styling?.focusedBorderColor ?? CheckoutColors.borderFocus(tokens: tokens)
  }

  var defaultBorderColor: Color {
    styling?.borderColor ?? CheckoutColors.borderDefault(tokens: tokens)
  }
}

// MARK: - Fonts
@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
  var errorMessageFont: Font { PrimerFont.bodySmall(tokens: tokens) }
  var labelFont: Font {
    styling?.resolvedLabelFont(tokens: tokens) ?? PrimerFont.bodySmall(tokens: tokens)
  }
}

// MARK: - Spacing & Frame
@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
  var fieldCornerRadius: CGFloat { styling?.cornerRadius ?? PrimerRadius.small(tokens: tokens) }
  var textFieldContainerBackgroundLineWidth: CGFloat {
    styling?.borderWidth ?? PrimerBorderWidth.standard
  }
  var errorMessageHeight: CGFloat { hasError ? PrimerComponentHeight.errorMessage : 0 }
  var errorMessageTopPadding: CGFloat { hasError ? PrimerSpacing.xsmall(tokens: tokens) : 0 }
}
