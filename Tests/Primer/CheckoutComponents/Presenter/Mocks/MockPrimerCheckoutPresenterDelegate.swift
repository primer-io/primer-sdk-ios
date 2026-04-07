//
//  MockPrimerCheckoutPresenterDelegate.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockPrimerCheckoutPresenterDelegate: PrimerCheckoutPresenterDelegate {

    private(set) var didCompleteWithSuccessCallCount = 0
    private(set) var capturedSuccessResult: PaymentResult?

    private(set) var didFailWithErrorCallCount = 0
    private(set) var capturedError: PrimerError?

    private(set) var didDismissCallCount = 0

    private(set) var willPresent3DSChallengeCallCount = 0
    private(set) var capturedTokenData: PrimerPaymentMethodTokenData?

    private(set) var didDismiss3DSChallengeCallCount = 0

    private(set) var didComplete3DSChallengeCallCount = 0
    private(set) var capturedThreeDSSuccess: Bool?
    private(set) var capturedResumeToken: String?
    private(set) var capturedThreeDSError: Error?

    func primerCheckoutPresenterDidCompleteWithSuccess(_ result: PaymentResult) {
        didCompleteWithSuccessCallCount += 1
        capturedSuccessResult = result
    }

    func primerCheckoutPresenterDidFailWithError(_ error: PrimerError) {
        didFailWithErrorCallCount += 1
        capturedError = error
    }

    func primerCheckoutPresenterDidDismiss() {
        didDismissCallCount += 1
    }

    func primerCheckoutPresenterWillPresent3DSChallenge(
        _ paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) {
        willPresent3DSChallengeCallCount += 1
        capturedTokenData = paymentMethodTokenData
    }

    func primerCheckoutPresenterDidDismiss3DSChallenge() {
        didDismiss3DSChallengeCallCount += 1
    }

    func primerCheckoutPresenterDidComplete3DSChallenge(
        success: Bool, resumeToken: String?, error: Error?
    ) {
        didComplete3DSChallengeCallCount += 1
        capturedThreeDSSuccess = success
        capturedResumeToken = resumeToken
        capturedThreeDSError = error
    }

    func reset() {
        didCompleteWithSuccessCallCount = 0
        capturedSuccessResult = nil
        didFailWithErrorCallCount = 0
        capturedError = nil
        didDismissCallCount = 0
        willPresent3DSChallengeCallCount = 0
        capturedTokenData = nil
        didDismiss3DSChallengeCallCount = 0
        didComplete3DSChallengeCallCount = 0
        capturedThreeDSSuccess = nil
        capturedResumeToken = nil
        capturedThreeDSError = nil
    }
}
