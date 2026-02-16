//
//  FormRedirectRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Repository Protocol

@available(iOS 15.0, *)
protocol FormRedirectRepository {

    func tokenize(
        paymentMethodType: String,
        sessionInfo: any OffSessionPaymentSessionInfo
    ) async throws -> FormRedirectTokenizationResponse

    func createPayment(token: String, paymentMethodType: String) async throws -> FormRedirectPaymentResponse

    func resumePayment(paymentId: String, resumeToken: String, paymentMethodType: String) async throws -> FormRedirectPaymentResponse

    func pollForCompletion(statusUrl: URL) async throws -> String

    func cancelPolling(error: PrimerError)
}

// MARK: - Response Models

@available(iOS 15.0, *)
struct FormRedirectTokenizationResponse {
    let tokenData: PrimerPaymentMethodTokenData
}

@available(iOS 15.0, *)
struct FormRedirectPaymentResponse {
    let paymentId: String
    let status: Response.Body.Payment.Status

    /// Present when status is PENDING; URL to poll for payment completion
    let statusUrl: URL?
}
