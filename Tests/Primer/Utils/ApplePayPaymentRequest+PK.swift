//
//  ApplePayPaymentRequest+PK.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 16.4, *)
final class ApplePayPaymentRequest: XCTestCase {
    
    func testToPKRecurringPaymentSummaryItem_validInput() throws {
        let billing = ApplePayRegularBillingOption(label: "Test Subscription", amount: nil)
        let summaryItem = billing.toPKRecurringPaymentSummaryItem(totalAmount: 123, currency: Currency(code: "USD", decimalDigits: 2))
        XCTAssertEqual(summaryItem.label, billing.label)
        XCTAssertEqual(summaryItem.amount, NSDecimalNumber(decimal: 123.formattedCurrencyAmount(currency: Currency(code: "USD", decimalDigits: 2))))
        XCTAssertEqual(summaryItem.intervalCount, billing.recurringIntervalCount)
        XCTAssertEqual(summaryItem.intervalUnit, NSCalendar.Unit.month)
    }
    
    func testToPKRecurringPaymentRequest_missingAmount_throwsError() throws {
        let request = ApplePayRecurringPaymentRequest(description: "Test recurring payment", amount: nil)
        assert(.regularBillingAmount, against: request.toPK)
    }
    
    func testToPKRecurringPaymentRequest_missingDescriptor_throwsError() throws {
        let request = ApplePayRecurringPaymentRequest(description: nil, amount: 123)
        assert(.recurringPaymentMissingDescription, against: request.toPK)
    }
    
    func testToPKDeferredPaymentRequest_validInput() throws {
        let request = ApplePayDeferredPaymentRequest(description: "Request", amount: 123)
        XCTAssertNoThrow(request.toPK)
    }
    
    func testToPKDeferredPaymentRequest_missingAmount_throwsError() throws {
        let request = ApplePayDeferredPaymentRequest(description: nil, amount: nil)
        assert(.deferredBillingAmount, against: request.toPK)
    }
    
    func testToPKDeferredPaymentRequest() throws {
        let request = ApplePayDeferredPaymentRequest(description: nil, amount: 123)
        assert(.deferredPaymentMissingDescription, against: request.toPK)
    }
    
    func testToPKAutomaticReloadPaymentRequest_validInput() throws {
        let request = ApplePayAutomaticReloadRequest(description: "Deferred payment", amount: 123)
        XCTAssertNoThrow(request.toPK)
    }
    
    func testToPKAutomaticReloadPaymentRequest_missingAmount_throwsError() throws {
        let request = ApplePayAutomaticReloadRequest(description: "Reload Payment", amount: nil)
        assert(.automaticReloadBillingAmount, against: request.toPK)
    }
    
    func testToPKAutomaticReloadPaymentRequest_missingDescription_throwsError() throws {
        let request = ApplePayAutomaticReloadRequest(description: nil, amount: 123)
        assert(.automaticReloadMissingDescription, against: request.toPK)
    }
    
    func testToPKAutomaticReloadPaymentRequest_invalidManagmentUrl_throwsError() throws {
        let request = ApplePayAutomaticReloadRequest(description: "test", amount: 123, managementUrl: "")
        assert(.automaticReloadInvalidManagementUrl, against: request.toPK)
    }
    
    func testTrialBillingWithZeroAmount() throws {
        XCTAssertNoThrow(ApplePayTrialBillingOption().toPK)
    }
    
    func testTokenManagementUrlEdgeCases() throws {
        let validRequest = ApplePayRecurringPaymentRequest(description: "Valid Token Management", amount: 5000)
        XCTAssertNoThrow(try validRequest.toPK())

        let invalidRequest = ApplePayRecurringPaymentRequest(description: "Valid Token Management", amount: 5000, managementUrl: "")
        XCTAssertThrowsError(try invalidRequest.toPK())
    }
    
    private func assert<T>(_ expectedErrorKey: String, against method: @escaping () throws -> T) {
        let expectedError = getInvalidValueError(key: expectedErrorKey)
        let failureMessage = "Invalid value 'nil' for key '\(expectedErrorKey)'"
        XCTAssertThrowsError(try method()) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, failureMessage)
            }
        }
    }
    
    private func getInvalidValueError(
        key: String,
        value: Any? = nil
    ) -> PrimerError {
        PrimerError.invalidValue(
            key: key,
            value: value,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString
        )
    }
}

private extension String {
    static let regularBillingAmount = "regularBilling.amount or amount"
    static let recurringPaymentMissingDescription = "recurringPaymentRequest.paymentDescription or paymentMethod.descriptor"
    static let deferredBillingAmount = "deferredBilling.amount or amount"
    static let deferredPaymentMissingDescription = "deferredPaymentRequest.paymentDescription or paymentMethod.descriptor"
    static let automaticReloadBillingAmount = "automaticReloadBilling.amount or amount"
    static let automaticReloadMissingDescription = "automaticReloadRequest.paymentDescription or paymentMethod.descriptor"
    static let automaticReloadInvalidManagementUrl = "automaticReloadRequest.managementUrl"
}
