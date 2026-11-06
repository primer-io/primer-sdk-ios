//
//  WebRedirectRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// The payment exists before the shopper leaves for the third party.
struct RedirectPayment: Equatable {
    let redirectUrl: URL
    let statusUrl: URL
    let paymentId: String?
}

@available(iOS 15.0, *)
protocol WebRedirectRepository {
    func tokenize(
        paymentMethodType: String, sessionInfo: WebRedirectSessionInfo
    ) async throws -> RedirectPayment
    func openWebAuthentication(paymentMethodType: String, url: URL) async throws -> URL
    func pollForCompletion(statusUrl: URL) async throws -> String
    func resumePayment(
        paymentMethodType: String, resumeToken: String
    ) async throws -> PaymentResult
    func cancelPolling(paymentMethodType: String)
}
