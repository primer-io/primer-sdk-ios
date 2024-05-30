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
    static var inexistentPaymentMethod = "inexistent"
    static var klarnaPaymentMethodType = "KLARNA"

    static let invalidTokenError = PrimerError.invalidClientToken(
        userInfo: [:],
        diagnosticsId: UUID().uuidString
    )
    
    static var stripeACHToken: String {
        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjE2NjQ5NTM1OTkwLCJhY2Nlc3NUb2tlbiI6ImIwY2E0NTFhLTBmYmItNGZlYS1hY2UwLTgxMDYwNGQ4OTBkYSIsImFuYWx5dGljc1VybCI6Imh0dHBzOi8vYW5hbHl0aWNzLmFwaS5zYW5kYm94LmNvcmUucHJpbWVyLmlvL21peHBhbmVsIiwiYW5hbHl0aWNzVXJsVjIiOiJodHRwczovL2FuYWx5dGljcy5zYW5kYm94LmRhdGEucHJpbWVyLmlvL2NoZWNrb3V0L3RyYWNrIiwiaW50ZW50IjoiU1RSSVBFX0FDSCIsImNsaWVudFNlY3JldCI6ImNsaWVudC1zZWNyZXQtdGVzdCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwic3RhdHVzVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8vcmVzdW1lLXRva2Vucy9lOTM3ZDQyMS0zYzE2LTRjMmUtYTBjOC01OGQxY2RhNWM0NmUiLCJyZWRpcmVjdFVybCI6Imh0dHBzOi8vdGVzdC5hZHllbi5jb20vaHBwL2NoZWNrb3V0LnNodG1sP3U9c2tpcERldGFpbHMmcD1lSnlOVTl0eW16QVEtUnJ6QmdQaVluamd3UVdTdUUwY2g5aE9waThlV2F4dDFTQXhrbkROMzJjaGwyblR6clF6ekk3WWN5U2RQYnVpYlZ0elJnMlhZaTcyMG9HTEFTVm92YXlwMlV2VnpJV0JnNkpHcW5TcGVBUEtvdi1Zc2FBTi1DOTNBMG9qbGhKcnA2aW9NbGxCZXVCS3RyUzNXS2NVQ05hUHlXSmRXbmdnTzFKaFpvekpUcGkzTzc3dVZxQk5rZDNmZlJEZU5lUEpqdWxiU0xPYkl2dDJ2MTV0cjR0RlVjNnp2ekxQYjFxaTZRZGN3aDRHRFpCeXFiZFNWYUMydk5xRzljLTc5bGJ0ZnVHWlRvbWNHcHBtRCpGeUdUd0gqVk5PbmhZeCplQTg4a042TFNET29KSDVobmpWNWZRZ3dwc3YtV0puaXRYc0txZzhsWWlZcTRmbkpTSHJpWjliNkVJRFdHOHpsdXZGcnFWZ2NJV0xReWFGVVpTWnRDeXlkVm5PRjllSXRVQ05MWVZ0MEJmWm1YUlBhdzJZMSp2eU5qMGEwKnFKUDV1UUstellFZGdKT2ZvbzJ4YVViZEJEaDFZOUNJZko1azhDWmpTb00yZWdjYmw4RlRZWHlFVXhKVlFjbFJsRXpoNkdXakpzOFN2bkRzeFJWaFAtNmxQM3NMN1AtWnVRU0kxR29seUVYd1dUY0pBY0RxSXgwSlk3R2dkbEp5OU9PMjUzdUJ3UnJMSnJ3RGJ5QkVLUEdVajhhUlVRei1hWkY5a0JJMkJUbDhWMkdGY2VxMmpJZ2doR0loYlIxbUNHSDMqNFlYdUNmbGpueVg0S1BtR0pIZTg4WmdmVXhWVTFCWnZSTVBKZFZzVlRCcFlHUFl6Tmh0YTg0cVpQaVV1STdibTJHNnpjR1AxMkl3eCo4dDE2YzNJWXVhRnp3NmdWZVBYZ0M3eUR2dzJjelRwdEpPSzJtblcxS2ZYUjBpY3V4dmZRZGp2blRKeVllSkVmVENNdkNYMHZJYjZUZTlxZkMqa2EqWGh3Tnp5QTQ5YmRlLVVxbi1QTE9lSWJNZTEtblBmSldwcmlCY3BiWlBRIn0.-dAIRiCWqBGjy330LU_jqDMqV1RK_q-5X4iaye1Mec0"
    }

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
                    productType: nil)
            ],
                shippingAmount: nil),
            customer: getClientSessionCustomer(firstName: firstName, lastName: lastName, email: email),
            testId: nil)
    }
    
    static func getEmptyClientSession(
        emptyMerchantAmmount: Bool,
        emptyTotalOrderAmmount: Bool,
        emptyLineItems: Bool,
        emptyOrderAmount: Bool,
        emptyCurrencyCode: Bool
    ) -> ClientSession.APIResponse {
        return ClientSession.APIResponse(
            clientSessionId: "mock-client-session-stripe-ach_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: nil),
            order: ClientSession.Order(
                id: "mock-client-session-order-stripe-ach_id",
                merchantAmount: emptyMerchantAmmount ? nil: 1000,
                totalOrderAmount: emptyTotalOrderAmmount ? nil : 1000,
                totalTaxAmount: nil,
                countryCode: .us,
                currencyCode: emptyCurrencyCode ? nil : CurrencyLoader().getCurrency("USD"),
                fees: nil,
                lineItems: emptyLineItems ? nil : [getLineItem(hasAmount: !emptyOrderAmount)],
                shippingAmount: nil),
            customer: getClientSessionCustomer(firstName: "firstname", lastName: "lastname", email: "email"),
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
            extraMerchantData: nil),
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
    
    static func getInvalidPaymentMethod() -> PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: "invalid-id",
            implementationType: .nativeSdk,
            type: "INVALID_PM",
            name: "INVALID",
            processorConfigId: "invalid-processor-config-id",
            surcharge: nil,
            options: nil,
            displayMetadata: nil)
    }
    
    static func getPayment(id: String, status: Response.Body.Payment.Status) -> Response.Body.Payment {
        Response.Body.Payment(
            id: id,
            paymentId: "mock_payment_id",
            amount: 1000,
            currencyCode: "USD",
            customer: nil,
            customerId: "mock_customer_id",
            dateStr: nil,
            order: nil,
            orderId: nil,
            requiredAction: nil,
            status: status,
            paymentFailureReason: nil)
    }
}
