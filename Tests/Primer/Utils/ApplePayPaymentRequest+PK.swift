//
//  ApplePayPaymentRequest+PK.swift
//
//
//  Created by Semir on 04/04/2025.
//

import XCTest
import PassKit
@testable import PrimerSDK

class ApplePayPaymentRequest: XCTestCase {

    let currency = Currency(code: "USD", decimalDigits: 2)

    func testToPKRecurringPaymentSummaryItem_validInput() throws {
        guard #available(iOS 15.0, *) else {
            throw XCTSkip("Test requires iOS 15.0 or later")
        }

        let billing = ApplePayRegularBillingOption(
            label: "Test Subscription",
            amount: 5000,
            recurringStartDate: Date(),
            recurringEndDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            recurringIntervalUnit: .month,
            recurringIntervalCount: 1
        )

        let summaryItem = billing.toPKRecurringPaymentSummaryItem(totalAmount: 5000, currency: currency)

        XCTAssertEqual(summaryItem.label, billing.label)
        XCTAssertEqual(summaryItem.amount, NSDecimalNumber(decimal: 5000.formattedCurrencyAmount(currency: Currency(code: "USD", decimalDigits: 2))))
        XCTAssertEqual(summaryItem.intervalCount, billing.recurringIntervalCount)
        XCTAssertEqual(summaryItem.intervalUnit, NSCalendar.Unit.month)
    }

    func testToPKRecurringPaymentRequest_missingAmount_throwsError() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Test requires iOS 16.0 or later")
        }

        let request = ApplePayRecurringPaymentRequest(
            paymentDescription: "Test Recurring Payment",
            billingAgreement: "Agreement123",
            managementUrl: "https://example.com",
            regularBilling: ApplePayRegularBillingOption(
                label: "Test Billing",
                amount: nil,
                recurringStartDate: Date(),
                recurringEndDate: nil,
                recurringIntervalUnit: nil,
                recurringIntervalCount: nil
            ),
            trialBilling: nil,
            tokenManagementUrl: nil
        )

        let expectedError = getInvalidValueError(key: "regularBilling.amount or amount")

        XCTAssertThrowsError(try request.toPKRecurringPaymentRequest(orderAmount: nil, currency: currency, descriptor: nil)) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Invalid value 'nil' for key 'regularBilling.amount or amount'")
            }
        }
    }

    func testToPKRecurringPaymentRequest_missingDescriptor_throwsError() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Test requires iOS 16.0 or later")
        }

        let request = ApplePayRecurringPaymentRequest(
            paymentDescription: nil,
            billingAgreement: "Agreement123",
            managementUrl: "https://example.com",
            regularBilling: ApplePayRegularBillingOption(
                label: "Test Billing",
                amount: 123,
                recurringStartDate: Date(),
                recurringEndDate: nil,
                recurringIntervalUnit: nil,
                recurringIntervalCount: nil
            ),
            trialBilling: nil,
            tokenManagementUrl: nil
        )

        let expectedError = getInvalidValueError(key: "recurringPaymentRequest.paymentDescription or paymentMethod.descriptor")

        XCTAssertThrowsError(try request.toPKRecurringPaymentRequest(orderAmount: nil, currency: currency, descriptor: nil)) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Invalid value 'nil' for key 'recurringPaymentRequest.paymentDescription or paymentMethod.descriptor'")
            }
        }
    }

    func testToPKDeferredPaymentRequest_validInput() throws {
        guard #available(iOS 16.4, *) else {
            throw XCTSkip("Test requires iOS 16.4 or later")
        }

        let request = ApplePayDeferredPaymentRequest(
            paymentDescription: "Deferred Payment",
            billingAgreement: nil,
            managementUrl: "https://example.com",
            deferredBilling: ApplePayDeferredBillingOption(
                label: "Deferred Item",
                amount: 3000,
                deferredPaymentDate: Date()
            ),
            freeCancellationDate: nil,
            freeCancellationTimeZone: nil,
            tokenManagementUrl: nil
        )

        XCTAssertNoThrow(try request.toPKDeferredPaymentRequest(orderAmount: 3000, currency: currency, descriptor: nil))
    }

    func testToPKDeferredPaymentRequest_missingAmount_throwsError() throws {
        guard #available(iOS 16.4, *) else {
            throw XCTSkip("Test requires iOS 16.4 or later")
        }

        let request = ApplePayDeferredPaymentRequest(
            paymentDescription: "Deferred Payment",
            billingAgreement: nil,
            managementUrl: "https://example.com",
            deferredBilling: ApplePayDeferredBillingOption(
                label: "Deferred Item",
                amount: nil,
                deferredPaymentDate: Date()
            ),
            freeCancellationDate: nil,
            freeCancellationTimeZone: nil,
            tokenManagementUrl: nil
        )

        let expectedError = getInvalidValueError(key: "deferredBilling.amount or amount")

        XCTAssertThrowsError(try request.toPKDeferredPaymentRequest(orderAmount: nil, currency: currency, descriptor: nil)) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Invalid value 'nil' for key 'deferredBilling.amount or amount'")
            }
        }
    }

    func testToPKDeferredPaymentRequest() throws {
        guard #available(iOS 16.4, *) else {
            throw XCTSkip("Test requires iOS 16.4 or later")
        }

        let request = ApplePayDeferredPaymentRequest(
            paymentDescription: nil,
            billingAgreement: nil,
            managementUrl: "https://example.com",
            deferredBilling: ApplePayDeferredBillingOption(
                label: "Deferred Item",
                amount: 123,
                deferredPaymentDate: Date()
            ),
            freeCancellationDate: nil,
            freeCancellationTimeZone: nil,
            tokenManagementUrl: nil
        )

        let expectedError = getInvalidValueError(key: "deferredPaymentRequest.paymentDescription or paymentMethod.descriptor")

        XCTAssertThrowsError(try request.toPKDeferredPaymentRequest(orderAmount: nil, currency: currency, descriptor: nil)) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Invalid value 'nil' for key 'deferredPaymentRequest.paymentDescription or paymentMethod.descriptor'")
            }
        }
    }

    func testtoPKAutomaticReloadPaymentRequest_validInput() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Test requires iOS 16.0 or later")
        }

        let request = ApplePayAutomaticReloadRequest(
            paymentDescription: "Deferred Payment",
            billingAgreement: nil,
            managementUrl: "https://example.com",
            automaticReloadBilling: ApplePayAutomaticReloadBillingOption(
                label: "Deferred Item",
                amount: 3000,
                automaticReloadThresholdAmount: 200
            ),
            tokenManagementUrl: nil
        )

        XCTAssertNoThrow(try request.toPKAutomaticReloadPaymentRequest(orderAmount: 3000, currency: currency, descriptor: nil))
    }

    func testToPKAutomaticReloadPaymentRequest_missingAmount_throwsError() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Test requires iOS 16.0 or later")
        }
        let request = ApplePayAutomaticReloadRequest(
            paymentDescription: "Reload Payment",
            billingAgreement: nil,
            managementUrl: "https://example.com",
            automaticReloadBilling: ApplePayAutomaticReloadBillingOption(
                label: "Reload Item",
                amount: nil,
                automaticReloadThresholdAmount: 0
            ),
            tokenManagementUrl: nil
        )

        let expectedError = getInvalidValueError(key: "automaticReloadBilling.amount or amount")

        XCTAssertThrowsError(try request.toPKAutomaticReloadPaymentRequest(orderAmount: nil, currency: currency, descriptor: nil)) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Invalid value 'nil' for key 'automaticReloadBilling.amount or amount'")
            }
        }
    }

    func testToPKAutomaticReloadPaymentRequest_missingDescription_throwsError() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Test requires iOS 16.0 or later")
        }
        let request = ApplePayAutomaticReloadRequest(
            paymentDescription: nil,
            billingAgreement: nil,
            managementUrl: "https://example.com",
            automaticReloadBilling: ApplePayAutomaticReloadBillingOption(
                label: "Reload Item",
                amount: 123,
                automaticReloadThresholdAmount: 0
            ),
            tokenManagementUrl: nil
        )

        let expectedError = getInvalidValueError(key: "automaticReloadRequest.paymentDescription or paymentMethod.descriptor")

        XCTAssertThrowsError(try request.toPKAutomaticReloadPaymentRequest(orderAmount: nil, currency: currency, descriptor: nil)) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Invalid value 'nil' for key 'automaticReloadRequest.paymentDescription or paymentMethod.descriptor'")
            }
        }
    }

    func testToPKAutomaticReloadPaymentRequest_invalidManagmentUrl_throwsError() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Test requires iOS 16.0 or later")
        }
        let request = ApplePayAutomaticReloadRequest(
            paymentDescription: "test",
            billingAgreement: nil,
            managementUrl: "",
            automaticReloadBilling: ApplePayAutomaticReloadBillingOption(
                label: "Reload Item",
                amount: 123,
                automaticReloadThresholdAmount: 0
            ),
            tokenManagementUrl: nil
        )

        let expectedError = getInvalidValueError(key: "automaticReloadRequest.managementUrl")

        XCTAssertThrowsError(try request.toPKAutomaticReloadPaymentRequest(orderAmount: nil, currency: currency, descriptor: nil)) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Invalid value 'nil' for key 'automaticReloadRequest.managementUrl'")
            }
        }
    }

    func testTrialBillingWithZeroAmount() throws {
        guard #available(iOS 15.0, *) else {
            throw XCTSkip("Test requires iOS 15.0 or later")
        }

        let billing = ApplePayTrialBillingOption(
            label: "Trial Plan",
            amount: 0,
            recurringStartDate: Date(),
            recurringEndDate: Date(),
            recurringIntervalUnit: .month,
            recurringIntervalCount: 1
        )

        XCTAssertNoThrow(billing.toPKRecurringPaymentSummaryItem(totalAmount: 0, currency: currency))
    }

    func testTokenManagementUrlEdgeCases() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Test requires iOS 16.0 or later")
        }

        let validRequest = ApplePayRecurringPaymentRequest(
            paymentDescription: "Valid Token Management",
            billingAgreement: "Agreement123",
            managementUrl: "https://example.com",
            regularBilling: ApplePayRegularBillingOption(
                label: "Test Billing",
                amount: 5000,
                recurringStartDate: Date(),
                recurringEndDate: nil,
                recurringIntervalUnit: .month,
                recurringIntervalCount: 1
            ),
            trialBilling: nil,
            tokenManagementUrl: "https://example.com/token"
        )

        XCTAssertNoThrow(try validRequest.toPKRecurringPaymentRequest(orderAmount: 5000, currency: currency, descriptor: nil))

        let invalidRequest = ApplePayRecurringPaymentRequest(
            paymentDescription: "Invalid Token Management",
            billingAgreement: "Agreement123",
            managementUrl: "",
            regularBilling: ApplePayRegularBillingOption(
                label: "Test Billing",
                amount: nil,
                recurringStartDate: Date(),
                recurringEndDate: nil,
                recurringIntervalUnit: .month,
                recurringIntervalCount: 1
            ),
            trialBilling: nil,
            tokenManagementUrl: "https://example.com/token"
        )

        XCTAssertThrowsError(try invalidRequest.toPKRecurringPaymentRequest(orderAmount: 5000, currency: currency, descriptor: nil))
    }

    func getInvalidValueError(
        key: String,
        value: Any? = nil
    ) -> PrimerError {
        let error = PrimerError.invalidValue(
            key: key,
            value: value,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
}
