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
    static let clientToken: String = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjE3MDcyMjQwNDYsImFjY2Vzc1Rva2VuIjoiMzAyYTNkNjItYjI2OS00NDZmLWE3OWQtYmJmY2YxNmNiYjAzIiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnN0YWdpbmcuY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJhbmFseXRpY3NVcmxWMiI6Imh0dHBzOi8vYW5hbHl0aWNzLnN0YWdpbmcuZGF0YS5wcmltZXIuaW8vY2hlY2tvdXQvdHJhY2siLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zdGFnaW5nLnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc3RhZ2luZy5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc3RhZ2luZy5wcmltZXIuaW8iLCJlbnYiOiJTVEFHSU5HIiwicGF5bWVudEZsb3ciOiJERUZBVUxUIn0.l-t8CYCHTGEC_6LcVCSutKOh80-fBtaoexkjaQoic8M"
    static let paymentMethod: String = "pay_now"
    static let klarnaProvider: PrimerKlarnaProviding = PrimerKlarnaProvider(
        clientToken: clientToken,
        paymentCategory: paymentMethod
    )
    static let klarnaAccountInfo = KlarnaCustomerAccountInfo(
        accountUniqueId: "test@gmail.com",
        accountRegistrationDate: "2022-04-25T14:05:15.953Z".toDate(),
        accountLastModified: "2023-04-25T14:05:15.953Z".toDate()
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
                options: nil),
            order: ClientSession.Order(
                id: "mock-client-session-order-id-1",
                merchantAmount: nil,
                totalOrderAmount: hasAmount ? 100: nil,
                totalTaxAmount: nil,
                countryCode: .de,
                currencyCode: hasCurrency ? .EUR : nil,
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
}

#endif
