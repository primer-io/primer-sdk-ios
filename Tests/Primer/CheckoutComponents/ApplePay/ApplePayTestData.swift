//
//  ApplePayTestData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
enum ApplePayTestData {

    // MARK: - Constants

    enum Constants {
        static let configId = "mock_apple_pay_config_id"
        static let merchantIdentifier = "merchant.test.primer"
        static let merchantName = "Test Merchant"
        static let paymentToken = "payment_token_123"
        static let paymentId = "payment_123"
    }

    // MARK: - Payment Method Configuration

    static var applePayPaymentMethod: PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: Constants.configId,
            implementationType: .nativeSdk,
            type: "APPLE_PAY",
            name: "Apple Pay",
            processorConfigId: "apple_pay_processor",
            surcharge: nil,
            options: ApplePayOptions(
                merchantName: Constants.merchantName,
                recurringPaymentRequest: nil,
                deferredPaymentRequest: nil,
                automaticReloadRequest: nil
            ),
            displayMetadata: nil
        )
    }

    // MARK: - Settings

    static var applePaySettings: PrimerSettings {
        PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "testapp://",
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: Constants.merchantIdentifier,
                    merchantName: Constants.merchantName
                )
            )
        )
    }

    // MARK: - Order

    static var defaultOrder: ClientSession.Order {
        ClientSession.Order(
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
    }

    static var orderWithLineItemsAndFees: ClientSession.Order {
        let lineItem = ClientSession.Order.LineItem(
            itemId: "item_1",
            quantity: 2,
            amount: 500,
            discountAmount: nil,
            name: "Test Item",
            description: "Test Item Description",
            taxAmount: 50,
            taxCode: nil,
            productType: nil
        )
        let fee = ClientSession.Order.Fee(
            type: .surcharge,
            amount: 100
        )
        return ClientSession.Order(
            id: "order_id",
            merchantAmount: nil,
            totalOrderAmount: 1150,
            totalTaxAmount: 50,
            countryCode: .gb,
            currencyCode: Currency(code: "GBP", decimalDigits: 2),
            fees: [fee],
            lineItems: [lineItem],
            shippingMethod: nil
        )
    }

    // MARK: - Checkout Modules

    static var shippingCheckoutModule: PrimerAPIConfiguration.CheckoutModule {
        let shippingMethod = Response.Body.Configuration.CheckoutModule.ShippingMethodOptions.ShippingMethod(
            name: "Standard Shipping",
            description: "Delivered in 3-5 business days",
            amount: 500,
            id: "shipping_standard"
        )
        let shippingOptions = Response.Body.Configuration.CheckoutModule.ShippingMethodOptions(
            shippingMethods: [shippingMethod],
            selectedShippingMethod: "shipping_standard"
        )
        return PrimerAPIConfiguration.CheckoutModule(
            type: "SHIPPING",
            requestUrlStr: nil,
            options: shippingOptions
        )
    }

    // MARK: - Response Bodies

    static var tokenizationResponse: Response.Body.Tokenization {
        Response.Body.Tokenization(
            analyticsId: "analytics_id",
            id: "token_id",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .applePay,
            paymentMethodType: "APPLE_PAY",
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: Constants.paymentToken,
            tokenType: .singleUse,
            vaultData: nil
        )
    }

    static func paymentResponse(status: Response.Body.Payment.Status = .success) -> Response.Body.Payment {
        Response.Body.Payment(
            id: Constants.paymentId,
            paymentId: Constants.paymentId,
            amount: 1000,
            currencyCode: "GBP",
            customer: nil,
            customerId: nil,
            dateStr: nil,
            order: nil,
            orderId: nil,
            requiredAction: nil,
            status: status,
            paymentFailureReason: nil,
            showSuccessCheckoutOnPendingPayment: nil,
            checkoutOutcome: nil
        )
    }
}
