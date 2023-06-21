//
//  HeadlessVaultManagerTests.swift
//  Debug App Tests
//
//  Created by Boris on 21.6.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class HeadlessVaultManagerTests: XCTestCase {
    
    func test_start_headless_vaulted() throws {
        let exp = expectation(description: "Start Headless Universal Checkout")
        
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock-client-session-id-1",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil),
            order: ClientSession.Order(
                id: "mock-client-session-order-id-1",
                merchantAmount: nil,
                totalOrderAmount: 100,
                totalTaxAmount: nil,
                countryCode: .gb,
                currencyCode: .GBP,
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
            customer: ClientSession.Customer(id: "testid"),
            testId: nil)
                
        let mockPrimerApiConfiguration = Response.Body.Configuration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
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
        
        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [
            PrimerPaymentMethodTokenData(analyticsId: "test",
                                         id: "test",
                                         isVaulted: true,
                                         isAlreadyVaulted: true,
                                         paymentInstrumentType: .payPalBillingAgreement,
                                         paymentMethodType: "PAYPAL",
                                         paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData(paypalBillingAgreementId: "",
                                                                                                                 first6Digits: nil,
                                                                                                                 last4Digits: nil,
                                                                                                                 expirationMonth: nil,
                                                                                                                 expirationYear: nil,
                                                                                                                 cardholderName: nil,
                                                                                                                 network: nil,
                                                                                                                 isNetworkTokenized: nil,
                                                                                                                 klarnaCustomerToken: nil,
                                                                                                                 sessionData: nil,
                                                                                                                 externalPayerInfo: nil,
                                                                                                                 shippingAddress: nil,
                                                                                                                 binData: nil,
                                                                                                                 threeDSecureAuthentication: nil,
                                                                                                                 gocardlessMandateId: nil,
                                                                                                                 authorizationToken: nil,
                                                                                                                 hashedIdentifier: nil,
                                                                                                                 mnc: nil,
                                                                                                                 mcc: nil,
                                                                                                                 mx: nil,
                                                                                                                 currencyCode: nil,
                                                                                                                 productId: nil,
                                                                                                                 paymentMethodConfigId: nil,
                                                                                                                 paymentMethodType: nil,
                                                                                                                 sessionInfo: nil),
                                         threeDSecureAuthentication: nil,
                                         token: "anything",
                                         tokenType: .multiUse,
                                         vaultData: nil)
        ])
        var avaliableVaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken) { pm, err in
            let vaultManager = PrimerHeadlessUniversalCheckout.VaultManager()
            try! vaultManager.configure()
            vaultManager.fetchVaultedPaymentMethods { vpm, err in
                let testAppState = AppState.current.paymentMethods
                print(testAppState)
                if let unwrappedVaultedPaymentMethods = vpm {
                    avaliableVaultedPaymentMethods = unwrappedVaultedPaymentMethods
                    exp.fulfill()
                }
            }

        }
        
        wait(for: [exp], timeout: 30)
        
        let apiConfiguration = AppState.current.apiConfiguration
        
        XCTAssert(avaliableVaultedPaymentMethods.count == 1, "Primer Headless Vaulted Manager should return 1 available payment method")
        XCTAssert(avaliableVaultedPaymentMethods.first?.paymentMethodType == "PAYPAL", "Primer Headless Universal Checkout should include Adyen Giropay in its available payment methods")
        XCTAssert(avaliableVaultedPaymentMethods.first(where: { $0.paymentMethodType == "PAYPAL" }) != nil, "Primer Headless Universal Checkout should not include ADYEN_DOTPAY in its available payment methods")
        XCTAssert(apiConfiguration?.clientSession?.clientSessionId == clientSession.clientSessionId, "Primer configuration's client session's id should be \(clientSession.clientSessionId ?? "nil")")
        XCTAssert(apiConfiguration?.clientSession?.order != nil, "Primer configuration's client session's order should not be null")
        XCTAssert(apiConfiguration?.clientSession?.order?.currencyCode == clientSession.order?.currencyCode, "Primer configuration's client session's order currency should be \(clientSession.order?.currencyCode?.rawValue ?? "nil")")
        XCTAssert(apiConfiguration?.clientSession?.order?.lineItems?.count == clientSession.order?.lineItems?.count, "Primer configuration's client session's order's line items should include \(clientSession.order?.lineItems?.count ?? 0) item(s)")
        XCTAssert(apiConfiguration?.clientSession?.customer != nil, "Primer configuration's client session's customer should not be be nil")
    }
    
    func test_headless_vaulted_configuration_fail() throws {
        let exp = expectation(description: "Configuration of VaultManager should fail ")
        
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock-client-session-id-1",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil),
            order: ClientSession.Order(
                id: "mock-client-session-order-id-1",
                merchantAmount: nil,
                totalOrderAmount: 100,
                totalTaxAmount: nil,
                countryCode: .gb,
                currencyCode: .GBP,
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
            clientSession: clientSession,
            paymentMethods: [],
            primerAccountId: "mock-primer-account-id",
            keys: nil,
            checkoutModules: nil)
        
        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])
        
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken) { pm, err in
            let vaultManager = PrimerHeadlessUniversalCheckout.VaultManager()
            do {
                try vaultManager.configure()
            } catch {
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 30)

        let apiConfiguration = AppState.current.apiConfiguration
        XCTAssert(apiConfiguration?.clientSession?.customer?.id == nil, "Primer configuration's client session's customer should be be nil")
    }
}
