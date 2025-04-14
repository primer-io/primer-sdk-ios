//
//  RNPrimerSettingsTests.swift
//  Debug App Tests
//
//  Created by Niall Quinn on 14/04/2025.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import Debug_App

final class RNPrimerSettingsTests: XCTestCase {

    func testDecodingMinimalSettings() throws {
        let json = """
        {
            "paymentHandling": "AUTO",
            "clientSessionCachingEnabled": true,
            "apiVersion": "2.3"
        }
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(RNPrimerSettings.self, from: json)
        XCTAssertEqual(settings.paymentHandling, "AUTO")
        XCTAssertEqual(settings.clientSessionCachingEnabled, true)
        XCTAssertEqual(settings.apiVersion, "2.3")
    }

    func testDecodingApplePayOptions() throws {
        let json = """
        {
            "applePayOptions": {
                "merchantIdentifier": "merchant.com.example",
                "merchantName": "Example Store",
                "isCaptureBillingAddressEnabled": true,
                "showApplePayForUnsupportedDevice": false,
                "checkProvidedNetworks": true,
                "shippingOptions": {
                    "shippingContactFields": ["name", "emailAddress"],
                    "requireShippingMethod": true
                },
                "billingOptions": {
                    "requiredBillingContactFields": ["phoneNumber"]
                }
            }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(RNPrimerPaymentMethodOptions.self, from: json)
        let options = decoded.applePayOptions
        XCTAssertEqual(options?.merchantIdentifier, "merchant.com.example")
        XCTAssertEqual(options?.merchantName, "Example Store")
        XCTAssertEqual(options?.isCaptureBillingAddressEnabled, true)
        XCTAssertEqual(options?.showApplePayForUnsupportedDevice, false)
        XCTAssertEqual(options?.checkProvidedNetworks, true)
        XCTAssertEqual(options?.shippingOptions?.shippingContactFields, [.name, .emailAddress])
        XCTAssertEqual(options?.shippingOptions?.requireShippingMethod, true)
        XCTAssertEqual(options?.billingOptions?.requiredBillingContactFields, [.phoneNumber])
    }

    func testDecodingStripeTemplateMandateData() throws {
        let json = """
        {
            "publishableKey": "pk_test_123",
            "mandateData": {
                "merchantName": "Example Store"
            }
        }
        """.data(using: .utf8)!

        let stripe = try JSONDecoder().decode(RNPrimerStripeOptions.self, from: json)

        switch stripe.mandateData {
        case .template(let data):
            XCTAssertEqual(data.merchantName, "Example Store")
        default:
            XCTFail("Expected template mandate data")
        }
    }

    func testDecodingStripeFullMandateData() throws {
        let json = """
        {
            "publishableKey": "pk_test_456",
            "mandateData": {
                "fullMandateText": "You authorize payment...",
                "fullMandateStringResourceName": "mandate_string"
            }
        }
        """.data(using: .utf8)!

        let stripe = try JSONDecoder().decode(RNPrimerStripeOptions.self, from: json)

        switch stripe.mandateData {
        case .full(let data):
            XCTAssertEqual(data.fullMandateText, "You authorize payment...")
            XCTAssertEqual(data.fullMandateStringResourceName, "mandate_string")
        default:
            XCTFail("Expected full mandate data")
        }
    }

    func testDecodingUIOptionsWithoutTheme() throws {
        let json = """
        {
            "isInitScreenEnabled": true,
            "isSuccessScreenEnabled": false,
            "isErrorScreenEnabled": true,
            "dismissalMechanism": ["gestures", "closeButton"]
        }
        """.data(using: .utf8)!

        let uiOptions = try JSONDecoder().decode(RNPrimerUIOptions.self, from: json)
        XCTAssertTrue(uiOptions.isInitScreenEnabled ?? false)
        XCTAssertFalse(uiOptions.isSuccessScreenEnabled ?? true)
        XCTAssertTrue(uiOptions.isErrorScreenEnabled ?? false)
        XCTAssertEqual(uiOptions.dismissalMechanism, [.gestures, .closeButton])
    }

    func testInvalidMandateDataFails() throws {
        let json = """
        {
            "publishableKey": "pk_test_invalid",
            "mandateData": {
                "unexpectedField": "value"
            }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(RNPrimerStripeOptions.self, from: json))
    }
}
