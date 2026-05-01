//
//  ACHMocks.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class ACHMocks {
    static var stripeACHPaymentMethodId = "STRIPE_ACH"
    static var stripeACHPaymentMethodName = "Mock StripeACH Payment Method"
    static var stripeACHPaymentMethodType = "STRIPE_ACH"
    static var processorConfigId = "mock_processor_config_id"
    static var inexistentPaymentMethod = "inexistent"
    static var klarnaPaymentMethodType = "KLARNA"

    static let invalidTokenError = PrimerError.invalidClientToken()

    static var stripeACHToken: String {
        try! JWTFactory().create(payload: [
            "exp": 2000000000,
            "accessToken": "00000000-0000-0000-0000-000000000000",
            "analyticsUrl": "https://analytics.api.sandbox.core.primer.io/mixpanel",
            "analyticsUrlV2": "https://analytics.sandbox.data.primer.io/checkout/track",
            "intent": "STRIPE_ACH",
            "stripeClientSecret": "mock-stripe-client-secret",
            "configurationUrl": "https://api.sandbox.primer.io/client-sdk/configuration",
            "coreUrl": "https://api.sandbox.primer.io",
            "pciUrl": "https://sdk.api.sandbox.primer.io",
            "env": "SANDBOX",
            "statusUrl": "https://localhost/resume-tokens/mock-resume-token-id",
            "redirectUrl": "https://localhost/redirect"
        ])
    }

    static func getClientSession(
        firstName: String = "",
        lastName: String = "",
        email: String = ""
    ) -> ClientSession.APIResponse {
        ClientSession.APIResponse(
            clientSessionId: "mock-client-session-stripe-ach_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: ClientSession.Order(
                id: "mock-client-session-order-stripe-ach_id",
                merchantAmount: 1050,
                totalOrderAmount: 1000,
                totalTaxAmount: 50,
                countryCode: .us,
                currencyCode: CurrencyLoader().getCurrency("USD"),
                fees: nil,
                lineItems: [ClientSession.Order.LineItem(
                    itemId: "mock-item-id-1",
                    quantity: 1,
                    amount: 1000,
                    discountAmount: nil,
                    name: "mock-name-1",
                    description: "mock-description-1",
                    taxAmount: 50,
                    taxCode: nil,
                    productType: nil
                )]
            ),
            customer: getClientSessionCustomer(firstName: firstName, lastName: lastName, email: email),
            testId: nil
        )
    }

    static func getEmptyClientSession(
        emptyMerchantAmmount: Bool,
        emptyTotalOrderAmmount: Bool,
        emptyLineItems: Bool,
        emptyOrderAmount: Bool,
        emptyCurrencyCode: Bool
    ) -> ClientSession.APIResponse {
        ClientSession.APIResponse(
            clientSessionId: "mock-client-session-stripe-ach_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: ClientSession.Order(
                id: "mock-client-session-order-stripe-ach_id",
                merchantAmount: emptyMerchantAmmount ? nil: 1000,
                totalOrderAmount: emptyTotalOrderAmmount ? nil : 1000,
                totalTaxAmount: nil,
                countryCode: .us,
                currencyCode: emptyCurrencyCode ? nil : CurrencyLoader().getCurrency("USD"),
                fees: nil,
                lineItems: emptyLineItems ? nil : [getLineItem(hasAmount: !emptyOrderAmount)]
            ),
            customer: getClientSessionCustomer(firstName: "firstname", lastName: "lastname", email: "email"),
            testId: nil
        )
    }

    static func getLineItem(hasAmount: Bool) -> ClientSession.Order.LineItem {
        ClientSession.Order.LineItem(
            itemId: "mock-item-id-1",
            quantity: 1,
            amount: hasAmount ? 100 : nil,
            discountAmount: nil,
            name: "mock-name-1",
            description: "mock-description-1",
            taxAmount: nil,
            taxCode: nil,
            productType: nil
        )
    }

    static let primerPaymentMethodTokenData = PrimerPaymentMethodTokenData(
        analyticsId: "mock_analytics_id",
        id: "mock_payment_method_token_data_id",
        isVaulted: false,
        isAlreadyVaulted: false,
        paymentInstrumentType: .stripeAch,
        paymentMethodType: stripeACHPaymentMethodName,
        paymentInstrumentData: nil,
        threeDSecureAuthentication: nil,
        token: "mock_payment_method_token",
        tokenType: .singleUse,
        vaultData: nil
    )

    static let stripeACHPaymentMethod = PrimerPaymentMethod(
        id: stripeACHPaymentMethodId,
        implementationType: .nativeSdk,
        type: stripeACHPaymentMethodType,
        name: stripeACHPaymentMethodName,
        processorConfigId: processorConfigId,
        surcharge: 299,
        options: nil,
        displayMetadata: nil
    )

    static let klarnaPaymentMethod = PrimerPaymentMethod(
        id: "klarna-test",
        implementationType: .nativeSdk,
        type: "KLARNA",
        name: "Klarna",
        processorConfigId: "klarna-processor-config-id",
        surcharge: nil,
        options: MerchantOptions(
            merchantId: "merchant-id",
            merchantAccountId: "merchant-account-id",
            appId: "app-id",
            extraMerchantData: nil
        ),
        displayMetadata: nil
    )

    static func getClientSessionCustomer(firstName: String, lastName: String, email: String) -> ClientSession.Customer {
        ClientSession.Customer(
            id: "ach-client-id",
            firstName: firstName,
            lastName: lastName,
            emailAddress: email,
            mobileNumber: "",
            billingAddress: nil,
            shippingAddress: nil
        )
    }

    static func getInvalidPaymentMethod() -> PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: "invalid-id",
            implementationType: .nativeSdk,
            type: "INVALID_PM",
            name: "INVALID",
            processorConfigId: "invalid-processor-config-id",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
    }

    static func getPayment(id: String, status: Response.Body.Payment.Status) -> Response.Body.Payment {
        Response.Body.Payment(
            id: id,
            paymentId: "mock_payment_id",
            amount: 1000,
            currencyCode: "USD",
            customerId: "mock_customer_id",
            status: status
        )
    }
}
