//
//  KlarnaTestsMocks.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 28.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

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
                orderedAllowedCardNetworks: nil),
            order: ClientSession.Order(
                id: "mock-client-session-order-id-1",
                merchantAmount: nil,
                totalOrderAmount: hasAmount ? 100: nil,
                totalTaxAmount: nil,
                countryCode: .de,
                currencyCode: hasCurrency ? CurrencyLoader().getCurrency("EUR") : nil,
                fees: nil,
                lineItems: hasItems ? [getLineItem(hasAmount: hasLineItemAmout)] : nil,
                shippingAmount: nil),
            customer: nil,
            testId: nil)
    }
            
    static func getMockPrimerApiConfiguration(clientSession: ClientSession.APIResponse) -> Response.Body.Configuration {
        return Response.Body.Configuration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            binDataUrl: "https://bindata.url",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: clientSession,
            paymentMethods: [
                PrimerPaymentMethod(
                    id: "klarna-test",
                    implementationType: .nativeSdk,
                    type: "KLARNA", name: "Klarna",
                    processorConfigId: "klarna-processor-config-id",
                    surcharge: nil,
                    options: nil,
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
                purchaseCountry: "SE",
                purchaseCurrency: "SEK",
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
}

#endif
