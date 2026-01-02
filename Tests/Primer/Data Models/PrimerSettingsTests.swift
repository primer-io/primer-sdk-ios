//
//  PrimerSettingsTests.swift
//
//  Copyright (c) 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PrimerSettingsTests: XCTestCase {

    // MARK: - PrimerSettings Initialization Tests

    func test_primerSettings_defaultInit_hasExpectedDefaults() {
        // Given/When
        let settings = PrimerSettings()

        // Then
        XCTAssertEqual(settings.paymentHandling, .auto)
        XCTAssertNotNil(settings.localeData)
        XCTAssertNotNil(settings.paymentMethodOptions)
        XCTAssertNotNil(settings.uiOptions)
        XCTAssertNotNil(settings.debugOptions)
        XCTAssertFalse(settings.clientSessionCachingEnabled)
        XCTAssertEqual(settings.apiVersion, .V2_4)
    }

    func test_primerSettings_customPaymentHandling_setsCorrectly() {
        // Given/When
        let settings = PrimerSettings(paymentHandling: .manual)

        // Then
        XCTAssertEqual(settings.paymentHandling, .manual)
    }

    func test_primerSettings_clientSessionCachingEnabled_setsCorrectly() {
        // Given/When
        let settings = PrimerSettings(clientSessionCachingEnabled: true)

        // Then
        XCTAssertTrue(settings.clientSessionCachingEnabled)
    }

    func test_primerSettings_fullInit_allPropertiesSet() {
        // Given
        let localeData = PrimerLocaleData()
        let paymentMethodOptions = PrimerPaymentMethodOptions()
        let uiOptions = PrimerUIOptions()
        let debugOptions = PrimerDebugOptions()

        // When
        let settings = PrimerSettings(
            paymentHandling: .manual,
            localeData: localeData,
            paymentMethodOptions: paymentMethodOptions,
            uiOptions: uiOptions,
            debugOptions: debugOptions,
            clientSessionCachingEnabled: true,
            apiVersion: .V2_4
        )

        // Then
        XCTAssertEqual(settings.paymentHandling, .manual)
        XCTAssertNotNil(settings.localeData)
        XCTAssertNotNil(settings.paymentMethodOptions)
        XCTAssertNotNil(settings.uiOptions)
        XCTAssertNotNil(settings.debugOptions)
        XCTAssertTrue(settings.clientSessionCachingEnabled)
        XCTAssertEqual(settings.apiVersion, .V2_4)
    }

    func test_primerSettings_codable_encodesAndDecodes() throws {
        // Given
        let originalSettings = PrimerSettings(
            paymentHandling: .manual,
            clientSessionCachingEnabled: true,
            apiVersion: .V2_4
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSettings)
        let decoder = JSONDecoder()
        let decodedSettings = try decoder.decode(PrimerSettings.self, from: data)

        // Then
        XCTAssertEqual(decodedSettings.paymentHandling, originalSettings.paymentHandling)
        XCTAssertEqual(decodedSettings.clientSessionCachingEnabled, originalSettings.clientSessionCachingEnabled)
        XCTAssertEqual(decodedSettings.apiVersion, originalSettings.apiVersion)
    }

    // MARK: - PrimerPaymentHandling Tests

    func test_paymentHandling_auto_hasCorrectRawValue() {
        XCTAssertEqual(PrimerPaymentHandling.auto.rawValue, "AUTO")
    }

    func test_paymentHandling_manual_hasCorrectRawValue() {
        XCTAssertEqual(PrimerPaymentHandling.manual.rawValue, "MANUAL")
    }

    func test_paymentHandling_codable_roundTrip() throws {
        // Given
        let modes: [PrimerPaymentHandling] = [.auto, .manual]

        for mode in modes {
            // When
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(PrimerPaymentHandling.self, from: data)

            // Then
            XCTAssertEqual(mode, decoded, "Failed for mode: \(mode)")
        }
    }

    // MARK: - PrimerApplePayOptions Tests

    func test_applePayOptions_basicInit_setsRequiredFields() {
        // Given/When
        let options = PrimerApplePayOptions(
            merchantIdentifier: "merchant.com.example",
            merchantName: "Example Store"
        )

        // Then
        XCTAssertEqual(options.merchantIdentifier, "merchant.com.example")
        XCTAssertTrue(options.showApplePayForUnsupportedDevice)
        XCTAssertTrue(options.checkProvidedNetworks)
        XCTAssertNil(options.shippingOptions)
        XCTAssertNil(options.billingOptions)
    }

    func test_applePayOptions_fullInit_setsAllFields() {
        // Given
        let shippingOptions = PrimerApplePayOptions.ShippingOptions(
            shippingContactFields: [.name, .emailAddress],
            requireShippingMethod: true
        )
        let billingOptions = PrimerApplePayOptions.BillingOptions(
            requiredBillingContactFields: [.postalAddress]
        )

        // When
        let options = PrimerApplePayOptions(
            merchantIdentifier: "merchant.com.example",
            merchantName: "Example Store",
            isCaptureBillingAddressEnabled: true,
            showApplePayForUnsupportedDevice: false,
            checkProvidedNetworks: false,
            shippingOptions: shippingOptions,
            billingOptions: billingOptions
        )

        // Then
        XCTAssertEqual(options.merchantIdentifier, "merchant.com.example")
        XCTAssertFalse(options.showApplePayForUnsupportedDevice)
        XCTAssertFalse(options.checkProvidedNetworks)
        XCTAssertNotNil(options.shippingOptions)
        XCTAssertNotNil(options.billingOptions)
        XCTAssertEqual(options.shippingOptions?.shippingContactFields, [.name, .emailAddress])
        XCTAssertTrue(options.shippingOptions?.requireShippingMethod ?? false)
    }

    func test_applePayOptions_shippingOptions_init() {
        // Given/When
        let options = PrimerApplePayOptions.ShippingOptions(
            shippingContactFields: [.phoneNumber],
            requireShippingMethod: false
        )

        // Then
        XCTAssertEqual(options.shippingContactFields, [.phoneNumber])
        XCTAssertFalse(options.requireShippingMethod)
    }

    func test_applePayOptions_billingOptions_init() {
        // Given/When
        let options = PrimerApplePayOptions.BillingOptions(
            requiredBillingContactFields: [.name, .postalAddress]
        )

        // Then
        XCTAssertEqual(options.requiredBillingContactFields, [.name, .postalAddress])
    }

    func test_applePayOptions_requiredContactField_rawValues() {
        XCTAssertEqual(PrimerApplePayOptions.RequiredContactField.name.rawValue, "name")
        XCTAssertEqual(PrimerApplePayOptions.RequiredContactField.emailAddress.rawValue, "emailAddress")
        XCTAssertEqual(PrimerApplePayOptions.RequiredContactField.phoneNumber.rawValue, "phoneNumber")
        XCTAssertEqual(PrimerApplePayOptions.RequiredContactField.postalAddress.rawValue, "postalAddress")
    }

    func test_applePayOptions_codable_roundTrip() throws {
        // Given
        let options = PrimerApplePayOptions(
            merchantIdentifier: "merchant.id",
            merchantName: "Name",
            isCaptureBillingAddressEnabled: true,
            showApplePayForUnsupportedDevice: false,
            checkProvidedNetworks: true
        )

        // When
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(PrimerApplePayOptions.self, from: data)

        // Then
        XCTAssertEqual(decoded.merchantIdentifier, options.merchantIdentifier)
        XCTAssertEqual(decoded.showApplePayForUnsupportedDevice, options.showApplePayForUnsupportedDevice)
        XCTAssertEqual(decoded.checkProvidedNetworks, options.checkProvidedNetworks)
    }

    // MARK: - PrimerKlarnaOptions Tests

    func test_klarnaOptions_init_setsDescription() {
        // Given/When
        let options = PrimerKlarnaOptions(recurringPaymentDescription: "Monthly subscription")

        // Then
        XCTAssertEqual(options.recurringPaymentDescription, "Monthly subscription")
    }

    func test_klarnaOptions_codable_roundTrip() throws {
        // Given
        let options = PrimerKlarnaOptions(recurringPaymentDescription: "Test description")

        // When
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(PrimerKlarnaOptions.self, from: data)

        // Then
        XCTAssertEqual(decoded.recurringPaymentDescription, options.recurringPaymentDescription)
    }

    func test_klarnaOptions_emptyDescription_allowed() {
        // Given/When
        let options = PrimerKlarnaOptions(recurringPaymentDescription: "")

        // Then
        XCTAssertEqual(options.recurringPaymentDescription, "")
    }

    // MARK: - PrimerStripeOptions Tests

    func test_stripeOptions_init_setsPublishableKey() {
        // Given/When
        let options = PrimerStripeOptions(publishableKey: "pk_test_123")

        // Then
        XCTAssertEqual(options.publishableKey, "pk_test_123")
        XCTAssertNil(options.mandateData)
    }

    func test_stripeOptions_withFullMandate_setsCorrectly() {
        // Given/When
        let options = PrimerStripeOptions(
            publishableKey: "pk_test_123",
            mandateData: .fullMandate(text: "I authorize debits to my account")
        )

        // Then
        if case .fullMandate(let text) = options.mandateData {
            XCTAssertEqual(text, "I authorize debits to my account")
        } else {
            XCTFail("Expected fullMandate")
        }
    }

    func test_stripeOptions_withTemplateMandate_setsCorrectly() {
        // Given/When
        let options = PrimerStripeOptions(
            publishableKey: "pk_test_123",
            mandateData: .templateMandate(merchantName: "Test Merchant")
        )

        // Then
        if case .templateMandate(let merchantName) = options.mandateData {
            XCTAssertEqual(merchantName, "Test Merchant")
        } else {
            XCTFail("Expected templateMandate")
        }
    }

    func test_stripeOptions_equatable_sameAreEqual() {
        // Given
        let options1 = PrimerStripeOptions(
            publishableKey: "pk_test_123",
            mandateData: .fullMandate(text: "Auth text")
        )
        let options2 = PrimerStripeOptions(
            publishableKey: "pk_test_123",
            mandateData: .fullMandate(text: "Auth text")
        )

        // Then
        XCTAssertEqual(options1, options2)
    }

    func test_stripeOptions_equatable_differentAreNotEqual() {
        // Given
        let options1 = PrimerStripeOptions(publishableKey: "pk_test_123")
        let options2 = PrimerStripeOptions(publishableKey: "pk_test_456")

        // Then
        XCTAssertNotEqual(options1, options2)
    }

    func test_stripeOptions_codable_roundTrip() throws {
        // Given
        let options = PrimerStripeOptions(
            publishableKey: "pk_test_123",
            mandateData: .templateMandate(merchantName: "Merchant")
        )

        // When
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(PrimerStripeOptions.self, from: data)

        // Then
        XCTAssertEqual(decoded, options)
    }

    // MARK: - PrimerCardPaymentOptions Tests

    func test_cardPaymentOptions_defaultInit_hasDropdownStyle() {
        // Given/When
        let options = PrimerCardPaymentOptions()

        // Then
        XCTAssertEqual(options.networkSelectorStyle, .dropdown)
    }

    func test_cardPaymentOptions_inlineStyle_setsCorrectly() {
        // Given/When
        let options = PrimerCardPaymentOptions(networkSelectorStyle: .inline)

        // Then
        XCTAssertEqual(options.networkSelectorStyle, .inline)
    }

    func test_cardPaymentOptions_codable_roundTrip() throws {
        // Given
        let options = PrimerCardPaymentOptions(networkSelectorStyle: .inline)

        // When
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(PrimerCardPaymentOptions.self, from: data)

        // Then
        XCTAssertEqual(decoded.networkSelectorStyle, options.networkSelectorStyle)
    }

    // MARK: - CardNetworkSelectorStyle Tests

    func test_cardNetworkSelectorStyle_rawValues() {
        XCTAssertEqual(CardNetworkSelectorStyle.inline.rawValue, "inline")
        XCTAssertEqual(CardNetworkSelectorStyle.dropdown.rawValue, "dropdown")
    }

    func test_cardNetworkSelectorStyle_codable_roundTrip() throws {
        // Given
        let styles: [CardNetworkSelectorStyle] = [.inline, .dropdown]

        for style in styles {
            // When
            let data = try JSONEncoder().encode(style)
            let decoded = try JSONDecoder().decode(CardNetworkSelectorStyle.self, from: data)

            // Then
            XCTAssertEqual(style, decoded, "Failed for style: \(style)")
        }
    }

    // MARK: - PrimerUIOptions Tests

    func test_uiOptions_defaultInit_hasExpectedDefaults() {
        // Given/When
        let options = PrimerUIOptions()

        // Then
        XCTAssertTrue(options.isInitScreenEnabled)
        XCTAssertTrue(options.isSuccessScreenEnabled)
        XCTAssertTrue(options.isErrorScreenEnabled)
        XCTAssertEqual(options.dismissalMechanism, [.gestures])
        XCTAssertNil(options.cardFormUIOptions)
        XCTAssertEqual(options.appearanceMode, .system)
        XCTAssertNotNil(options.theme)
    }

    func test_uiOptions_allScreensDisabled_setsCorrectly() {
        // Given/When
        let options = PrimerUIOptions(
            isInitScreenEnabled: false,
            isSuccessScreenEnabled: false,
            isErrorScreenEnabled: false
        )

        // Then
        XCTAssertFalse(options.isInitScreenEnabled)
        XCTAssertFalse(options.isSuccessScreenEnabled)
        XCTAssertFalse(options.isErrorScreenEnabled)
    }

    func test_uiOptions_customDismissalMechanism_setsCorrectly() {
        // Given/When
        let options = PrimerUIOptions(dismissalMechanism: [.closeButton])

        // Then
        XCTAssertEqual(options.dismissalMechanism, [.closeButton])
    }

    func test_uiOptions_multipleDismissalMechanisms_setsCorrectly() {
        // Given/When
        let options = PrimerUIOptions(dismissalMechanism: [.gestures, .closeButton])

        // Then
        XCTAssertEqual(options.dismissalMechanism.count, 2)
        XCTAssertTrue(options.dismissalMechanism.contains(.gestures))
        XCTAssertTrue(options.dismissalMechanism.contains(.closeButton))
    }

    func test_uiOptions_withCardFormUIOptions_setsCorrectly() {
        // Given
        let cardFormOptions = PrimerCardFormUIOptions(payButtonAddNewCard: true)

        // When
        let options = PrimerUIOptions(cardFormUIOptions: cardFormOptions)

        // Then
        XCTAssertNotNil(options.cardFormUIOptions)
        XCTAssertTrue(options.cardFormUIOptions?.payButtonAddNewCard ?? false)
    }

    // MARK: - DismissalMechanism Tests

    func test_dismissalMechanism_codable_roundTrip() throws {
        // Given
        let mechanisms: [DismissalMechanism] = [.gestures, .closeButton]

        for mechanism in mechanisms {
            // When
            let data = try JSONEncoder().encode(mechanism)
            let decoded = try JSONDecoder().decode(DismissalMechanism.self, from: data)

            // Then
            XCTAssertEqual(mechanism, decoded, "Failed for mechanism: \(mechanism)")
        }
    }

    // MARK: - PrimerCardFormUIOptions Tests

    func test_cardFormUIOptions_defaultInit_payButtonAddNewCardFalse() {
        // Given/When
        let options = PrimerCardFormUIOptions()

        // Then
        XCTAssertFalse(options.payButtonAddNewCard)
    }

    func test_cardFormUIOptions_customInit_payButtonAddNewCardTrue() {
        // Given/When
        let options = PrimerCardFormUIOptions(payButtonAddNewCard: true)

        // Then
        XCTAssertTrue(options.payButtonAddNewCard)
    }

    func test_cardFormUIOptions_codable_roundTrip() throws {
        // Given
        let options = PrimerCardFormUIOptions(payButtonAddNewCard: true)

        // When
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(PrimerCardFormUIOptions.self, from: data)

        // Then
        XCTAssertEqual(decoded.payButtonAddNewCard, options.payButtonAddNewCard)
    }

    // MARK: - PrimerDebugOptions Tests

    func test_debugOptions_defaultInit_sanityCheckEnabled() {
        // Given/When
        let options = PrimerDebugOptions()

        // Then
        XCTAssertTrue(options.is3DSSanityCheckEnabled)
    }

    func test_debugOptions_explicitFalse_disablesSanityCheck() {
        // Given/When
        let options = PrimerDebugOptions(is3DSSanityCheckEnabled: false)

        // Then
        XCTAssertFalse(options.is3DSSanityCheckEnabled)
    }

    func test_debugOptions_explicitTrue_enablesSanityCheck() {
        // Given/When
        let options = PrimerDebugOptions(is3DSSanityCheckEnabled: true)

        // Then
        XCTAssertTrue(options.is3DSSanityCheckEnabled)
    }

    func test_debugOptions_nilInit_defaultsToTrue() {
        // Given/When
        let options = PrimerDebugOptions(is3DSSanityCheckEnabled: nil)

        // Then
        XCTAssertTrue(options.is3DSSanityCheckEnabled)
    }

    func test_debugOptions_codable_roundTrip() throws {
        // Given
        let options = PrimerDebugOptions(is3DSSanityCheckEnabled: false)

        // When
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(PrimerDebugOptions.self, from: data)

        // Then
        XCTAssertEqual(decoded.is3DSSanityCheckEnabled, options.is3DSSanityCheckEnabled)
    }

    // MARK: - PrimerThreeDsOptions Tests

    func test_threeDsOptions_defaultInit_hasNilUrl() {
        // Given/When
        let options = PrimerThreeDsOptions()

        // Then
        XCTAssertNil(options.threeDsAppRequestorUrl)
    }

    func test_threeDsOptions_withUrl_setsCorrectly() {
        // Given/When
        let options = PrimerThreeDsOptions(threeDsAppRequestorUrl: "https://example.com/3ds")

        // Then
        XCTAssertEqual(options.threeDsAppRequestorUrl, "https://example.com/3ds")
    }

    func test_threeDsOptions_equatable_sameAreEqual() {
        // Given
        let options1 = PrimerThreeDsOptions(threeDsAppRequestorUrl: "https://example.com")
        let options2 = PrimerThreeDsOptions(threeDsAppRequestorUrl: "https://example.com")

        // Then
        XCTAssertEqual(options1, options2)
    }

    func test_threeDsOptions_equatable_differentAreNotEqual() {
        // Given
        let options1 = PrimerThreeDsOptions(threeDsAppRequestorUrl: "https://example1.com")
        let options2 = PrimerThreeDsOptions(threeDsAppRequestorUrl: "https://example2.com")

        // Then
        XCTAssertNotEqual(options1, options2)
    }

    func test_threeDsOptions_codable_roundTrip() throws {
        // Given
        let options = PrimerThreeDsOptions(threeDsAppRequestorUrl: "https://test.com")

        // When
        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(PrimerThreeDsOptions.self, from: data)

        // Then
        XCTAssertEqual(decoded, options)
    }

    // MARK: - PrimerApiVersion Tests

    func test_apiVersion_V2_4_hasCorrectRawValue() {
        XCTAssertEqual(PrimerApiVersion.V2_4.rawValue, "2.4")
    }

    func test_apiVersion_latest_isV2_4() {
        XCTAssertEqual(PrimerApiVersion.latest, .V2_4)
    }

    func test_apiVersion_codable_roundTrip() throws {
        // Given
        let version = PrimerApiVersion.V2_4

        // When
        let data = try JSONEncoder().encode(version)
        let decoded = try JSONDecoder().decode(PrimerApiVersion.self, from: data)

        // Then
        XCTAssertEqual(version, decoded)
    }

    // MARK: - PrimerPaymentMethodOptions Additional Tests

    func test_paymentMethodOptions_defaultInit_allOptionsNil() {
        // Given/When
        let options = PrimerPaymentMethodOptions()

        // Then
        XCTAssertNil(options.applePayOptions)
        XCTAssertNil(options.klarnaOptions)
        XCTAssertNil(options.threeDsOptions)
        XCTAssertNil(options.stripeOptions)
    }

    func test_paymentMethodOptions_withAllOptions_setsCorrectly() {
        // Given
        let applePayOptions = PrimerApplePayOptions(merchantIdentifier: "merchant.id", merchantName: "Name")
        let klarnaOptions = PrimerKlarnaOptions(recurringPaymentDescription: "Desc")
        let threeDsOptions = PrimerThreeDsOptions(threeDsAppRequestorUrl: "https://test.com")
        let stripeOptions = PrimerStripeOptions(publishableKey: "pk_test")

        // When
        let options = PrimerPaymentMethodOptions(
            urlScheme: "myapp://callback",
            applePayOptions: applePayOptions,
            klarnaOptions: klarnaOptions,
            threeDsOptions: threeDsOptions,
            stripeOptions: stripeOptions
        )

        // Then
        XCTAssertNotNil(options.applePayOptions)
        XCTAssertNotNil(options.klarnaOptions)
        XCTAssertNotNil(options.threeDsOptions)
        XCTAssertNotNil(options.stripeOptions)
    }

    func test_paymentMethodOptions_validUrlScheme_noScheme_throws() {
        // Given
        let options = PrimerPaymentMethodOptions(urlScheme: nil)

        // Then
        XCTAssertThrowsError(try options.validUrlForUrlScheme())
    }

    func test_paymentMethodOptions_cardPaymentOptions_defaultValue() {
        // Given/When
        let options = PrimerPaymentMethodOptions()

        // Then
        XCTAssertEqual(options.cardPaymentOptions.networkSelectorStyle, .dropdown)
    }
}
