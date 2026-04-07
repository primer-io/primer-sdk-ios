//
//  AdyenKlarnaRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
protocol AdyenKlarnaRepository {
    func fetchPaymentOptions(configId: String) async throws -> [AdyenKlarnaPaymentOption]
    func tokenize(
        paymentMethodType: String, sessionInfo: AdyenKlarnaSessionInfo
    ) async throws -> (redirectUrl: URL, statusUrl: URL)
    func openWebAuthentication(paymentMethodType: String, url: URL) async throws -> URL
    func pollForCompletion(statusUrl: URL) async throws -> String
    func resumePayment(
        paymentMethodType: String, resumeToken: String
    ) async throws -> PaymentResult
    func cancelPolling(paymentMethodType: String)
}
