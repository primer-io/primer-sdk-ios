//
//  HeadlessRepository.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Repository protocol for accessing the headless SDK functionality.
/// This abstracts the PrimerHeadlessUniversalCheckout SDK.
protocol HeadlessRepository {

    /// Fetches available payment methods.
    /// - Returns: Array of available payment methods.
    func getPaymentMethods() async throws -> [InternalPaymentMethod]

    /// Processes a card payment using RawDataManager.
    /// - Parameters:
    ///   - cardNumber: The card number.
    ///   - cvv: The CVV/CVC code.
    ///   - expiryMonth: The expiry month (MM).
    ///   - expiryYear: The expiry year (YY or YYYY).
    ///   - cardholderName: The name on the card.
    ///   - selectedNetwork: The selected card network for co-badged cards.
    /// - Returns: The payment result.
    func processCardPayment(
        cardNumber: String,
        cvv: String,
        expiryMonth: String,
        expiryYear: String,
        cardholderName: String,
        selectedNetwork: CardNetwork?
    ) async throws -> PaymentResult

    /// Sets the billing address for the current session.
    /// - Parameter billingAddress: The billing address data.
    func setBillingAddress(_ billingAddress: BillingAddress) async throws

    /// Gets a stream for real-time network detection events.
    /// - Returns: AsyncStream that emits detected card networks.
    func getNetworkDetectionStream() -> AsyncStream<[CardNetwork]>

    /// Updates card number in RawDataManager to trigger network detection.
    /// - Parameter cardNumber: The card number to update.
    func updateCardNumberInRawDataManager(_ cardNumber: String) async

    /// Handles user selection of a specific card network for co-badged cards.
    /// - Parameter cardNetwork: The selected card network.
    func selectCardNetwork(_ cardNetwork: CardNetwork) async
}
