//
//  CheckoutNavigationStateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class CheckoutNavigationStateTests: XCTestCase {

    // MARK: - Helpers

    private func makeVaultedPaymentMethod(id: String) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        let data = try! JSONSerialization.data(withJSONObject: ["last4Digits": "4242"]) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )
        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(id)"
        )
    }

    private func makePaymentResult(paymentId: String) -> PaymentResult {
        PaymentResult(paymentId: paymentId, status: .success)
    }

    private func makeError(message: String) -> PrimerError {
        PrimerError.unknown(message: message, diagnosticsId: "test_diagnostics")
    }

    // MARK: - Simple State Equality

    func test_loading_equalsLoading() {
        XCTAssertEqual(CheckoutNavigationState.loading, .loading)
    }

    func test_paymentMethodSelection_equalsPaymentMethodSelection() {
        XCTAssertEqual(CheckoutNavigationState.paymentMethodSelection, .paymentMethodSelection)
    }

    func test_vaultedPaymentMethods_equalsVaultedPaymentMethods() {
        XCTAssertEqual(CheckoutNavigationState.vaultedPaymentMethods, .vaultedPaymentMethods)
    }

    func test_processing_equalsProcessing() {
        XCTAssertEqual(CheckoutNavigationState.processing, .processing)
    }

    func test_dismissed_equalsDismissed() {
        XCTAssertEqual(CheckoutNavigationState.dismissed, .dismissed)
    }

    // MARK: - Payment Method Equality

    func test_paymentMethod_sameType_areEqual() {
        XCTAssertEqual(
            CheckoutNavigationState.paymentMethod("PAYMENT_CARD"),
            .paymentMethod("PAYMENT_CARD")
        )
    }

    func test_paymentMethod_differentType_areNotEqual() {
        XCTAssertNotEqual(
            CheckoutNavigationState.paymentMethod("PAYMENT_CARD"),
            .paymentMethod("PAYPAL")
        )
    }

    // MARK: - Success Equality

    func test_success_samePaymentId_areEqual() {
        let state1 = CheckoutNavigationState.success(makePaymentResult(paymentId: "pay_123"))
        let state2 = CheckoutNavigationState.success(makePaymentResult(paymentId: "pay_123"))
        XCTAssertEqual(state1, state2)
    }

    func test_success_differentPaymentId_areNotEqual() {
        let state1 = CheckoutNavigationState.success(makePaymentResult(paymentId: "pay_123"))
        let state2 = CheckoutNavigationState.success(makePaymentResult(paymentId: "pay_456"))
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Failure Equality

    func test_failure_sameError_areEqual() {
        let state1 = CheckoutNavigationState.failure(makeError(message: "Payment failed"))
        let state2 = CheckoutNavigationState.failure(makeError(message: "Payment failed"))
        XCTAssertEqual(state1, state2)
    }

    func test_failure_differentError_areNotEqual() {
        let state1 = CheckoutNavigationState.failure(makeError(message: "Payment failed"))
        let state2 = CheckoutNavigationState.failure(makeError(message: "Network error"))
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Delete Confirmation Equality

    func test_deleteConfirmation_sameMethod_areEqual() {
        let state1 = CheckoutNavigationState.deleteVaultedPaymentMethodConfirmation(makeVaultedPaymentMethod(id: "vault_123"))
        let state2 = CheckoutNavigationState.deleteVaultedPaymentMethodConfirmation(makeVaultedPaymentMethod(id: "vault_123"))
        XCTAssertEqual(state1, state2)
    }

    func test_deleteConfirmation_differentMethod_areNotEqual() {
        let state1 = CheckoutNavigationState.deleteVaultedPaymentMethodConfirmation(makeVaultedPaymentMethod(id: "vault_123"))
        let state2 = CheckoutNavigationState.deleteVaultedPaymentMethodConfirmation(makeVaultedPaymentMethod(id: "vault_456"))
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Cross-Type Inequality

    func test_differentSimpleTypes_areNotEqual() {
        let states: [CheckoutNavigationState] = [
            .loading, .paymentMethodSelection, .vaultedPaymentMethods, .processing, .dismissed
        ]

        for lhsIndex in 0..<states.count {
            for rhsIndex in (lhsIndex + 1)..<states.count {
                XCTAssertNotEqual(states[lhsIndex], states[rhsIndex])
            }
        }
    }

    func test_paymentMethod_notEqual_toOtherTypes() {
        XCTAssertNotEqual(CheckoutNavigationState.paymentMethod("PAYMENT_CARD"), .loading)
    }

    func test_success_notEqual_toOtherTypes() {
        XCTAssertNotEqual(
            CheckoutNavigationState.success(makePaymentResult(paymentId: "pay_123")),
            .processing
        )
    }

    func test_failure_notEqual_toOtherTypes() {
        XCTAssertNotEqual(
            CheckoutNavigationState.failure(makeError(message: "Error")),
            .loading
        )
    }
}
