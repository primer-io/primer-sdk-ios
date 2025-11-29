//
//  ProcessCardPaymentInteractor.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Card payment data for processing.
struct CardPaymentData {
    let cardNumber: String
    let cvv: String
    let expiryMonth: String
    let expiryYear: String
    let cardholderName: String
    let selectedNetwork: CardNetwork?
    let billingAddress: BillingAddress?
}

/// Billing address data.
struct BillingAddress {
    let firstName: String?
    let lastName: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let countryCode: String?
    let phoneNumber: String?
}

/// Protocol for processing card payments.
protocol ProcessCardPaymentInteractor {
    /// Processes a card payment with the provided data.
    /// - Parameter cardData: The card payment data to process.
    /// - Returns: The payment result.
    func execute(cardData: CardPaymentData) async throws -> PaymentResult
}

/// Default implementation using RawDataManager internally.
final class ProcessCardPaymentInteractorImpl: ProcessCardPaymentInteractor, LogReporter {
    private let repository: HeadlessRepository

    init(repository: HeadlessRepository) {
        self.repository = repository
    }

    func execute(cardData: CardPaymentData) async throws -> PaymentResult {
        logger.info(message: "Processing card payment")

        do {
            // First, send billing address if provided
            if let billingAddress = cardData.billingAddress {
                logger.debug(message: "Sending billing address")
                try await repository.setBillingAddress(billingAddress)
            }

            // Then process the card payment
            logger.debug(message: "Processing card tokenization and payment")
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
            logger.info(message: "[PERF] Card payment processed in \(String(format: "%.0f", duration))ms: \(result.paymentId)")
            return result

        } catch {
            logger.error(message: "Card payment processing failed: \(error)")
            throw error
        }
    }
}
