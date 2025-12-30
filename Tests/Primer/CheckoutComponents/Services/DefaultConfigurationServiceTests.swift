//
//  DefaultConfigurationServiceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for DefaultConfigurationService covering all configuration access methods.
@available(iOS 15.0, *)
final class DefaultConfigurationServiceTests: XCTestCase {

    private var sut: DefaultConfigurationService!

    override func setUp() {
        super.setUp()
        sut = DefaultConfigurationService()
    }

    override func tearDown() {
        PrimerAPIConfigurationModule.apiConfiguration = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - apiConfiguration Tests

    func test_apiConfiguration_whenModuleHasConfiguration_returnsConfiguration() {
        // Given
        let config = createMinimalConfiguration()
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.apiConfiguration

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.coreUrl, "https://core.primer.io")
    }

    func test_apiConfiguration_whenModuleHasNoConfiguration_returnsNil() {
        // Given
        PrimerAPIConfigurationModule.apiConfiguration = nil

        // When
        let result = sut.apiConfiguration

        // Then
        XCTAssertNil(result)
    }

    // MARK: - checkoutModules Tests

    func test_checkoutModules_whenConfigHasModules_returnsModules() {
        // Given
        let modules = [
            PrimerAPIConfiguration.CheckoutModule(
                type: "BILLING_ADDRESS",
                requestUrlStr: nil,
                options: nil
            ),
            PrimerAPIConfiguration.CheckoutModule(
                type: "SHIPPING",
                requestUrlStr: nil,
                options: nil
            )
        ]
        let config = createConfiguration(checkoutModules: modules)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.checkoutModules

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[0].type, "BILLING_ADDRESS")
        XCTAssertEqual(result?[1].type, "SHIPPING")
    }

    func test_checkoutModules_whenConfigHasNoModules_returnsNil() {
        // Given
        let config = createConfiguration(checkoutModules: nil)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.checkoutModules

        // Then
        XCTAssertNil(result)
    }

    // MARK: - billingAddressOptions Tests

    func test_billingAddressOptions_whenBillingAddressModuleExists_returnsOptions() {
        // Given
        let postalCodeOptions = PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions(
            firstName: true,
            lastName: true,
            city: true,
            postalCode: true,
            addressLine1: true,
            addressLine2: false,
            countryCode: true,
            phoneNumber: false,
            state: false
        )
        let billingModule = PrimerAPIConfiguration.CheckoutModule(
            type: "BILLING_ADDRESS",
            requestUrlStr: nil,
            options: postalCodeOptions
        )
        let config = createConfiguration(checkoutModules: [billingModule])
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.billingAddressOptions

        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.firstName ?? false)
        XCTAssertTrue(result?.lastName ?? false)
        XCTAssertTrue(result?.city ?? false)
        XCTAssertFalse(result?.addressLine2 ?? true)
    }

    func test_billingAddressOptions_whenNoBillingAddressModule_returnsNil() {
        // Given
        let shippingModule = PrimerAPIConfiguration.CheckoutModule(
            type: "SHIPPING",
            requestUrlStr: nil,
            options: nil
        )
        let config = createConfiguration(checkoutModules: [shippingModule])
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.billingAddressOptions

        // Then
        XCTAssertNil(result)
    }

    func test_billingAddressOptions_whenNoModules_returnsNil() {
        // Given
        let config = createConfiguration(checkoutModules: nil)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.billingAddressOptions

        // Then
        XCTAssertNil(result)
    }

    // MARK: - currency Tests

    func test_currency_whenClientSessionHasCurrency_returnsCurrency() {
        // Given
        let order = ClientSession.Order(
            id: "order-id",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: Currency(code: "USD", decimalDigits: 2),
            fees: nil,
            lineItems: nil
        )
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-id",
            paymentMethod: nil,
            order: order,
            customer: nil,
            testId: nil
        )
        let config = createConfiguration(clientSession: clientSession)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.currency

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "USD")
        XCTAssertEqual(result?.decimalDigits, 2)
    }

    func test_currency_whenNoClientSession_returnsNil() {
        // Given
        let config = createConfiguration(clientSession: nil)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.currency

        // Then
        XCTAssertNil(result)
    }

    // MARK: - amount Tests

    func test_amount_whenMerchantAmountExists_returnsMerchantAmount() {
        // Given
        let order = ClientSession.Order(
            id: "order-id",
            merchantAmount: 1500,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: nil,
            fees: nil,
            lineItems: nil
        )
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-id",
            paymentMethod: nil,
            order: order,
            customer: nil,
            testId: nil
        )
        let config = createConfiguration(clientSession: clientSession)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.amount

        // Then
        XCTAssertEqual(result, 1500)
    }

    func test_amount_whenNoMerchantAmount_returnsTotalOrderAmount() {
        // Given
        let order = ClientSession.Order(
            id: "order-id",
            merchantAmount: nil,
            totalOrderAmount: 2000,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: nil,
            fees: nil,
            lineItems: nil
        )
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-id",
            paymentMethod: nil,
            order: order,
            customer: nil,
            testId: nil
        )
        let config = createConfiguration(clientSession: clientSession)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.amount

        // Then
        XCTAssertEqual(result, 2000)
    }

    func test_amount_whenNoAmounts_returnsNil() {
        // Given
        let order = ClientSession.Order(
            id: "order-id",
            merchantAmount: nil,
            totalOrderAmount: nil,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: nil,
            fees: nil,
            lineItems: nil
        )
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-id",
            paymentMethod: nil,
            order: order,
            customer: nil,
            testId: nil
        )
        let config = createConfiguration(clientSession: clientSession)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.amount

        // Then
        XCTAssertNil(result)
    }

    func test_amount_whenNoClientSession_returnsNil() {
        // Given
        let config = createConfiguration(clientSession: nil)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.amount

        // Then
        XCTAssertNil(result)
    }

    // MARK: - captureVaultedCardCvv Tests

    func test_captureVaultedCardCvv_whenCardOptionsHasCaptureTrue_returnsTrue() {
        // Given
        let cardOptions = CardOptions(
            threeDSecureEnabled: false,
            threeDSecureToken: nil,
            threeDSecureInitUrl: nil,
            threeDSecureProvider: "",
            processorConfigId: nil,
            captureVaultedCardCvv: true
        )
        let cardPaymentMethod = PrimerPaymentMethod(
            id: "card-method-id",
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.paymentCard.rawValue,
            name: "Card",
            processorConfigId: nil,
            surcharge: nil,
            options: cardOptions,
            displayMetadata: nil
        )
        let config = createConfiguration(paymentMethods: [cardPaymentMethod])
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.captureVaultedCardCvv

        // Then
        XCTAssertTrue(result)
    }

    func test_captureVaultedCardCvv_whenCardOptionsHasCaptureFalse_returnsFalse() {
        // Given
        let cardOptions = CardOptions(
            threeDSecureEnabled: false,
            threeDSecureToken: nil,
            threeDSecureInitUrl: nil,
            threeDSecureProvider: "",
            processorConfigId: nil,
            captureVaultedCardCvv: false
        )
        let cardPaymentMethod = PrimerPaymentMethod(
            id: "card-method-id",
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.paymentCard.rawValue,
            name: "Card",
            processorConfigId: nil,
            surcharge: nil,
            options: cardOptions,
            displayMetadata: nil
        )
        let config = createConfiguration(paymentMethods: [cardPaymentMethod])
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.captureVaultedCardCvv

        // Then
        XCTAssertFalse(result)
    }

    func test_captureVaultedCardCvv_whenNoCardPaymentMethod_returnsFalse() {
        // Given
        let paypalMethod = PrimerPaymentMethod(
            id: "paypal-method-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = createConfiguration(paymentMethods: [paypalMethod])
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.captureVaultedCardCvv

        // Then
        XCTAssertFalse(result)
    }

    func test_captureVaultedCardCvv_whenNoPaymentMethods_returnsFalse() {
        // Given
        let config = createConfiguration(paymentMethods: nil)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.captureVaultedCardCvv

        // Then
        XCTAssertFalse(result)
    }

    func test_captureVaultedCardCvv_whenCardHasNoOptions_returnsFalse() {
        // Given
        let cardPaymentMethod = PrimerPaymentMethod(
            id: "card-method-id",
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.paymentCard.rawValue,
            name: "Card",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = createConfiguration(paymentMethods: [cardPaymentMethod])
        PrimerAPIConfigurationModule.apiConfiguration = config

        // When
        let result = sut.captureVaultedCardCvv

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Helpers

    private func createMinimalConfiguration() -> PrimerAPIConfiguration {
        PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: nil,
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )
    }

    private func createConfiguration(
        clientSession: ClientSession.APIResponse? = nil,
        paymentMethods: [PrimerPaymentMethod]? = nil,
        checkoutModules: [PrimerAPIConfiguration.CheckoutModule]? = nil
    ) -> PrimerAPIConfiguration {
        PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: clientSession,
            paymentMethods: paymentMethods,
            primerAccountId: nil,
            keys: nil,
            checkoutModules: checkoutModules
        )
    }
}
