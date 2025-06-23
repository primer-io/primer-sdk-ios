//
//  HeadlessRepository.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Repository protocol for accessing the headless SDK functionality.
/// This abstracts the PrimerHeadlessUniversalCheckout SDK.
internal protocol HeadlessRepository {

    /// Initializes the checkout session with a client token.
    /// - Parameter clientToken: The client token from the merchant backend.
    func initialize(clientToken: String) async throws

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

    /// Tokenizes card data without processing payment.
    /// - Parameters:
    ///   - cardNumber: The card number.
    ///   - cvv: The CVV/CVC code.
    ///   - expiryMonth: The expiry month (MM).
    ///   - expiryYear: The expiry year (YY or YYYY).
    ///   - cardholderName: The name on the card.
    ///   - selectedNetwork: The selected card network for co-badged cards.
    /// - Returns: The tokenization result.
    func tokenizeCard(
        cardNumber: String,
        cvv: String,
        expiryMonth: String,
        expiryYear: String,
        cardholderName: String,
        selectedNetwork: CardNetwork?
    ) async throws -> TokenizationResult

    /// Sets the billing address for the current session.
    /// - Parameter billingAddress: The billing address data.
    func setBillingAddress(_ billingAddress: BillingAddress) async throws

    /// Detects available card networks for a given card number.
    /// - Parameter cardNumber: The card number to check.
    /// - Returns: Array of available card networks, or nil if not co-badged.
    func detectCardNetworks(for cardNumber: String) async -> [CardNetwork]?
}
