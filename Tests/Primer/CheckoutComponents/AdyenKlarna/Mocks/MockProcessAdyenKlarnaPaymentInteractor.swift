//
//  MockProcessAdyenKlarnaPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockProcessAdyenKlarnaPaymentInteractor: ProcessAdyenKlarnaPaymentInteractor {

    // MARK: - Configuration

    var fetchPaymentOptionsResult: Result<[AdyenKlarnaPaymentOption], Error> = .success([])
    var executeResult: Result<PaymentResult, Error> = .success(
        PaymentResult(paymentId: "pay-123", status: .success, amount: 1000, currencyCode: "EUR", paymentMethodType: "ADYEN_KLARNA")
    )

    // MARK: - Call Tracking

    private(set) var fetchPaymentOptionsCallCount = 0
    private(set) var executeCallCount = 0
    private(set) var lastSelectedOption: AdyenKlarnaPaymentOption?

    // MARK: - ProcessAdyenKlarnaPaymentInteractor

    func fetchPaymentOptions() async throws -> [AdyenKlarnaPaymentOption] {
        fetchPaymentOptionsCallCount += 1
        return try fetchPaymentOptionsResult.get()
    }

    func execute(selectedOption: AdyenKlarnaPaymentOption) async throws -> PaymentResult {
        executeCallCount += 1
        lastSelectedOption = selectedOption
        return try executeResult.get()
    }
}
