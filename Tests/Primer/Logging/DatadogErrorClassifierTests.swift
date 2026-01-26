//
//  DatadogErrorClassifierTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class DatadogErrorClassifierTests: XCTestCase {

    // MARK: - Reportable PrimerError Tests

    func test_shouldReportToDatadog_returnsTrueForNolError() {
        let error = PrimerError.nolError(code: "123", message: "Nol SDK error")

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsTrueForNolSdkInitError() {
        let error = PrimerError.nolSdkInitError()

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsTrueForKlarnaError() {
        let error = PrimerError.klarnaError(message: "Klarna SDK error")

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsTrueForStripeError() {
        let error = PrimerError.stripeError(key: "stripe-sdk-error", message: "Stripe error")

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsTrueForFailedToCreateSession() {
        let error = PrimerError.failedToCreateSession(error: NSError(domain: "test", code: 1))

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsTrueForApplePayConfigurationError() {
        let error = PrimerError.applePayConfigurationError(merchantIdentifier: "test")

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsTrueForApplePayPresentationFailed() {
        let error = PrimerError.applePayPresentationFailed(reason: "PassKit error")

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsTrueForFailedToCreatePayment() {
        let error = PrimerError.failedToCreatePayment(
            paymentMethodType: "CARD",
            description: "API error"
        )

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsTrueForFailedToResumePayment() {
        let error = PrimerError.failedToResumePayment(
            paymentMethodType: "CARD",
            description: "API error"
        )

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsTrueForUnknownError() {
        let error = PrimerError.unknown(message: "Something went wrong")

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    // MARK: - Non-Reportable PrimerError Tests

    func test_shouldReportToDatadog_returnsFalseForCancelled() {
        let error = PrimerError.cancelled(paymentMethodType: "CARD")

        XCTAssertFalse(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsFalseForPaymentFailed() {
        let error = PrimerError.paymentFailed(
            paymentMethodType: "CARD",
            paymentId: "pay_123",
            orderId: "order_123",
            status: "DECLINED"
        )

        XCTAssertFalse(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsFalseForKlarnaUserNotApproved() {
        let error = PrimerError.klarnaUserNotApproved()

        XCTAssertFalse(error.shouldReportToDatadog)
    }

    // MARK: - Validation/Configuration Errors (Not Reported)

    func test_shouldReportToDatadog_returnsFalseForInvalidClientToken() {
        let error = PrimerError.invalidClientToken(reason: "Expired")

        XCTAssertFalse(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsFalseForMissingConfiguration() {
        let error = PrimerError.missingPrimerConfiguration()

        XCTAssertFalse(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsFalseForUnsupportedPaymentMethod() {
        let error = PrimerError.unsupportedPaymentMethod(paymentMethodType: "UNKNOWN")

        XCTAssertFalse(error.shouldReportToDatadog)
    }

    // MARK: - InternalError Tests

    func test_shouldReportToDatadog_returnsTrueForServerError() {
        let error = InternalError.serverError(status: 500)

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsTrueFor3DSFailure() {
        let underlyingError = NSError(domain: "com.primer.3ds", code: 1)
        let error = InternalError.failedToPerform3dsAndShouldBreak(error: underlyingError)

        XCTAssertTrue(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsFalseForFailedToDecode() {
        let error = InternalError.failedToDecode(message: "Invalid JSON")

        XCTAssertFalse(error.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_returnsFalseForNoData() {
        let error = InternalError.noData()

        XCTAssertFalse(error.shouldReportToDatadog)
    }

    // MARK: - Unknown Error Types

    func test_shouldReportToDatadog_returnsTrueForUnknownErrorType() {
        let error = NSError(domain: "com.test", code: 42)

        // Unknown error types should be reported for visibility
        XCTAssertTrue(error.shouldReportToDatadog)
    }

    // MARK: - 3DS Error Tests

    func test_shouldReportToDatadog_returnsTrueFor3DSErrorContainer() {
        // All 3DS errors should be reported (isReportable = true)
        let missingDependency = Primer3DSErrorContainer.missingSdkDependency()
        XCTAssertTrue(missingDependency.shouldReportToDatadog)

        let invalidVersion = Primer3DSErrorContainer.invalid3DSSdkVersion(
            invalidVersion: "1.0.0",
            validVersion: "2.0.0"
        )
        XCTAssertTrue(invalidVersion.shouldReportToDatadog)

        let missingConfig = Primer3DSErrorContainer.missing3DSConfiguration(missingKey: "directoryServerId")
        XCTAssertTrue(missingConfig.shouldReportToDatadog)

        let underlyingError = Primer3DSErrorContainer.underlyingError(
            error: NSError(domain: "com.netcetera", code: 1)
        )
        XCTAssertTrue(underlyingError.shouldReportToDatadog)
    }
}
