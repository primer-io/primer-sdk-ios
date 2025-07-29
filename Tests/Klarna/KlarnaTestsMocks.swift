//
//  KlarnaTestsMocks.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK
import PrimerKlarnaSDK

class KlarnaTestsMocks {
    static let sessionType: KlarnaSessionType = .oneOffPayment
    static let clientToken: String = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjIwMDAwMDAwMDAsImFjY2Vzc1Rva2VuIjoiYzJlOTM3YmMtYmUzOS00ZjVmLTkxYmYtNTIyNWExNDg0OTc1IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJhbmFseXRpY3NVcmxWMiI6Imh0dHBzOi8vYW5hbHl0aWNzLnNhbmRib3guZGF0YS5wcmltZXIuaW8vY2hlY2tvdXQvdHJhY2siLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwicGF5bWVudEZsb3ciOiJERUZBVUxUIn0.1Epm-502bLNhjhIQrmp4ZtrMQa0vQ2FjckPAlgJtuao"
    static let paymentMethod: String = "pay_now"
    static let klarnaCategoryResponse = Response.Body.Klarna.SessionCategory(identifier: "", name: "Pay now", descriptiveAssetUrl: "", standardAssetUrl: "")
    static let paymentCategory = KlarnaPaymentCategory(response: klarnaCategoryResponse)
    static let klarnaProvider: PrimerKlarnaProviding = PrimerKlarnaProvider(
        clientToken: clientToken,
        paymentCategory: paymentMethod
    )

    static let invalidTokenError = PrimerError.invalidClientToken(
        userInfo: [:],
        diagnosticsId: UUID().uuidString
    )

    static let primerPaymentMethodTokenData = PrimerPaymentMethodTokenData(
        analyticsId: "mock_analytics_id",
        id: "mock_payment_method_token_data_id",
        isVaulted: false,
        isAlreadyVaulted: false,
        paymentInstrumentType: .klarnaCustomerToken,
        paymentMethodType: "KLARNA",
        paymentInstrumentData: nil,
        threeDSecureAuthentication: nil,
        token: "mock_payment_method_token",
        tokenType: .singleUse,
        vaultData: nil)

    static var extraMerchantData: [String: Any] = [
        "subscription": [
            [
                "subscription_name": "Implant_lenses",
                "start_time": "2020-11-24T15:00",
                "end_time": "2021-11-24T15:00",
                "auto_renewal_of_subscription": false
            ]
        ],
        "customer_account_info": [
            [
                "unique_account_identifier": "Owen Owenson",
                "account_registration_date": "2020-11-24T15:00",
                "account_last_modified": "2020-11-24T15:00"
            ]
        ]
    ]

    static var klarnaOrder: ClientSession.Order {
        .init(id: "order_id",
              merchantAmount: 1234,
              totalOrderAmount: 1234,
              totalTaxAmount: nil,
              countryCode: .de,
              currencyCode: Currency(code: "EUR", decimalDigits: 2),
              fees: nil,
              lineItems: [
                .init(itemId: "item_id",
                      quantity: 1,
                      amount: 1234,
                      discountAmount: nil,
                      name: "my_item",
                      description: "item_description",
                      taxAmount: nil,
                      taxCode: nil,
                      productType: nil)
              ])
    }

    static func getClientSession(
        hasLineItemAmout: Bool = true,
        hasAmount: Bool = true,
        hasCurrency: Bool = true,
        hasItems: Bool = true
    ) -> ClientSession.APIResponse {
        return ClientSession.APIResponse(
            clientSessionId: "mock-client-session-id-1",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: ClientSession.Order(
                id: "mock-client-session-order-id-1",
                merchantAmount: nil,
                totalOrderAmount: hasAmount ? 100: nil,
                totalTaxAmount: nil,
                countryCode: .de,
                currencyCode: hasCurrency ? CurrencyLoader().getCurrency("EUR") : nil,
                fees: nil,
                lineItems: hasItems ? [getLineItem(hasAmount: hasLineItemAmout)] : nil),
            customer: nil,
            testId: nil
        )
    }

    static func getMockPrimerApiConfiguration(clientSession: ClientSession.APIResponse) -> Response.Body.Configuration {
        return Response.Body.Configuration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://primer.io/bindata",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: clientSession,
            paymentMethods: [
                PrimerPaymentMethod(
                    id: "klarna-test",
                    implementationType: .nativeSdk,
                    type: "KLARNA", name: "Klarna",
                    processorConfigId: "klarna-processor-config-id",
                    surcharge: nil,
                    options: MerchantOptions(
                        merchantId: "merchant-id",
                        merchantAccountId: "merchant-account-id",
                        appId: "app-id",
                        extraMerchantData: extraMerchantData),
                    displayMetadata: nil)
            ],
            primerAccountId: "mock-primer-account-id",
            keys: nil,
            checkoutModules: nil)
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

    static func getMockFinalizeKlarnaPaymentSession(isValid: Bool) -> Response.Body.Klarna.CustomerToken {
        return Response.Body.Klarna.CustomerToken(
            customerTokenId: isValid ? "mock-customer-token-id" : nil,
            sessionData: Response.Body.Klarna.SessionData(
                recurringDescription: "Mock recurring description",
                purchaseCountry: "DE",
                purchaseCurrency: "EUR",
                locale: "en-US",
                orderAmount: 100,
                orderTaxAmount: nil,
                orderLines: [
                    Response.Body.Klarna.SessionOrderLines(
                        type: "mock-type",
                        name: "mock-name",
                        quantity: 1,
                        unitPrice: 100,
                        totalAmount: 100,
                        totalDiscountAmount: 0)
                ],
                billingAddress: Response.Body.Klarna.BillingAddress(
                    addressLine1: "Mock address line 1",
                    addressLine2: "Mock address line 2",
                    addressLine3: "Mock address line 3",
                    city: "London",
                    countryCode: "GB",
                    email: "john@primer.io",
                    firstName: "John",
                    lastName: "Smith",
                    phoneNumber: "+447812345678",
                    postalCode: "PC123456",
                    state: "Greater London",
                    title: "Mock title"),
                shippingAddress: nil,
                tokenDetails: nil))
    }

    static var tokenizationResponseBody: Response.Body.Tokenization {
        .init(analyticsId: "analytics_id",
              id: "id",
              isVaulted: false,
              isAlreadyVaulted: false,
              paymentInstrumentType: .klarna,
              paymentMethodType: "KLARNA",
              paymentInstrumentData: nil,
              threeDSecureAuthentication: nil,
              token: "token",
              tokenType: .singleUse,
              vaultData: nil)
    }

    static var paymentResponseBody: Response.Body.Payment {
        return .init(id: "id",
                     paymentId: "payment_id",
                     amount: 123,
                     currencyCode: "EUR",
                     customer: .init(firstName: "first_name",
                                     lastName: "last_name",
                                     emailAddress: "email_address",
                                     mobileNumber: "+44(0)7891234567",
                                     billingAddress: .init(firstName: "billing_first_name",
                                                           lastName: "billing_last_name",
                                                           addressLine1: "billing_line_1",
                                                           addressLine2: "billing_line_2",
                                                           city: "billing_city",
                                                           state: "billing_state",
                                                           countryCode: "billing_country_code",
                                                           postalCode: "billing_postal_code"),
                                     shippingAddress: .init(firstName: "shipping_first_name",
                                                            lastName: "shipping_last_name",
                                                            addressLine1: "shipping_line_1",
                                                            addressLine2: "shipping_line_2",
                                                            city: "shipping_city",
                                                            state: "shipping_state",
                                                            countryCode: "shipping_country_code",
                                                            postalCode: "shipping_postal_code")),
                     customerId: "customer_id",
                     orderId: "order_id",
                     requiredAction: .init(clientToken: MockAppState.mockClientToken,
                                           name: .checkout,
                                           description: "description"),
                     status: .success)
    }
}

#endif
