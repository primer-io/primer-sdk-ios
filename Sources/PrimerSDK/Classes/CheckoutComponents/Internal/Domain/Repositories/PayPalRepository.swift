//
//  PayPalRepository.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Result model for PayPal billing agreement confirmation.
@available(iOS 15.0, *)
struct PayPalBillingAgreementResult: Equatable {
    let billingAgreementId: String
    let externalPayerInfo: PayPalPayerInfo?
    let shippingAddress: PayPalShippingAddress?
}

/// PayPal payer information model.
@available(iOS 15.0, *)
struct PayPalPayerInfo: Equatable {
    let externalPayerId: String?
    let email: String?
    let firstName: String?
    let lastName: String?
}

/// PayPal shipping address model.
@available(iOS 15.0, *)
struct PayPalShippingAddress: Equatable {
    let firstName: String?
    let lastName: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let state: String?
    let countryCode: String?
    let postalCode: String?
}

/// PayPal payment instrument for tokenization.
@available(iOS 15.0, *)
enum PayPalPaymentInstrumentData {
    /// Checkout flow payment instrument with order ID and payer info
    case order(orderId: String, payerInfo: PayPalPayerInfo?)
    /// Vault flow payment instrument with billing agreement result
    case billingAgreement(result: PayPalBillingAgreementResult)
}

/// Abstracts PayPal payment operations for CheckoutComponents.
/// Provides clean separation from the legacy SDK's PayPalService.
@available(iOS 15.0, *)
protocol PayPalRepository {

    /// Starts a PayPal order session for checkout (one-time payment) flow.
    /// - Returns: Tuple containing the order ID and approval URL for web authentication.
    /// - Throws: Error if session creation fails.
    func startOrderSession() async throws -> (orderId: String, approvalUrl: String)

    /// Starts a PayPal billing agreement session for vault (recurring payment) flow.
    /// - Returns: The approval URL for web authentication.
    /// - Throws: Error if session creation fails.
    func startBillingAgreementSession() async throws -> String

    /// Opens web authentication to the PayPal approval URL.
    /// - Parameter url: The PayPal approval URL to open.
    /// - Returns: The callback URL after user completes approval.
    /// - Throws: Error if authentication fails or user cancels.
    func openWebAuthentication(url: URL) async throws -> URL

    /// Confirms a billing agreement after user approval.
    /// - Returns: The billing agreement confirmation result.
    /// - Throws: Error if confirmation fails.
    func confirmBillingAgreement() async throws -> PayPalBillingAgreementResult

    /// Fetches payer information after order approval.
    /// - Parameter orderId: The PayPal order ID from session creation.
    /// - Returns: The payer information.
    /// - Throws: Error if fetch fails.
    func fetchPayerInfo(orderId: String) async throws -> PayPalPayerInfo

    /// Tokenizes the PayPal payment instrument and processes the payment.
    /// - Parameter paymentInstrument: The payment instrument data (order or billing agreement).
    /// - Returns: The payment result.
    /// - Throws: Error if tokenization or payment fails.
    func tokenize(paymentInstrument: PayPalPaymentInstrumentData) async throws -> PaymentResult
}
