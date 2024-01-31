//
//  HeadlessUniversalCheckoutTests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 20/4/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class HeadlessUniversalCheckoutTests: XCTestCase {
    
    func test_start_headless() throws {
        let exp = expectation(description: "Start Headless Universal Checkout")
        
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock-client-session-id-1",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: nil
            ),
            order: ClientSession.Order(
                id: "mock-client-session-order-id-1",
                merchantAmount: nil,
                totalOrderAmount: 100,
                totalTaxAmount: nil,
                countryCode: .gb,
                currencyCode: CurrencyLoader().getCurrency("GBP"),
                fees: nil,
                lineItems: [
                    ClientSession.Order.LineItem(
                        itemId: "mock-item-id-1",
                        quantity: 1,
                        amount: 100,
                        discountAmount: nil,
                        name: "mock-name-1",
                        description: "mock-description-1",
                        taxAmount: nil,
                        taxCode: nil)
                ],
                shippingAmount: nil),
            customer: nil,
            testId: nil)
        
        let mockPrimerApiConfiguration = Response.Body.Configuration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            binDataUrl: "https://primer.io/bindata",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: clientSession,
            paymentMethods: [
                PrimerPaymentMethod(
                    id: "mock-id-1",
                    implementationType: .webRedirect,
                    type: "ADYEN_GIROPAY",
                    name: "Giropay",
                    processorConfigId: "mock-processor-config-id-1",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil),
                PrimerPaymentMethod(
                    id: "mock-id-2",
                    implementationType: .webRedirect,
                    type: "ADYEN_DOTPAY",
                    name: "Payment Method Unavailable on Headless",
                    processorConfigId: "mock-processor-config-id-2",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil)
            ],
            primerAccountId: "mock-primer-account-id",
            keys: nil,
            checkoutModules: nil)
        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])
        
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        
        var availablePaymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]?
        
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken) { paymentMethods, _ in
            availablePaymentMethods = paymentMethods
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 30)
        
        let apiConfiguration = AppState.current.apiConfiguration
        
        XCTAssert((availablePaymentMethods?.count ?? 0) != 1, "Primer Headless Universal Checkout should return 1 available payment method")
        XCTAssert(availablePaymentMethods?.first?.paymentMethodType == "ADYEN_GIROPAY", "Primer Headless Universal Checkout should include Adyen Giropay in its available payment methods")
        XCTAssert(availablePaymentMethods?.first(where: { $0.paymentMethodType == "ADYEN_DOTPAY" }) != nil, "Primer Headless Universal Checkout should not include ADYEN_DOTPAY in its available payment methods")
        XCTAssert(apiConfiguration?.clientSession?.clientSessionId == clientSession.clientSessionId, "Primer configuration's client session's id should be \(clientSession.clientSessionId ?? "nil")")
        XCTAssert(apiConfiguration?.clientSession?.order != nil, "Primer configuration's client session's order should not be null")
        XCTAssert(apiConfiguration?.clientSession?.order?.currencyCode == clientSession.order?.currencyCode, "Primer configuration's client session's order currency should be \(clientSession.order?.currencyCode?.code ?? "nil")")
        XCTAssert(apiConfiguration?.clientSession?.order?.lineItems?.count == clientSession.order?.lineItems?.count, "Primer configuration's client session's order's line items should include \(clientSession.order?.lineItems?.count ?? 0) item(s)")
        XCTAssert(apiConfiguration?.clientSession?.customer == nil, "Primer configuration's client session's customer should be nil")
    }
    
    func test_patch_client_session_and_restart_headless_universal_checkout() throws {
        let exp = expectation(description: "Patch client session and  restart Headless Universal Checkout")
        
        try test_start_headless()
        
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock-client-session-id-2",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: nil
            ),
            order: ClientSession.Order(
                id: "mock-client-session-order-id-1",
                merchantAmount: nil,
                totalOrderAmount: 100,
                totalTaxAmount: nil,
                countryCode: .gb,
                currencyCode: CurrencyLoader().getCurrency("GBP"),
                fees: nil,
                lineItems: [
                    ClientSession.Order.LineItem(
                        itemId: "mock-item-id-1",
                        quantity: 1,
                        amount: 100,
                        discountAmount: nil,
                        name: "mock-name-1",
                        description: "mock-description-1",
                        taxAmount: nil,
                        taxCode: nil)
                ],
                shippingAmount: nil),
            customer: ClientSession.Customer(
                id: "mock-customer-id",
                firstName: "mock-first-name",
                lastName: "mock-last-name",
                emailAddress: "mock@email.com",
                mobileNumber: "12345678"
            ),
            testId: nil)
        
        let mockPrimerApiConfiguration = Response.Body.Configuration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            binDataUrl: "https://primer.io/bindata",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: clientSession,
            paymentMethods: [
                PrimerPaymentMethod(
                    id: "mock-id-1",
                    implementationType: .webRedirect,
                    type: "ADYEN_GIROPAY",
                    name: "Giropay",
                    processorConfigId: "mock-processor-config-id-1",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil),
                PrimerPaymentMethod(
                    id: "mock-id-2",
                    implementationType: .nativeSdk,
                    type: "ADYEN_DOTPAY",
                    name: "Payment Method Unavailable on Headless",
                    processorConfigId: "mock-processor-config-id-2",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil),
                PrimerPaymentMethod(
                    id: "mock-id-3",
                    implementationType: .nativeSdk,
                    type: "APPLE_PAY",
                    name: "Apple Pay",
                    processorConfigId: "mock-processor-config-id-3",
                    surcharge: nil,
                    options: nil,
                    displayMetadata: nil)
            ],
            primerAccountId: "mock-primer-account-id",
            keys: nil,
            checkoutModules: nil)
        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])
        
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        
        var availablePaymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]?
        
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken) { paymentMethods, _ in
            availablePaymentMethods = paymentMethods
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 30)
        
        let apiConfiguration = AppState.current.apiConfiguration
        
        XCTAssert((apiConfiguration?.paymentMethods?.count ?? 0) == mockPrimerApiConfiguration.paymentMethods?.count, "Primer configuration should include \(mockPrimerApiConfiguration.paymentMethods?.count ?? 0) payment methods")
        XCTAssert((availablePaymentMethods?.count ?? 0) == 2, "Primer Headless Universal Checkout should return 2 available payment method")
        XCTAssert(availablePaymentMethods?.first(where: { $0.paymentMethodType == "ADYEN_GIROPAY" }) != nil, "Primer Headless Universal Checkout should include Adyen Giropay in its available payment methods")
        XCTAssert(availablePaymentMethods?.first(where: { $0.paymentMethodType == "ADYEN_DOTPAY" }) == nil, "Primer Headless Universal Checkout should not include ADYEN_DOTPAY in its available payment methods")
        XCTAssert(availablePaymentMethods?.first(where: { $0.paymentMethodType == "APPLE_PAY" }) != nil, "Primer Headless Universal Checkout should include APPLE_PAY in its available payment methods")
        XCTAssert(apiConfiguration?.clientSession?.clientSessionId == clientSession.clientSessionId, "Primer configuration's client session's id should be \(clientSession.clientSessionId ?? "nil")")
        XCTAssert(apiConfiguration?.clientSession?.order != nil, "Primer configuration's client session's order should not be null")
        XCTAssert(apiConfiguration?.clientSession?.customer != nil, "Primer configuration's client session's customer should be null")
    }
}
