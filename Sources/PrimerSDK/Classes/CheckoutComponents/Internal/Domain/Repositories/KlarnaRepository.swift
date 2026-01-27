//
//  KlarnaRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

/// Result of creating a Klarna payment session.
@available(iOS 15.0, *)
struct KlarnaSessionResult {
    let clientToken: String
    let sessionId: String
    let categories: [KlarnaPaymentCategory]
    let hppSessionId: String?
}

/// Result of authorizing or finalizing a Klarna payment session.
@available(iOS 15.0, *)
enum KlarnaAuthorizationResult: Equatable {
    /// Authorization approved with token; no finalization needed.
    case approved(authToken: String)
    /// Authorization approved but finalization is required before completing.
    case finalizationRequired(authToken: String)
    /// User declined or did not approve the session.
    case declined
}

/// Abstracts Klarna payment operations for CheckoutComponents.
/// Provides clean separation from the legacy SDK's Klarna headless component.
@available(iOS 15.0, *)
protocol KlarnaRepository {

    /// Creates a Klarna payment session (handles both checkout and vault flows).
    /// - Returns: Session result containing client token, session ID, and available categories.
    /// - Throws: Error if session creation fails.
    func createSession() async throws -> KlarnaSessionResult

    /// Configures the Klarna SDK for the selected payment category and loads the payment view.
    /// - Parameters:
    ///   - clientToken: The Klarna client token from session creation.
    ///   - categoryId: The selected payment category identifier.
    /// - Returns: The loaded Klarna SDK payment view, or nil for test flows.
    /// - Throws: Error if view loading fails.
    func configureForCategory(clientToken: String, categoryId: String) async throws -> UIView?

    /// Authorizes the Klarna payment session.
    /// - Returns: The authorization result (approved, finalizationRequired, or declined).
    /// - Throws: Error if authorization fails.
    func authorize() async throws -> KlarnaAuthorizationResult

    /// Finalizes the Klarna payment session after authorization indicated finalization is required.
    /// - Returns: The finalization result.
    /// - Throws: Error if finalization fails.
    func finalize() async throws -> KlarnaAuthorizationResult

    /// Tokenizes the Klarna payment and processes the payment.
    /// - Parameter authToken: The authorization token from the authorize or finalize step.
    /// - Returns: The payment result.
    /// - Throws: Error if tokenization or payment processing fails.
    func tokenize(authToken: String) async throws -> PaymentResult
}
