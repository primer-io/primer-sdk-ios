//
//  ACHHelpersTests.swift
//  
//
//  Created by Stefan Vrancianu on 28.05.2024.
//

import Foundation
import XCTest
@testable import PrimerSDK

final class ACHHelpersTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func test_construct_localeData() {
        let sessionData = ACHHelpers.constructLocaleData()
        XCTAssertEqual(sessionData.locale, PrimerSettings.current.localeData.localeCode)
        XCTAssertEqual(sessionData.platform, "IOS")
    }

    func test_get_ACHPaymentInstrument_with_valid_paymentMethod() {
        let paymentInstrument = ACHHelpers.getACHPaymentInstrument(paymentMethod: ACHMocks.stripeACHPaymentMethod)
        
        XCTAssertNotNil(paymentInstrument)
        XCTAssertEqual(paymentInstrument?.paymentMethodConfigId, ACHMocks.stripeACHPaymentMethodId)
        XCTAssertEqual(paymentInstrument?.paymentMethodType, PrimerPaymentMethodType.stripeAch.rawValue)
        XCTAssertEqual(paymentInstrument?.authenticationProvider, PrimerPaymentMethodType.stripeAch.provider)
        XCTAssertEqual(paymentInstrument?.type, PaymentInstrumentType.stripeAch.rawValue)
    }

    func test_get_ACHPaymentInstrument_with_invalid_paymentMethod() {
        let paymentInstrument = ACHHelpers.getACHPaymentInstrument(paymentMethod: ACHMocks.getInvalidPaymentMethod())
        XCTAssertNil(paymentInstrument)
    }

    func test_get_invalid_token_error() {
        let error = ACHHelpers.getInvalidTokenError()
        let expectedErrorId = "invalid-client-token"
        XCTAssertEqual(error.errorId, expectedErrorId)
    }

    func test_get_invalid_setting_error() {
        let expectedName = "test-setting"
        let expectedRecoverySuggestion = "Check if value nil is valid for key \(expectedName)"
        let error = ACHHelpers.getInvalidSettingError(name: expectedName)
        
        XCTAssertEqual(error.errorId, "invalid-value")
        XCTAssertEqual(error.recoverySuggestion, expectedRecoverySuggestion)
    }

    func test_get_invalid_value_error() {
        let expectedKey = "test-key"
        let expectedValue = "test-value"
        let error = ACHHelpers.getInvalidValueError(key: expectedKey, value: expectedValue)
        
        XCTAssertEqual(error.errorId, "invalid-value")
        XCTAssertEqual(error.plainDescription, "Invalid value '\(expectedValue)' for key '\(expectedKey)'")
    }

    func test_get_cancelled_error() {
        let expectedPaymentMethodType = "STRIPE_ACH"
        let error = ACHHelpers.getCancelledError(paymentMethodType: expectedPaymentMethodType)
        XCTAssertEqual(error.errorId, "payment-cancelled")
        XCTAssertEqual(error.plainDescription, "Payment method \(expectedPaymentMethodType) cancelled")
    }

    func test_get_payment_failed_error() {
        let expectedPaymentMethodType = "STRIPE_ACH"
        let error = ACHHelpers.getPaymentFailedError(paymentMethodType: expectedPaymentMethodType)
        
        XCTAssertEqual(error.errorId, PrimerPaymentErrorCode.failed.rawValue)
        XCTAssertEqual(error.plainDescription, "Failed to create payment")
    }

    func test_get_failed_to_process_payment_error() {
        let expectedId = "test-failed-id"
        let expectedStatus: Response.Body.Payment.Status = .failed
        let paymentResponse = ACHMocks.getPayment(id: expectedId, status: expectedStatus)
        let error = ACHHelpers.getFailedToProcessPaymentError(paymentMethodType: ACHMocks.stripeACHPaymentMethodType,
                                                              paymentResponse: paymentResponse)
        
        XCTAssertEqual(error.errorId, "failed-to-process-payment")
        XCTAssertEqual(error.plainDescription, "The payment with id \(expectedId) was created but ended up in a \(expectedStatus.rawValue) status.")
    }

    func test_get_missing_SDK_error() {
        let expectedSDKName = "test-sdk"
        let expectedPaymentMethodType = ACHMocks.stripeACHPaymentMethodType
        let error = ACHHelpers.getMissingSDKError(sdk: expectedSDKName)
        
        XCTAssertEqual(error.errorId, "missing-sdk-dependency")
        XCTAssertEqual(error.plainDescription, "\(expectedPaymentMethodType) configuration has been found, but dependency \(expectedSDKName) is missing")
    }
}
