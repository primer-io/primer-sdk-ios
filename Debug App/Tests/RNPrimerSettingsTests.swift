//
//  RNPrimerSettingsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import Debug_App
@testable import PrimerSDK

final class RNPrimerSettingsTests: XCTestCase {

    func testDecodingMinimalSettings() throws {
        let json = """
        {
            "paymentHandling": "AUTO",
            "clientSessionCachingEnabled": true,
            "apiVersion": "2.4"
        }
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(RNPrimerSettings.self, from: json)
        XCTAssertEqual(settings.paymentHandling, "AUTO")
        XCTAssertEqual(settings.clientSessionCachingEnabled, true)
        XCTAssertEqual(settings.apiVersion, "2.4")
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

    func testMapMinimalSettings() {
            let rnSettings = RNPrimerSettings(
                paymentHandling: "AUTO",
                localeData: RNPrimerLocaleData(languageCode: "en", localeCode: "US"),
                paymentMethodOptions: nil,
                uiOptions: nil,
                debugOptions: nil,
                clientSessionCachingEnabled: true,
                apiVersion: "2.4"
            )

            let mapped = RNPrimerSettingsMapper.map(from: rnSettings)

            XCTAssertEqual(mapped.paymentHandling, .auto)
            XCTAssertEqual(mapped.localeData.languageCode, "en")
            XCTAssertEqual(mapped.localeData.regionCode, "US")
            XCTAssertEqual(mapped.localeData.localeCode, "en-US")
            XCTAssertEqual(mapped.clientSessionCachingEnabled, true)
            XCTAssertEqual(mapped.apiVersion, .V2_4)
        }

        func testMapWithApplePayAndStripeOptions() {
            let rnSettings = RNPrimerSettings(
                paymentHandling: "MANUAL",
                localeData: nil,
                paymentMethodOptions: RNPrimerPaymentMethodOptions(
                    iOS: RNPrimerPaymentMethodOptions.IOSOptions(urlScheme: "myapp://"),
                    applePayOptions: RNPrimerApplePayOptions(
                        merchantIdentifier: "merchant.com.example",
                        merchantName: "Example Store",
                        isCaptureBillingAddressEnabled: true,
                        showApplePayForUnsupportedDevice: false,
                        checkProvidedNetworks: true,
                        shippingOptions: RNShippingOptions(
                            shippingContactFields: [.name, .postalAddress],
                            requireShippingMethod: true
                        ),
                        billingOptions: RNBillingOptions(requiredBillingContactFields: [.emailAddress])
                    ),
                    cardPaymentOptions: nil,
                    goCardlessOptions: nil,
                    klarnaOptions: nil,
                    threeDsOptions: nil,
                    stripeOptions: RNPrimerStripeOptions(
                        publishableKey: "pk_test_123",
                        mandateData: .template(RNPrimerStripeTemplateMandateData(merchantName: "My Merchant"))
                    )
                ),
                uiOptions: nil,
                debugOptions: nil,
                clientSessionCachingEnabled: nil,
                apiVersion: nil
            )

            let mapped = RNPrimerSettingsMapper.map(from: rnSettings)
            let pmOptions = mapped.paymentMethodOptions

            XCTAssertEqual(pmOptions.stripeOptions?.publishableKey, "pk_test_123")

            if case .templateMandate(let merchantName) = pmOptions.stripeOptions?.mandateData {
                XCTAssertEqual(merchantName, "My Merchant")
            } else {
                XCTFail("Expected .templateMandate")
            }

            guard let applePay = pmOptions.applePayOptions else {
                return XCTFail("Expected Apple Pay options")
            }

            XCTAssertEqual(applePay.merchantIdentifier, "merchant.com.example")
            XCTAssertEqual(applePay.merchantName, "Example Store")
            XCTAssertEqual(applePay.isCaptureBillingAddressEnabled, true)
            XCTAssertEqual(applePay.showApplePayForUnsupportedDevice, false)
            XCTAssertEqual(applePay.checkProvidedNetworks, true)
            XCTAssertEqual(applePay.shippingOptions?.requireShippingMethod, true)
            XCTAssertEqual(applePay.shippingOptions?.shippingContactFields, [PrimerApplePayOptions.RequiredContactField.name,
                                                                             PrimerApplePayOptions.RequiredContactField.postalAddress])
            XCTAssertEqual(applePay.billingOptions?.requiredBillingContactFields, [.emailAddress])
        }

        func testMapDebugAndUIOptions() {
            let rnSettings = RNPrimerSettings(
                paymentHandling: nil,
                localeData: nil,
                paymentMethodOptions: nil,
                uiOptions: RNPrimerUIOptions(
                    isInitScreenEnabled: false,
                    isSuccessScreenEnabled: false,
                    isErrorScreenEnabled: true,
                    dismissalMechanism: [.gestures]
                ),
                debugOptions: RNPrimerDebugOptions(is3DSSanityCheckEnabled: false),
                clientSessionCachingEnabled: nil,
                apiVersion: nil
            )

            let mapped = RNPrimerSettingsMapper.map(from: rnSettings)
            XCTAssertEqual(mapped.debugOptions.is3DSSanityCheckEnabled, false)
            XCTAssertEqual(mapped.uiOptions.isInitScreenEnabled, false)
            XCTAssertEqual(mapped.uiOptions.isSuccessScreenEnabled, false)
            XCTAssertEqual(mapped.uiOptions.isErrorScreenEnabled, true)
            XCTAssertEqual(mapped.uiOptions.dismissalMechanism, [.gestures])
        }
}
