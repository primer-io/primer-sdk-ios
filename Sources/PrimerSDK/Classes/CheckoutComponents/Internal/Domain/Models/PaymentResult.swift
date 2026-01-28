//
//  PaymentResult.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Represents the result of a completed payment transaction.
///
/// `PaymentResult` contains all relevant information about a payment after it has been processed,
/// including its status, identifiers, and any additional metadata returned by the payment processor.
///
/// Use this struct to access payment details in your completion handlers or when observing
/// checkout state changes.
///
/// Example usage:
/// ```swift
/// for await state in checkoutScope.state {
///     if case .success(let result) = state {
///         print("Payment \(result.paymentId) completed with status: \(result.status)")
///     }
/// }
/// ```
public struct PaymentResult {
  /// The unique identifier for this payment, assigned by Primer.
  public let paymentId: String

  /// The current status of the payment.
  public let status: PaymentStatus

  /// The payment method token used for this transaction, if available.
  public let token: String?

  /// A URL for redirect-based payment flows, if applicable.
  public let redirectUrl: String?

  /// An error message if the payment failed, describing what went wrong.
  public let errorMessage: String?

  /// Additional metadata associated with the payment, as key-value pairs.
  public let metadata: [String: Any]?

  /// The payment amount in minor currency units (e.g., cents for USD).
  public let amount: Int?

  /// The ISO 4217 currency code (e.g., "USD", "EUR", "GBP").
  public let currencyCode: String?

  /// The type of payment method used (e.g., "PAYMENT_CARD", "PAYPAL").
  public let paymentMethodType: String?

  public init(
    paymentId: String,
    status: PaymentStatus,
    token: String? = nil,
    redirectUrl: String? = nil,
    errorMessage: String? = nil,
    metadata: [String: Any]? = nil,
    amount: Int? = nil,
    currencyCode: String? = nil,
    paymentMethodType: String? = nil
  ) {
    self.paymentId = paymentId
    self.status = status
    self.token = token
    self.redirectUrl = redirectUrl
    self.errorMessage = errorMessage
    self.metadata = metadata
    self.amount = amount
    self.currencyCode = currencyCode
    self.paymentMethodType = paymentMethodType
  }
}

/// Represents the status of a payment at any point during or after processing.
///
/// Use `PaymentStatus` to determine the outcome of a payment and take appropriate action
/// in your application, such as displaying a success message or prompting the user to
/// complete additional authentication.
public enum PaymentStatus {
  /// The payment has been created but processing has not yet started.
  case pending

  /// The payment is currently being processed by the payment processor.
  case processing

  /// The payment has been authorized but not yet captured.
  /// This status is common for card payments where capture happens separately.
  case authorized

  /// The payment completed successfully.
  case success

  /// The payment failed due to an error (e.g., insufficient funds, declined).
  case failed

  /// The payment was cancelled by the user or merchant.
  case cancelled

  /// The payment requires 3D Secure authentication to proceed.
  /// The SDK will automatically handle 3DS challenges when configured.
  case requires3DS

  /// The payment requires additional action from the user or merchant.
  /// This may include redirect-based authentication or manual confirmation.
  case requiresAction

  init(from apiStatus: Response.Body.Payment.Status) {
    switch apiStatus {
    case .success: self = .success
    case .pending: self = .pending
    case .failed: self = .failed
    }
  }
}
