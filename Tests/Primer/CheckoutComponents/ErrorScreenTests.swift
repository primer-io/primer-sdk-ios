//
//  ErrorScreenTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
final class ErrorScreenTests: XCTestCase {

    private func makeError(message: String = "Payment failed") -> PrimerError {
        PrimerError.unknown(message: message, diagnosticsId: "test_diagnostics")
    }

    // MARK: - View Creation Tests

    func test_viewCreation_withBothCallbacks_doesNotCrash() {
        let view = ErrorScreen(
            error: makeError(),
            onRetry: {},
            onChooseOtherPaymentMethods: {}
        )
        XCTAssertNotNil(view)
    }

    func test_viewCreation_withNilCallbacks_doesNotCrash() {
        let view = ErrorScreen(error: makeError())
        XCTAssertNotNil(view)
    }

    func test_viewCreation_withNilChooseOther_doesNotCrash() {
        let view = ErrorScreen(
            error: makeError(),
            onRetry: {},
            onChooseOtherPaymentMethods: nil
        )
        XCTAssertNotNil(view)
    }

    // MARK: - Callback Tests

    func test_onRetry_isInvoked() {
        var retryCallCount = 0
        let sut = ErrorScreen(
            error: makeError(),
            onRetry: { retryCallCount += 1 }
        )

        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.onRetry)
    }

    func test_onChooseOtherPaymentMethods_whenNil_isNil() {
        let sut = ErrorScreen(
            error: makeError(),
            onRetry: {},
            onChooseOtherPaymentMethods: nil
        )

        XCTAssertNil(sut.onChooseOtherPaymentMethods)
    }

    func test_onChooseOtherPaymentMethods_whenProvided_isNotNil() {
        let sut = ErrorScreen(
            error: makeError(),
            onRetry: {},
            onChooseOtherPaymentMethods: {}
        )

        XCTAssertNotNil(sut.onChooseOtherPaymentMethods)
    }
}
