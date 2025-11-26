//
//  HeadlessRepository.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Abstracts the PrimerHeadlessUniversalCheckout SDK.
protocol HeadlessRepository {

    func getPaymentMethods() async throws -> [InternalPaymentMethod]

    func processCardPayment(
        cardNumber: String,
        cvv: String,
        expiryMonth: String,
        expiryYear: String,
        cardholderName: String,
        selectedNetwork: CardNetwork?
    ) async throws -> PaymentResult

    func setBillingAddress(_ billingAddress: BillingAddress) async throws

    func getNetworkDetectionStream() -> AsyncStream<[CardNetwork]>

    func updateCardNumberInRawDataManager(_ cardNumber: String) async
    func selectCardNetwork(_ cardNetwork: CardNetwork) async
}
