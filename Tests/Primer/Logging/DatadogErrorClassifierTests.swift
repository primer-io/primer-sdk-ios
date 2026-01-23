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

    func test_shouldReport_returnsTrueForNolError() {
        let error = PrimerError.nolError(code: "123", message: "Nol SDK error")

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsTrueForNolSdkInitError() {
        let error = PrimerError.nolSdkInitError()

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsTrueForKlarnaError() {
        let error = PrimerError.klarnaError(message: "Klarna SDK error")

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsTrueForStripeError() {
        let error = PrimerError.stripeError(key: "stripe-sdk-error", message: "Stripe error")

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsTrueForFailedToCreateSession() {
        let error = PrimerError.failedToCreateSession(error: NSError(domain: "test", code: 1))

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsTrueForApplePayConfigurationError() {
        let error = PrimerError.applePayConfigurationError(merchantIdentifier: "test")

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsTrueForApplePayPresentationFailed() {
        let error = PrimerError.applePayPresentationFailed(reason: "PassKit error")

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsTrueForFailedToCreatePayment() {
        let error = PrimerError.failedToCreatePayment(
            paymentMethodType: "CARD",
            description: "API error"
        )

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsTrueForFailedToResumePayment() {
        let error = PrimerError.failedToResumePayment(
            paymentMethodType: "CARD",
            description: "API error"
        )

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsTrueForUnknownError() {
        let error = PrimerError.unknown(message: "Something went wrong")

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    // MARK: - Non-Reportable PrimerError Tests

    func test_shouldReport_returnsFalseForCancelled() {
        let error = PrimerError.cancelled(paymentMethodType: "CARD")

        XCTAssertFalse(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsFalseForPaymentFailed() {
        let error = PrimerError.paymentFailed(
            paymentMethodType: "CARD",
            paymentId: "pay_123",
            orderId: "order_123",
            status: "DECLINED"
        )

        XCTAssertFalse(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsFalseForKlarnaUserNotApproved() {
        let error = PrimerError.klarnaUserNotApproved()

        XCTAssertFalse(DatadogErrorClassifier.shouldReport(error))
    }

    // MARK: - Validation/Configuration Errors (Not Reported)

    func test_shouldReport_returnsFalseForInvalidClientToken() {
        let error = PrimerError.invalidClientToken(reason: "Expired")

        XCTAssertFalse(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsFalseForMissingConfiguration() {
        let error = PrimerError.missingPrimerConfiguration()

        XCTAssertFalse(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsFalseForUnsupportedPaymentMethod() {
        let error = PrimerError.unsupportedPaymentMethod(paymentMethodType: "UNKNOWN")

        XCTAssertFalse(DatadogErrorClassifier.shouldReport(error))
    }

    // MARK: - InternalError Tests

    func test_shouldReport_returnsTrueForServerError() {
        let error = InternalError.serverError(status: 500)

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsTrueFor3DSFailure() {
        let underlyingError = NSError(domain: "com.primer.3ds", code: 1)
        let error = InternalError.failedToPerform3dsAndShouldBreak(error: underlyingError)

        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsFalseForFailedToDecode() {
        let error = InternalError.failedToDecode(message: "Invalid JSON")

        XCTAssertFalse(DatadogErrorClassifier.shouldReport(error))
    }

    func test_shouldReport_returnsFalseForNoData() {
        let error = InternalError.noData()

        XCTAssertFalse(DatadogErrorClassifier.shouldReport(error))
    }

    // MARK: - Unknown Error Types

    func test_shouldReport_returnsTrueForUnknownErrorType() {
        let error = NSError(domain: "com.test", code: 42)

        // Unknown error types should be reported for visibility
        XCTAssertTrue(DatadogErrorClassifier.shouldReport(error))
    }

    // MARK: - Error Extension Tests

    func test_shouldReportToDatadog_extensionWorksPrimerError() {
        let reportable = PrimerError.unknown()
        let nonReportable = PrimerError.cancelled(paymentMethodType: "CARD")

        XCTAssertTrue(reportable.shouldReportToDatadog)
        XCTAssertFalse(nonReportable.shouldReportToDatadog)
    }

    func test_shouldReportToDatadog_extensionWorksForInternalError() {
        let reportable = InternalError.serverError(status: 500)
        let nonReportable = InternalError.noData()

        XCTAssertTrue(reportable.shouldReportToDatadog)
        XCTAssertFalse(nonReportable.shouldReportToDatadog)
    }
}
