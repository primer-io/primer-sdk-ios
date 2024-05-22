//
//  ACHMocks.swift
//
//
//  Created by Stefan Vrancianu on 16.05.2024.
//

import Foundation
import XCTest
@testable import PrimerSDK

class ACHMocks {
    static var stripeACHPaymentMethodId = "STRIPE_ACH"
    static var stripeACHPaymentMethodName = "Mock StripeACH Payment Method"
    static var stripeACHPaymentMethodType = "STRIPE_ACH"
    static var processorConfigId = "mock_processor_config_id"

    static let invalidTokenError = PrimerError.invalidClientToken(
        userInfo: [:],
        diagnosticsId: UUID().uuidString
    )

    static func getClientSession(
        firstName: String = "",
        lastName: String = "",
        email: String = ""
    ) -> ClientSession.APIResponse {
        return ClientSession.APIResponse(
            clientSessionId: "mock-client-session-stripe-ach_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: nil),
            order: ClientSession.Order(
                id: "mock-client-session-order-stripe-ach_id",
                merchantAmount: nil,
                totalOrderAmount: 100,
                totalTaxAmount: nil,
                countryCode: .de,
                currencyCode: CurrencyLoader().getCurrency("EUR"),
                fees: nil,
                lineItems: nil,
                shippingAmount: nil),
            customer: getClientSessionCustomer(firstName: firstName, lastName: lastName, email: email),
            testId: nil)
    }

    static func getLineItem(hasAmount: Bool) -> ClientSession.Order.LineItem {
        return ClientSession.Order.LineItem(
            itemId: "mock-item-id-1",
            quantity: 1,
            amount: hasAmount ? 100 : nil,
            discountAmount: nil,
            name: "mock-name-1",
            description: "mock-description-1",
            taxAmount: nil,
            taxCode: nil,
            productType: nil)
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
        vaultData: nil)
    
    static let stripeACHPaymentMethod = PrimerPaymentMethod(
        id: stripeACHPaymentMethodId,
        implementationType: .nativeSdk,
        type: stripeACHPaymentMethodType,
        name: stripeACHPaymentMethodName,
        processorConfigId: processorConfigId,
        surcharge: 299,
        options: nil,
        displayMetadata: nil)
    
    static func getClientSessionCustomer(firstName: String, lastName: String, email: String) -> ClientSession.Customer {
        return ClientSession.Customer(
            id: "ach-client-id",
            firstName: firstName,
            lastName: lastName,
            emailAddress: email,
            mobileNumber: "",
            billingAddress: nil,
            shippingAddress: nil)
    }
        
}
