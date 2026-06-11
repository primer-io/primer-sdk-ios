//
//  PrimerApplePayState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PassKit
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct PrimerApplePayState: Equatable, Sendable {

  var isLoading: Bool
  var isAvailable: Bool
  var availabilityError: String?

  var buttonStyle: PKPaymentButtonStyle
  var buttonType: PKPaymentButtonType
  var cornerRadius: CGFloat

  init(
    isLoading: Bool = false,
    isAvailable: Bool = false,
    availabilityError: String? = nil,
    buttonStyle: PKPaymentButtonStyle = .black,
    buttonType: PKPaymentButtonType = .plain,
    cornerRadius: CGFloat = 8.0
  ) {
    self.isLoading = isLoading
    self.isAvailable = isAvailable
    self.availabilityError = availabilityError
    self.buttonStyle = buttonStyle
    self.buttonType = buttonType
    self.cornerRadius = cornerRadius
  }

  static var `default`: PrimerApplePayState {
    PrimerApplePayState()
  }

  static func available(
    buttonStyle: PKPaymentButtonStyle = .black,
    buttonType: PKPaymentButtonType = .plain,
    cornerRadius: CGFloat = 8.0
  ) -> PrimerApplePayState {
    PrimerApplePayState(
      isLoading: false,
      isAvailable: true,
      availabilityError: nil,
      buttonStyle: buttonStyle,
      buttonType: buttonType,
      cornerRadius: cornerRadius
    )
  }

  static func unavailable(error: String) -> PrimerApplePayState {
    PrimerApplePayState(
      isLoading: false,
      isAvailable: false,
      availabilityError: error
    )
  }

  static var loading: PrimerApplePayState {
    PrimerApplePayState(
      isLoading: true,
      isAvailable: true,
      availabilityError: nil
    )
  }
}
