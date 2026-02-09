//
//  BankSelectorRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Abstracts bank selector operations for CheckoutComponents.
/// Provides clean separation from the legacy SDK's BanksTokenizationComponent.
@available(iOS 15.0, *)
protocol BankSelectorRepository {

  /// Fetches the list of available banks for a given payment method.
  /// - Parameters:
  ///   - paymentMethodConfigId: The configuration ID for the payment method.
  ///   - paymentMethod: The payment method identifier (e.g., "ideal", "dotpay").
  /// - Returns: Array of AdyenBank models from the API.
  /// - Throws: Error if the bank list fetch fails.
  func fetchBanks(
    paymentMethodConfigId: String,
    paymentMethod: String
  ) async throws -> [AdyenBank]

  /// Tokenizes the selected bank and returns a payment result.
  /// - Parameters:
  ///   - paymentMethodConfigId: The configuration ID for the payment method.
  ///   - paymentMethodType: The raw payment method type (e.g., "ADYEN_IDEAL").
  ///   - bankId: The selected bank's identifier.
  /// - Returns: The payment result after tokenization.
  /// - Throws: Error if tokenization fails.
  func tokenize(
    paymentMethodConfigId: String,
    paymentMethodType: String,
    bankId: String
  ) async throws -> PaymentResult
}
