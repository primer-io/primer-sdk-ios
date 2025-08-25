//
//  PrimerErrorTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PrimerErrorTests: XCTestCase {
    
    // MARK: - Apple Pay Error Tests
    
    func testApplePayNoCardsInWallet() {
        let diagnosticsId = "test-id-456"
        let error = PrimerError.applePayNoCardsInWallet(diagnosticsId: diagnosticsId)
        
        XCTAssertEqual(error.errorId, "apple-pay-no-cards-in-wallet")
        XCTAssertEqual(error.diagnosticsId, diagnosticsId)
        XCTAssertEqual(error.plainDescription, "Apple Pay has no cards in wallet")
        XCTAssertEqual(error.recoverySuggestion, "The user needs to add cards to their Apple Wallet to use Apple Pay.")
        
        // Test analytics context
        let context = error.analyticsContext
        XCTAssertEqual(context[AnalyticsContextKeys.paymentMethodType] as? String, PrimerPaymentMethodType.applePay.rawValue)
        XCTAssertEqual(context[AnalyticsContextKeys.errorId] as? String, "apple-pay-no-cards-in-wallet")
        
        // Test error description
        XCTAssertTrue(error.errorDescription?.contains("[apple-pay-no-cards-in-wallet]") ?? false)
        XCTAssertTrue(error.errorDescription?.contains(diagnosticsId) ?? false)
    }
    
    func testApplePayDeviceNotSupported() {
        let diagnosticsId = "test-id-789"
        let error = PrimerError.applePayDeviceNotSupported(diagnosticsId: diagnosticsId)
        
        XCTAssertEqual(error.errorId, "apple-pay-device-not-supported")
        XCTAssertEqual(error.diagnosticsId, diagnosticsId)
        XCTAssertEqual(error.plainDescription, "Device does not support Apple Pay")
        XCTAssertEqual(error.recoverySuggestion, "This device does not support Apple Pay. Apple Pay requires compatible hardware and iOS version.")
        
        // Test analytics context
        let context = error.analyticsContext
        XCTAssertEqual(context[AnalyticsContextKeys.paymentMethodType] as? String, PrimerPaymentMethodType.applePay.rawValue)
        XCTAssertEqual(context[AnalyticsContextKeys.errorId] as? String, "apple-pay-device-not-supported")
    }
    
    func testApplePayConfigurationError() {
        let merchantIdentifier = "invalid.merchant.id"
        let diagnosticsId = "test-id-abc"
        let error = PrimerError.applePayConfigurationError(
            merchantIdentifier: merchantIdentifier,
            diagnosticsId: diagnosticsId
        )
        
        XCTAssertEqual(error.errorId, "apple-pay-configuration-error")
        XCTAssertEqual(error.diagnosticsId, diagnosticsId)
        XCTAssertEqual(error.plainDescription, "Apple Pay configuration error: merchant identifier 'invalid.merchant.id' may be invalid")
        XCTAssertEqual(error.recoverySuggestion, "Check that the merchant identifier matches your Apple Developer configuration and is valid for the current environment (sandbox/production).")
        
        // Test with nil merchant identifier
        let errorWithNilMerchant = PrimerError.applePayConfigurationError(
            merchantIdentifier: nil,
            diagnosticsId: "test-id-def"
        )
        XCTAssertEqual(errorWithNilMerchant.plainDescription, "Apple Pay configuration error: merchant identifier 'nil' may be invalid")
        
        // Test analytics context
        let context = error.analyticsContext
        XCTAssertEqual(context[AnalyticsContextKeys.paymentMethodType] as? String, PrimerPaymentMethodType.applePay.rawValue)
    }
    
    func testApplePayPresentationFailed() {
        let reason = "User cancelled the payment"
        let diagnosticsId = "test-id-xyz"
        let error = PrimerError.applePayPresentationFailed(
            reason: reason,
            diagnosticsId: diagnosticsId
        )
        
        XCTAssertEqual(error.errorId, "apple-pay-presentation-failed")
        XCTAssertEqual(error.diagnosticsId, diagnosticsId)
        XCTAssertEqual(error.plainDescription, "Apple Pay presentation failed: User cancelled the payment")
        XCTAssertEqual(error.recoverySuggestion, "Unable to display Apple Pay sheet. This may be due to system restrictions or temporary issues. Try again later.")
        
        // Test with nil reason
        let errorWithNilReason = PrimerError.applePayPresentationFailed(
            reason: nil,
            diagnosticsId: "test-id-123"
        )
        XCTAssertEqual(errorWithNilReason.plainDescription, "Apple Pay presentation failed: unknown reason")
        
        // Test analytics context
        let context = error.analyticsContext
        XCTAssertEqual(context[AnalyticsContextKeys.paymentMethodType] as? String, PrimerPaymentMethodType.applePay.rawValue)
    }
    
    func testUnableToPresentApplePay() {
        let diagnosticsId = "test-id-999"
        let error = PrimerError.unableToPresentApplePay(diagnosticsId: diagnosticsId)
        
        XCTAssertEqual(error.errorId, "unable-to-present-apple-pay")
        XCTAssertEqual(error.diagnosticsId, diagnosticsId)
        XCTAssertEqual(error.plainDescription, "Unable to present Apple Pay")
        
        let recoverySuggestion = """
        PassKit was unable to present the Apple Pay UI. Check merchantIdentifier \
        and other parameters are set correctly for the current environment.
        """
        XCTAssertEqual(error.recoverySuggestion, recoverySuggestion)
        
        // Test analytics context
        let context = error.analyticsContext
        XCTAssertEqual(context[AnalyticsContextKeys.paymentMethodType] as? String, PrimerPaymentMethodType.applePay.rawValue)
    }
    
    func testApplePayTimedOut() {
        let diagnosticsId = "test-id-timeout"
        let error = PrimerError.applePayTimedOut(diagnosticsId: diagnosticsId)
        
        XCTAssertEqual(error.errorId, "apple-pay-timed-out")
        XCTAssertEqual(error.diagnosticsId, diagnosticsId)
        XCTAssertEqual(error.plainDescription, "Apple Pay timed out")
        XCTAssertEqual(error.recoverySuggestion, "Make sure you have an active internet connection and your Apple Pay configuration is correct.")
        
        // Test analytics context
        let context = error.analyticsContext
        XCTAssertEqual(context[AnalyticsContextKeys.paymentMethodType] as? String, PrimerPaymentMethodType.applePay.rawValue)
    }
    
    func testUnableToMakePaymentsOnProvidedNetworks() {
        let diagnosticsId = "test-id-networks"
        let error = PrimerError.unableToMakePaymentsOnProvidedNetworks(diagnosticsId: diagnosticsId)
        
        XCTAssertEqual(error.errorId, "unable-to-make-payments-on-provided-networks")
        XCTAssertEqual(error.diagnosticsId, diagnosticsId)
        XCTAssertEqual(error.plainDescription, "Unable to make payments on provided networks")
        XCTAssertNil(error.recoverySuggestion)
        
        // Test analytics context
        let context = error.analyticsContext
        XCTAssertEqual(context[AnalyticsContextKeys.paymentMethodType] as? String, PrimerPaymentMethodType.applePay.rawValue)
    }
    
    // MARK: - Error Info Tests

    
    // MARK: - Exposed Error Tests
    
    func testExposedError() {
        let error = PrimerError.applePayDeviceNotSupported(diagnosticsId: "test")
        let exposedError = error.exposedError
        
        // Exposed error should be the same as the original error
        guard let exposedPrimerError = exposedError as? PrimerError else {
            XCTFail("Expected exposed error to be PrimerError")
            return
        }
        
        switch exposedPrimerError {
        case .applePayDeviceNotSupported:
            // Success
            break
        default:
            XCTFail("Expected applePayDeviceNotSupported")
        }
    }
}
