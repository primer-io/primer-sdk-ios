//
//  ComponentsApplePayBridgeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@_spi(PrimerInternal) @testable import PrimerSDK

@available(iOS 15.0, *)
final class ComponentsApplePayBridgeTests: XCTestCase {

    // MARK: - stableCode(for:)

    func test_stableCode_osVersionMessage_returnsOSVersionTooLow() {
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: "OS version too low"), "OS_VERSION_TOO_LOW")
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: "iOS 15 or later is required"), "OS_VERSION_TOO_LOW")
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: "Unsupported OS"), "OS_VERSION_TOO_LOW")
    }

    func test_stableCode_walletMessage_returnsNoWalletCard() {
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: "No cards in wallet"), "NO_WALLET_CARD")
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: "No eligible card for Apple Pay"), "NO_WALLET_CARD")
    }

    func test_stableCode_merchantIdentifierMessage_returnsMerchantIdMissing() {
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: "Merchant identifier is missing"), "MERCHANT_IDENTIFIER_MISSING")
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: "merchantIdentifier not set"), "MERCHANT_IDENTIFIER_MISSING")
    }

    func test_stableCode_clientSessionMessage_returnsCheckoutSessionInvalid() {
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: "Client session is invalid"), "CHECKOUT_SESSION_INVALID")
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: "clientSession missing payment options"), "CHECKOUT_SESSION_INVALID")
    }

    func test_stableCode_unrelatedMessage_returnsUnknown() {
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: "Something else went wrong"), "UNKNOWN")
        XCTAssertEqual(ComponentsApplePayState.stableCode(for: ""), "UNKNOWN")
    }

    // MARK: - ComponentsApplePayState.init(from:)

    func test_componentsApplePayState_fromAvailableState_mapsAvailableNoError() {
        // Given
        let upstream = PrimerApplePayState.available()

        // When
        let sut = ComponentsApplePayState(from: upstream)

        // Then
        XCTAssertTrue(sut.isAvailable)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.availabilityError)
    }

    func test_componentsApplePayState_fromUnavailableWithMessage_includesTypedCode() {
        // Given
        let upstream = PrimerApplePayState.unavailable(error: "No cards in wallet")

        // When
        let sut = ComponentsApplePayState(from: upstream)

        // Then
        XCTAssertFalse(sut.isAvailable)
        XCTAssertEqual(sut.availabilityError?.code, "NO_WALLET_CARD")
        XCTAssertEqual(sut.availabilityError?.message, "No cards in wallet")
    }

    func test_componentsApplePayState_fromLoadingState_setsIsLoading() {
        // Given
        let upstream = PrimerApplePayState.loading

        // When
        let sut = ComponentsApplePayState(from: upstream)

        // Then
        XCTAssertTrue(sut.isLoading)
        XCTAssertTrue(sut.isAvailable)
        XCTAssertNil(sut.availabilityError)
    }

    // MARK: - ComponentsApplePayOutcome.init(from:)

    func test_componentsApplePayOutcome_fromPaymentResult_mapsToSuccess() {
        // Given
        let result = PaymentResult(
            paymentId: "pay-123",
            status: .success,
            amount: 1500,
            currencyCode: "GBP",
            paymentMethodType: "APPLE_PAY"
        )

        // When
        let sut = ComponentsApplePayOutcome(from: result)

        // Then
        guard case let .success(paymentId, status, amount, currencyCode, paymentMethodType) = sut else {
            return XCTFail("expected .success, got \(sut)")
        }
        XCTAssertEqual(paymentId, "pay-123")
        XCTAssertEqual(status, "success")
        XCTAssertEqual(amount, 1500)
        XCTAssertEqual(currencyCode, "GBP")
        XCTAssertEqual(paymentMethodType, "APPLE_PAY")
    }

    func test_componentsApplePayOutcome_fromPaymentResultMissingMethodType_defaultsToApplePay() {
        // Given — `paymentMethodType` is optional on `PaymentResult`; native sometimes omits it.
        let result = PaymentResult(paymentId: "pay-456", status: .success, paymentMethodType: nil)

        // When
        let sut = ComponentsApplePayOutcome(from: result)

        // Then
        guard case let .success(_, _, _, _, paymentMethodType) = sut else {
            return XCTFail("expected .success, got \(sut)")
        }
        XCTAssertEqual(paymentMethodType, "APPLE_PAY")
    }

    func test_componentsApplePayOutcome_fromPrimerError_mapsToFailureWithErrorId() {
        // Given
        let error = PrimerError.invalidValue(key: "applePayConfig.id")

        // When
        let sut = ComponentsApplePayOutcome(from: error)

        // Then
        guard case let .failure(errorCode, errorMessage, diagnosticsId) = sut else {
            return XCTFail("expected .failure, got \(sut)")
        }
        XCTAssertEqual(errorCode, error.errorId)
        XCTAssertFalse(errorMessage.isEmpty)
        XCTAssertEqual(diagnosticsId, error.diagnosticsId)
    }
}
