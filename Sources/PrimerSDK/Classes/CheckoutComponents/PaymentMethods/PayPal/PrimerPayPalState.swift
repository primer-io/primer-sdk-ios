//
//  PrimerPayPalState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// State model for PayPal payment method scope.
/// Tracks the current step of the PayPal payment flow.
@available(iOS 15.0, *)
public struct PrimerPayPalState: Equatable {

  /// The current step of the PayPal payment flow.
  public enum Step: Equatable {
    /// Initial state, ready to start payment
    case idle
    /// Creating PayPal session
    case loading
    /// Web authentication session is open
    case redirecting
    /// Processing payment after user approval
    case processing
    /// Payment completed successfully
    case success
    /// Payment failed with error message
    case failure(String)
  }

  /// Current step of the PayPal flow
  public var step: Step

  /// The PayPal payment method information
  public var paymentMethod: CheckoutPaymentMethod?

  /// Formatted surcharge amount if applicable (e.g., "+ $1.50")
  public var surchargeAmount: String?

  /// Default initializer
  public init(
    step: Step = .idle,
    paymentMethod: CheckoutPaymentMethod? = nil,
    surchargeAmount: String? = nil
  ) {
    self.step = step
    self.paymentMethod = paymentMethod
    self.surchargeAmount = surchargeAmount
  }
}
