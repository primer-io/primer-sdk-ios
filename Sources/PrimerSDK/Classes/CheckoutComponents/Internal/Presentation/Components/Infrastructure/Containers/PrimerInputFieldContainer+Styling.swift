//
//  PrimerInputFieldContainer+Styling.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

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
    CheckoutColors.textPrimary(tokens: tokens)
  }

  var errorMessageForegroundColor: Color {
    CheckoutColors.textNegative(tokens: tokens)
  }

  var errorBorderColor: Color {
    CheckoutColors.borderError(tokens: tokens)
  }

  var focusedBorderColor: Color {
    CheckoutColors.borderFocus(tokens: tokens)
  }

  var defaultBorderColor: Color {
    CheckoutColors.borderDefault(tokens: tokens)
  }
}

@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
  var errorMessageFont: Font { PrimerFont.bodySmall(tokens: tokens) }
  var labelFont: Font { PrimerFont.bodySmall(tokens: tokens) }
}

@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
  var fieldCornerRadius: CGFloat { PrimerRadius.small(tokens: tokens) }
  var textFieldContainerBackgroundLineWidth: CGFloat { PrimerBorderWidth.standard(tokens: tokens) }
  var errorMessageMinHeight: CGFloat { hasError ? PrimerComponentHeight.errorMessage : 0 }
  var errorMessageTopPadding: CGFloat { hasError ? PrimerSpacing.xsmall(tokens: tokens) : 0 }
}
