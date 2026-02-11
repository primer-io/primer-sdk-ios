//
//  ProcessFormRedirectPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Interactor Protocol

@available(iOS 15.0, *)
protocol ProcessFormRedirectPaymentInteractor {

    /// - Parameter onPollingStarted: Invoked when polling begins, signaling the user needs to complete payment in an external app
    func execute(
        paymentMethodType: String,
        sessionInfo: any OffSessionPaymentSessionInfo,
        onPollingStarted: (() -> Void)?
    ) async throws -> PaymentResult

    func cancelPolling(paymentMethodType: String)
}
