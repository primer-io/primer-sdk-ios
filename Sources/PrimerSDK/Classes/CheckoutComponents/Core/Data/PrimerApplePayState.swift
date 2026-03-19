//
//  PrimerApplePayState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PassKit

@available(iOS 15.0, *)
public struct PrimerApplePayState: Equatable {

  public internal(set) var isLoading: Bool
  public internal(set) var isAvailable: Bool
  public internal(set) var availabilityError: String?

  public internal(set) var buttonStyle: PKPaymentButtonStyle
  public internal(set) var buttonType: PKPaymentButtonType
  public internal(set) var cornerRadius: CGFloat

  public init(
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

  public static var `default`: PrimerApplePayState {
    PrimerApplePayState()
  }

  public static func available(
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

  public static func unavailable(error: String) -> PrimerApplePayState {
    PrimerApplePayState(
      isLoading: false,
      isAvailable: false,
      availabilityError: error
    )
  }

  public static var loading: PrimerApplePayState {
    PrimerApplePayState(
      isLoading: true,
      isAvailable: true,
      availabilityError: nil
    )
  }
}
