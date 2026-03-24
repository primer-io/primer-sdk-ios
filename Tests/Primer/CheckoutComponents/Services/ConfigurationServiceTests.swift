//
//  ConfigurationServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ConfigurationServiceTests: XCTestCase {

    private var sut: DefaultConfigurationService!

    override func setUp() {
        super.setUp()
        sut = DefaultConfigurationService()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
        sut = nil
        super.tearDown()
    }

    // MARK: - apiConfiguration

    func test_apiConfiguration_whenNil_returnsNil() {
        // Given - no SDKSessionHelper setup

        // When
        let result = sut.apiConfiguration

        // Then
        XCTAssertNil(result)
    }

    func test_apiConfiguration_whenSet_returnsConfiguration() {
        // Given
        SDKSessionHelper.setUp()

        // When
        let result = sut.apiConfiguration

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.coreUrl, "core_url")
    }

    // MARK: - checkoutModules

    func test_checkoutModules_whenConfigNil_returnsNil() {
        // Given - no SDKSessionHelper setup

        // When
        let result = sut.checkoutModules

        // Then
        XCTAssertNil(result)
    }

    func test_checkoutModules_whenModulesPresent_returnsModules() {
        // Given
        let modules = [makeBillingAddressModule()]
        SDKSessionHelper.setUp(checkoutModules: modules)

        // When
        let result = sut.checkoutModules

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?.first?.type, "BILLING_ADDRESS")
    }

    // MARK: - billingAddressOptions

    func test_billingAddressOptions_whenNoBillingModule_returnsNil() {
        // Given
        let modules = [makeCheckoutModule(type: "CARD_INFORMATION")]
        SDKSessionHelper.setUp(checkoutModules: modules)

        // When
        let result = sut.billingAddressOptions

        // Then
        XCTAssertNil(result)
    }

    func test_billingAddressOptions_whenBillingModulePresent_returnsOptions() {
        // Given
        let modules = [makeBillingAddressModule()]
        SDKSessionHelper.setUp(checkoutModules: modules)

        // When
        let result = sut.billingAddressOptions

        // Then
        XCTAssertNotNil(result)
    }

    // MARK: - currency

    func test_currency_whenConfigNil_returnsNil() {
        // Given - no SDKSessionHelper setup

        // When
        let result = sut.currency

        // Then
        XCTAssertNil(result)
    }

    func test_currency_whenOrderHasCurrency_returnsCurrency() {
        // Given
        let order = makeOrder(
            currencyCode: Currency(
                code: TestData.Currencies.usd,
                decimalDigits: TestData.Currencies.defaultDecimalDigits
            )
        )
        SDKSessionHelper.setUp(order: order)

        // When
        let result = sut.currency

        // Then
        XCTAssertEqual(result?.code, TestData.Currencies.usd)
    }

    // MARK: - amount

    func test_amount_whenConfigNil_returnsNil() {
        // Given - no SDKSessionHelper setup

        // When
        let result = sut.amount

        // Then
        XCTAssertNil(result)
    }

    func test_amount_prefersMerchantAmountOverTotalOrderAmount() {
        // Given
        let order = makeOrder(
            merchantAmount: TestData.Amounts.standard,
            totalOrderAmount: TestData.Amounts.large
        )
        SDKSessionHelper.setUp(order: order)

        // When
        let result = sut.amount

        // Then
        XCTAssertEqual(result, TestData.Amounts.standard)
    }

    func test_amount_fallsBackToTotalOrderAmount_whenMerchantAmountNil() {
        // Given
        let order = makeOrder(merchantAmount: nil, totalOrderAmount: TestData.Amounts.large)
        SDKSessionHelper.setUp(order: order)

        // When
        let result = sut.amount

        // Then
        XCTAssertEqual(result, TestData.Amounts.large)
    }

    func test_amount_returnsNil_whenBothAmountsNil() {
        // Given
        let order = makeOrder(merchantAmount: nil, totalOrderAmount: nil)
        SDKSessionHelper.setUp(order: order)

        // When
        let result = sut.amount

        // Then
        XCTAssertNil(result)
    }

    // MARK: - captureVaultedCardCvv

    func test_captureVaultedCardCvv_whenNoPaymentMethods_returnsFalse() {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [])

        // When
        let result = sut.captureVaultedCardCvv

        // Then
        XCTAssertFalse(result)
    }

    func test_captureVaultedCardCvv_whenCardOptionsTrue_returnsTrue() {
        // Given
        let cardMethod = PrimerPaymentMethod(
            id: TestData.PaymentMethodIds.cardId,
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.paymentCard.rawValue,
            name: TestData.PaymentMethodNames.cardName,
            processorConfigId: nil,
            surcharge: nil,
            options: CardOptions(
                threeDSecureEnabled: false,
                threeDSecureToken: nil,
                threeDSecureInitUrl: nil,
                threeDSecureProvider: "NETCETERA",
                processorConfigId: nil,
                captureVaultedCardCvv: true
            ),
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [cardMethod])

        // When
        let result = sut.captureVaultedCardCvv

        // Then
        XCTAssertTrue(result)
    }

    func test_captureVaultedCardCvv_whenCardOptionsFalse_returnsFalse() {
        // Given
        let cardMethod = PrimerPaymentMethod(
            id: TestData.PaymentMethodIds.cardId,
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.paymentCard.rawValue,
            name: TestData.PaymentMethodNames.cardName,
            processorConfigId: nil,
            surcharge: nil,
            options: CardOptions(
                threeDSecureEnabled: false,
                threeDSecureToken: nil,
                threeDSecureInitUrl: nil,
                threeDSecureProvider: "NETCETERA",
                processorConfigId: nil,
                captureVaultedCardCvv: false
            ),
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [cardMethod])

        // When
        let result = sut.captureVaultedCardCvv

        // Then
        XCTAssertFalse(result)
    }

    func test_captureVaultedCardCvv_whenNoCardPaymentMethod_returnsFalse() {
        // Given
        let paypalMethod = PrimerPaymentMethod(
            id: TestData.PaymentMethodIds.paypalId,
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: TestData.PaymentMethodNames.paypalName,
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paypalMethod])

        // When
        let result = sut.captureVaultedCardCvv

        // Then
        XCTAssertFalse(result)
    }

    func test_captureVaultedCardCvv_whenConfigNil_returnsFalse() {
        // Given - no SDKSessionHelper setup

        // When
        let result = sut.captureVaultedCardCvv

        // Then
        XCTAssertFalse(result)
    }
}

// MARK: - Helpers

@available(iOS 15.0, *)
private extension ConfigurationServiceTests {

    func makeOrder(
        merchantAmount: Int? = nil,
        totalOrderAmount: Int? = nil,
        currencyCode: Currency? = nil
    ) -> ClientSession.Order {
        ClientSession.Order(
            id: "order-123",
            merchantAmount: merchantAmount,
            totalOrderAmount: totalOrderAmount,
            totalTaxAmount: nil,
            countryCode: nil,
            currencyCode: currencyCode,
            fees: nil,
            lineItems: nil
        )
    }

    func makeBillingAddressModule() -> PrimerAPIConfiguration.CheckoutModule {
        PrimerAPIConfiguration.CheckoutModule(
            type: "BILLING_ADDRESS",
            requestUrlStr: nil,
            options: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions(
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
        )
    }

    func makeCheckoutModule(type: String) -> PrimerAPIConfiguration.CheckoutModule {
        PrimerAPIConfiguration.CheckoutModule(
            type: type,
            requestUrlStr: nil,
            options: nil
        )
    }
}
