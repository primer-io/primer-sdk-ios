//
//  ProcessBankSelectorPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Interactor protocol for bank selector payment methods (iDEAL, Dotpay).
@available(iOS 15.0, *)
protocol ProcessBankSelectorPaymentInteractor {

  /// Fetches available banks for the given payment method type.
  /// - Parameter paymentMethodType: The raw payment method type (e.g., "ADYEN_IDEAL").
  /// - Returns: Array of public Bank models.
  func fetchBanks(paymentMethodType: String) async throws -> [Bank]

  /// Tokenizes with the selected bank and processes the payment.
  /// - Parameters:
  ///   - bankId: The selected bank's identifier.
  ///   - paymentMethodType: The raw payment method type (e.g., "ADYEN_IDEAL").
  /// - Returns: The payment result.
  func execute(bankId: String, paymentMethodType: String) async throws -> PaymentResult
}

/// Implementation that resolves payment config, delegates to repository,
/// and maps internal AdyenBank models to public Bank models.
@available(iOS 15.0, *)
final class ProcessBankSelectorPaymentInteractorImpl: ProcessBankSelectorPaymentInteractor, LogReporter {

  private let repository: BankSelectorRepository

  init(repository: BankSelectorRepository) {
    self.repository = repository
  }

  func fetchBanks(paymentMethodType: String) async throws -> [Bank] {
    let (configId, paymentMethod) = try resolveConfig(for: paymentMethodType)

    logger.debug(message: "Fetching banks for \(paymentMethodType) (method: \(paymentMethod))")

    let adyenBanks = try await repository.fetchBanks(
      paymentMethodConfigId: configId,
      paymentMethod: paymentMethod
    )

    return adyenBanks.map { Bank(from: $0) }
  }

  func execute(bankId: String, paymentMethodType: String) async throws -> PaymentResult {
    let (configId, _) = try resolveConfig(for: paymentMethodType)

    logger.debug(message: "Starting bank selector payment for bank: \(bankId)")

    let result = try await repository.tokenize(
      paymentMethodConfigId: configId,
      paymentMethodType: paymentMethodType,
      bankId: bankId
    )

    logger.debug(message: "Bank selector payment completed successfully")
    return result
  }

  // MARK: - Private Helpers

  /// Resolves the payment method configuration and API payment method name.
  private func resolveConfig(for paymentMethodType: String) throws -> (configId: String, paymentMethod: String) {
    guard let config = PrimerAPIConfiguration.current?.paymentMethods?
      .first(where: { $0.type == paymentMethodType })
    else {
      throw PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType)
    }

    guard let configId = config.id else {
      throw PrimerError.invalidValue(key: "paymentMethodConfig.id")
    }

    let paymentMethod: String
    switch paymentMethodType {
    case PrimerPaymentMethodType.adyenIDeal.rawValue:
      paymentMethod = "ideal"
    case PrimerPaymentMethodType.adyenDotPay.rawValue:
      paymentMethod = "dotpay"
    default:
      paymentMethod = ""
    }

    return (configId, paymentMethod)
  }
}
