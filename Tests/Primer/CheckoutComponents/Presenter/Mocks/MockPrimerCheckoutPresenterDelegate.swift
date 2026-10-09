//
//  MockPrimerCheckoutPresenterDelegate.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
final class MockPrimerCheckoutPresenterDelegate: PrimerCheckoutPresenterDelegate {

    private(set) var didCompleteWithSuccessCallCount = 0
    private(set) var capturedSuccessResult: PaymentResult?

    private(set) var didFailWithErrorCallCount = 0
    private(set) var capturedError: PrimerError?
    private(set) var capturedCheckoutData: PrimerCheckoutData?

    private(set) var didDismissCallCount = 0

    private(set) var capturedPaymentMethodTokens: [PrimerPaymentMethodToken] = []

    func primerCheckoutPresenterDidCompleteWithSuccess(_ result: PaymentResult) {
        didCompleteWithSuccessCallCount += 1
        capturedSuccessResult = result
    }

    func primerCheckoutPresenterDidVaultPaymentMethod(_ paymentMethodToken: PrimerPaymentMethodToken) {
        capturedPaymentMethodTokens.append(paymentMethodToken)
    }

    func primerCheckoutPresenterDidFailWithError(_ error: PrimerError, checkoutData: PrimerCheckoutData?) {
        didFailWithErrorCallCount += 1
        capturedError = error
        capturedCheckoutData = checkoutData
    }

    func primerCheckoutPresenterDidDismiss() {
        didDismissCallCount += 1
    }

    func reset() {
        didCompleteWithSuccessCallCount = 0
        capturedSuccessResult = nil
        didFailWithErrorCallCount = 0
        capturedError = nil
        didDismissCallCount = 0
    }
}
