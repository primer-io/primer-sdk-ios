//
//  ApplePayRequestBuilderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ApplePayRequestBuilderTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func tearDown() async throws {
        SDKSessionHelper.tearDown()
        // Reset settings to default
        DependencyContainer.register(PrimerSettings() as PrimerSettingsProtocol)
        try await super.tearDown()
    }

    // MARK: - Success Tests

    func test_build_success_withValidConfiguration() throws {
        // Given
        setupValidConfiguration()

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then
        XCTAssertEqual(request.merchantIdentifier, ApplePayTestData.Constants.merchantIdentifier)
        XCTAssertEqual(request.countryCode.rawValue, "GB")
        XCTAssertEqual(request.currency.code, "GBP")
        XCTAssertFalse(request.items.isEmpty)
    }

    func test_build_success_withMerchantAmount_createsSingleSummaryItem() throws {
        // Given
        let order = ClientSession.Order(
            id: "order_id",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .gb,
            currencyCode: Currency(code: "GBP", decimalDigits: 2),
            fees: nil,
            lineItems: nil,
            shippingMethod: nil
        )
        setupConfiguration(withOrder: order)

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then
        XCTAssertEqual(request.items.count, 1)
        XCTAssertEqual(request.items.first?.name, ApplePayTestData.Constants.merchantName)
    }

    func test_build_success_withLineItems_createsMultipleOrderItems() throws {
        // Given
        let lineItem = ClientSession.Order.LineItem(
            itemId: "item_1",
            quantity: 2,
            amount: 500,
            discountAmount: nil,
            name: "Test Item",
            description: "Test Item Description",
            taxAmount: nil,
            taxCode: nil,
            productType: nil
        )
        let order = ClientSession.Order(
            id: "order_id",
            merchantAmount: nil,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .gb,
            currencyCode: Currency(code: "GBP", decimalDigits: 2),
            fees: nil,
            lineItems: [lineItem],
            shippingMethod: nil
        )
        setupConfiguration(withOrder: order)

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then
        // Should have line item + summary item
        XCTAssertEqual(request.items.count, 2)
    }

    func test_build_success_withLineItemsAndFees_includesSurcharge() throws {
        // Given
        setupConfiguration(withOrder: ApplePayTestData.orderWithLineItemsAndFees)

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then
        // Should have: line item + surcharge fee + summary item = 3 items
        XCTAssertEqual(request.items.count, 3)

        // Verify surcharge item exists (surcharge uses localized string "Additional fees")
        let surchargeItem = request.items.first(where: { $0.name.contains("Additional") || $0.name.contains("fee") })
        XCTAssertNotNil(surchargeItem, "Expected surcharge item in order items")
    }

    func test_build_success_withShippingModule_includesShippingMethods() throws {
        // Given
        setupConfigurationWithShipping(withOrder: ApplePayTestData.orderWithLineItemsAndFees)

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then
        XCTAssertNotNil(request.shippingMethods)
        XCTAssertEqual(request.shippingMethods?.count, 1)
        XCTAssertEqual(request.shippingMethods?.first?.label, "Standard Shipping")
    }

    func test_build_success_withShippingModule_includesShippingInOrderItems() throws {
        // Given
        setupConfigurationWithShipping(withOrder: ApplePayTestData.orderWithLineItemsAndFees)

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then
        // Should have: line item + surcharge fee + shipping + summary item = 4 items
        XCTAssertEqual(request.items.count, 4)

        // Verify shipping item exists
        let shippingItem = request.items.first(where: { $0.name == "Shipping" })
        XCTAssertNotNil(shippingItem, "Expected shipping item in order items")
    }

    func test_build_success_withZeroDecimalCurrency_calculatesCorrectly() throws {
        // Given - Use JPY which is zero decimal
        let order = ClientSession.Order(
            id: "order_id",
            merchantAmount: nil,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .jp,
            currencyCode: Currency(code: "JPY", decimalDigits: 0),
            fees: nil,
            lineItems: [
                ClientSession.Order.LineItem(
                    itemId: "item_1",
                    quantity: 1,
                    amount: 1000,
                    discountAmount: nil,
                    name: "Test Item",
                    description: nil,
                    taxAmount: nil,
                    taxCode: nil,
                    productType: nil
                )
            ],
            shippingMethod: nil
        )
        setupConfigurationWithZeroDecimalCurrency(withOrder: order)

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then
        XCTAssertEqual(request.currency.code, "JPY")
        XCTAssertEqual(request.countryCode.rawValue, "JP")
    }

    // MARK: - Failure Tests

    func test_build_failure_whenCountryCodeMissing_throwsError() {
        // Given - Order without country code
        let order = ClientSession.Order(
            id: "order_id",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: nil,
            currencyCode: Currency(code: "GBP", decimalDigits: 2),
            fees: nil,
            lineItems: nil,
            shippingMethod: nil
        )
        setupConfiguration(withOrder: order)

        // When/Then
        XCTAssertThrowsError(try ApplePayRequestBuilder.build()) { error in
            guard let primerError = error as? PrimerError else {
                XCTFail("Expected PrimerError")
                return
            }
            if case let .invalidClientSessionValue(name, _, _, _) = primerError {
                XCTAssertEqual(name, "order.countryCode")
            } else {
                XCTFail("Expected invalidClientSessionValue error, got \(primerError)")
            }
        }
    }

    func test_build_failure_whenMerchantIdentifierMissing_throwsError() {
        // Given - Valid order but no applePayOptions
        SDKSessionHelper.setUp(
            withPaymentMethods: [ApplePayTestData.applePayPaymentMethod],
            order: ApplePayTestData.defaultOrder
        )
        // Register settings without apple pay options
        let settings = PrimerSettings()
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        // When/Then
        XCTAssertThrowsError(try ApplePayRequestBuilder.build()) { error in
            guard let primerError = error as? PrimerError else {
                XCTFail("Expected PrimerError")
                return
            }
            if case .invalidMerchantIdentifier = primerError {
                // Expected
            } else {
                XCTFail("Expected invalidMerchantIdentifier error, got \(primerError)")
            }
        }
    }

    func test_build_failure_whenNoOrderAmounts_throwsError() {
        // Given - Order without merchantAmount or lineItems
        let order = ClientSession.Order(
            id: "order_id",
            merchantAmount: nil,
            totalOrderAmount: nil,
            totalTaxAmount: nil,
            countryCode: .gb,
            currencyCode: Currency(code: "GBP", decimalDigits: 2),
            fees: nil,
            lineItems: nil,
            shippingMethod: nil
        )
        setupConfiguration(withOrder: order)

        // When/Then
        XCTAssertThrowsError(try ApplePayRequestBuilder.build()) { error in
            guard let primerError = error as? PrimerError else {
                XCTFail("Expected PrimerError")
                return
            }
            if case let .invalidValue(key, _, _, _) = primerError {
                XCTAssertTrue(key.contains("lineItems") || key.contains("merchantAmount"))
            } else {
                XCTFail("Expected invalidValue error, got \(primerError)")
            }
        }
    }

    // MARK: - Order Item Construction Edge Cases

    func test_build_withBothMerchantAmountAndLineItems_prefersMerchantAmount() throws {
        // Given - Order with both merchantAmount AND lineItems
        let lineItem = ClientSession.Order.LineItem(
            itemId: "item_1",
            quantity: 1,
            amount: 500,
            discountAmount: nil,
            name: "Line Item",
            description: nil,
            taxAmount: nil,
            taxCode: nil,
            productType: nil
        )
        let order = ClientSession.Order(
            id: "order_id",
            merchantAmount: 1000, // This should take precedence
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .gb,
            currencyCode: Currency(code: "GBP", decimalDigits: 2),
            fees: nil,
            lineItems: [lineItem],
            shippingMethod: nil
        )
        setupConfiguration(withOrder: order)

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then - should only have summary item (merchantAmount path), not line items
        XCTAssertEqual(request.items.count, 1)
        XCTAssertEqual(request.items.first?.name, ApplePayTestData.Constants.merchantName)
    }

    func test_build_withEmptyLineItems_andNoMerchantAmount_throwsError() {
        // Given - Order with empty lineItems and no merchantAmount
        let order = ClientSession.Order(
            id: "order_id",
            merchantAmount: nil,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .gb,
            currencyCode: Currency(code: "GBP", decimalDigits: 2),
            fees: nil,
            lineItems: [], // Empty array
            shippingMethod: nil
        )
        setupConfiguration(withOrder: order)

        // When/Then
        XCTAssertThrowsError(try ApplePayRequestBuilder.build())
    }

    func test_build_withLineItemWithDiscount_calculatesCorrectAmount() throws {
        // Given - Line item with discount
        let lineItem = ClientSession.Order.LineItem(
            itemId: "item_1",
            quantity: 2,
            amount: 500,
            discountAmount: 100, // Discount applied
            name: "Discounted Item",
            description: nil,
            taxAmount: nil,
            taxCode: nil,
            productType: nil
        )
        let order = ClientSession.Order(
            id: "order_id",
            merchantAmount: nil,
            totalOrderAmount: 900,
            totalTaxAmount: nil,
            countryCode: .gb,
            currencyCode: Currency(code: "GBP", decimalDigits: 2),
            fees: nil,
            lineItems: [lineItem],
            shippingMethod: nil
        )
        setupConfiguration(withOrder: order)

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then
        XCTAssertFalse(request.items.isEmpty)
    }

    func test_build_withMultipleLineItems_createsAllItems() throws {
        // Given - Multiple line items
        let lineItem1 = ClientSession.Order.LineItem(
            itemId: "item_1",
            quantity: 1,
            amount: 500,
            discountAmount: nil,
            name: "Item 1",
            description: nil,
            taxAmount: nil,
            taxCode: nil,
            productType: nil
        )
        let lineItem2 = ClientSession.Order.LineItem(
            itemId: "item_2",
            quantity: 2,
            amount: 300,
            discountAmount: nil,
            name: "Item 2",
            description: nil,
            taxAmount: nil,
            taxCode: nil,
            productType: nil
        )
        let order = ClientSession.Order(
            id: "order_id",
            merchantAmount: nil,
            totalOrderAmount: 1100,
            totalTaxAmount: nil,
            countryCode: .gb,
            currencyCode: Currency(code: "GBP", decimalDigits: 2),
            fees: nil,
            lineItems: [lineItem1, lineItem2],
            shippingMethod: nil
        )
        setupConfiguration(withOrder: order)

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then - should have 2 line items + 1 summary item = 3 items
        XCTAssertEqual(request.items.count, 3)
    }

    // MARK: - Shipping Edge Cases

    func test_build_withShippingModule_emptySelectedMethod_handlesGracefully() throws {
        // Given - Shipping module with empty selected method (no valid selection)
        let shippingMethod = Response.Body.Configuration.CheckoutModule.ShippingMethodOptions.ShippingMethod(
            name: "Standard Shipping",
            description: "Delivered in 3-5 business days",
            amount: 500,
            id: "shipping_standard"
        )
        let shippingOptions = Response.Body.Configuration.CheckoutModule.ShippingMethodOptions(
            shippingMethods: [shippingMethod],
            selectedShippingMethod: "" // Empty selection
        )
        let shippingModule = PrimerAPIConfiguration.CheckoutModule(
            type: "SHIPPING",
            requestUrlStr: nil,
            options: shippingOptions
        )

        SDKSessionHelper.setUp(
            withPaymentMethods: [ApplePayTestData.applePayPaymentMethod],
            order: ApplePayTestData.defaultOrder,
            checkoutModules: [shippingModule]
        )
        registerApplePaySettings()

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then - shipping methods should still be available
        XCTAssertNotNil(request.shippingMethods)
    }

    func test_build_withZeroAmountShipping_includesZeroShipping() throws {
        // Given - Free shipping
        let shippingMethod = Response.Body.Configuration.CheckoutModule.ShippingMethodOptions.ShippingMethod(
            name: "Free Shipping",
            description: "Free delivery",
            amount: 0,
            id: "shipping_free"
        )
        let shippingOptions = Response.Body.Configuration.CheckoutModule.ShippingMethodOptions(
            shippingMethods: [shippingMethod],
            selectedShippingMethod: "shipping_free"
        )
        let shippingModule = PrimerAPIConfiguration.CheckoutModule(
            type: "SHIPPING",
            requestUrlStr: nil,
            options: shippingOptions
        )

        SDKSessionHelper.setUp(
            withPaymentMethods: [ApplePayTestData.applePayPaymentMethod],
            order: ApplePayTestData.defaultOrder,
            checkoutModules: [shippingModule]
        )
        registerApplePaySettings()

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then
        XCTAssertNotNil(request.shippingMethods)
        XCTAssertEqual(request.shippingMethods?.first?.label, "Free Shipping")
    }

    // MARK: - Currency Edge Cases

    func test_build_withDifferentCurrencies_handlesCorrectly() throws {
        // Given - EUR currency
        let order = ClientSession.Order(
            id: "order_id",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .de,
            currencyCode: Currency(code: "EUR", decimalDigits: 2),
            fees: nil,
            lineItems: nil,
            shippingMethod: nil
        )

        SDKSessionHelper.setUp(
            withPaymentMethods: [ApplePayTestData.applePayPaymentMethod],
            order: order,
            configureAppState: { mockAppState in
                mockAppState.currency = Currency(code: "EUR", decimalDigits: 2)
            }
        )
        registerApplePaySettings()

        // When
        let request = try ApplePayRequestBuilder.build()

        // Then
        XCTAssertEqual(request.currency.code, "EUR")
        XCTAssertEqual(request.countryCode.rawValue, "DE")
    }

    // MARK: - Helpers

    private func registerApplePaySettings() {
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: ApplePayTestData.Constants.merchantIdentifier,
                    merchantName: ApplePayTestData.Constants.merchantName
                )
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    // MARK: - Original Helpers

    private func setupValidConfiguration() {
        setupConfiguration(withOrder: ApplePayTestData.defaultOrder)
    }

    private func setupConfiguration(withOrder order: ClientSession.Order) {
        SDKSessionHelper.setUp(
            withPaymentMethods: [ApplePayTestData.applePayPaymentMethod],
            order: order
        )
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: ApplePayTestData.Constants.merchantIdentifier,
                    merchantName: ApplePayTestData.Constants.merchantName
                )
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    private func setupConfigurationWithShipping(withOrder order: ClientSession.Order) {
        SDKSessionHelper.setUp(
            withPaymentMethods: [ApplePayTestData.applePayPaymentMethod],
            order: order,
            checkoutModules: [ApplePayTestData.shippingCheckoutModule]
        )
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: ApplePayTestData.Constants.merchantIdentifier,
                    merchantName: ApplePayTestData.Constants.merchantName
                )
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    private func setupConfigurationWithZeroDecimalCurrency(withOrder order: ClientSession.Order) {
        SDKSessionHelper.setUp(
            withPaymentMethods: [ApplePayTestData.applePayPaymentMethod],
            order: order,
            checkoutModules: [ApplePayTestData.shippingCheckoutModule],
            configureAppState: { mockAppState in
                mockAppState.currency = Currency(code: "JPY", decimalDigits: 0)
            }
        )
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: ApplePayTestData.Constants.merchantIdentifier,
                    merchantName: ApplePayTestData.Constants.merchantName
                )
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }
}
