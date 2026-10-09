//
//  PrimerInputFieldContainer+Styling.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
  var borderColor: Color {
    if !isInputEnabled {
      CheckoutColors.borderDisabled(tokens: tokens)
    } else if errorMessage?.isEmpty == false {
      errorBorderColor
    } else {
      isFocused ? focusedBorderColor : defaultBorderColor
    }
  }

  var labelForegroundColor: Color {
    isInputEnabled
      ? CheckoutColors.textPrimary(tokens: tokens)
      : CheckoutColors.textDisabled(tokens: tokens)
  }

  /// A locked field takes the disabled fill, the same token Android and React Native use for it.
  var fieldBackgroundColor: Color {
    isInputEnabled
      ? CheckoutColors.inputBackground(tokens: tokens)
      : CheckoutColors.backgroundOutlinedDisabled(tokens: tokens)
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
  var fieldCornerRadius: CGFloat { PrimerRadius.small(tokens: tokens) }
  var textFieldContainerBackgroundLineWidth: CGFloat {
    if hasError { return PrimerBorderWidth.error(tokens: tokens) }
    return isFocused
      ? PrimerBorderWidth.focused(tokens: tokens)
      : PrimerBorderWidth.standard(tokens: tokens)
  }
  var errorMessageMinHeight: CGFloat { hasError ? PrimerComponentHeight.errorMessage : 0 }
  var errorMessageTopPadding: CGFloat { hasError ? PrimerSpacing.xsmall(tokens: tokens) : 0 }
}
