//
//  ProcessCardPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

struct CardPaymentData {
  let cardNumber: String
  let cvv: String
  let expiryMonth: String
  let expiryYear: String
  let cardholderName: String
  let selectedNetwork: CardNetwork?
}

protocol ProcessCardPaymentInteractor {
  func execute(cardData: CardPaymentData) async throws -> PaymentResult
  /// Saves the card as a multi-use token and creates no payment.
  func vault(cardData: CardPaymentData) async throws -> PrimerPaymentMethodToken
}

@available(iOS 15.0, *)
final class ProcessCardPaymentInteractorImpl: ProcessCardPaymentInteractor, LogReporter {

  private let repository: HeadlessRepository

  init(repository: HeadlessRepository) {
    self.repository = repository
  }

  func execute(cardData: CardPaymentData) async throws -> PaymentResult {
    do {
      let startTime = CFAbsoluteTimeGetCurrent()
      let result = try await repository.processCardPayment(
        cardNumber: cardData.cardNumber,
        cvv: cardData.cvv,
        expiryMonth: cardData.expiryMonth,
        expiryYear: cardData.expiryYear,
        cardholderName: cardData.cardholderName,
        selectedNetwork: cardData.selectedNetwork
      )

      let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
      logger.info(
        message: "[PERF] Card payment processed in \(String(format: "%.0f", duration))ms: \(result.paymentId)"
      )
      return result
    } catch {
      logger.error(message: "Card payment processing failed: \(error)", error: error)
      throw error
    }
  }

  func vault(cardData: CardPaymentData) async throws -> PrimerPaymentMethodToken {
    do {
      return try await repository.vaultCard(
        cardNumber: cardData.cardNumber,
        cvv: cardData.cvv,
        expiryMonth: cardData.expiryMonth,
        expiryYear: cardData.expiryYear,
        cardholderName: cardData.cardholderName,
        selectedNetwork: cardData.selectedNetwork
      )
    } catch {
      logger.error(message: "Saving the card failed: \(error)", error: error)
      throw error
    }
  }
}
