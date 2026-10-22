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
  /// The network the shopper picked, sent with the card as its preferred network.
  let selectedNetwork: CardNetwork?
  /// The network the card form shows, the pick or the default; the surcharge follows it.
  let surchargeNetwork: CardNetwork?
}

protocol ProcessCardPaymentInteractor {
  func execute(cardData: CardPaymentData) async throws -> PaymentResult
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
        selectedNetwork: cardData.selectedNetwork,
        surchargeNetwork: cardData.surchargeNetwork
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
}
