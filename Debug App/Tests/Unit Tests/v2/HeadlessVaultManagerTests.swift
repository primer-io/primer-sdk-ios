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
    
    func test_start_headless_vault_manager() throws {
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
            binDataUrl: "https://primer.io/bindata",
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
        var availableVaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken) { _, _ in
            let vaultManager = PrimerHeadlessUniversalCheckout.VaultManager()
            try! vaultManager.configure()
            vaultManager.fetchVaultedPaymentMethods { vpm, _ in
                if let unwrappedVaultedPaymentMethods = vpm {
                    availableVaultedPaymentMethods = unwrappedVaultedPaymentMethods
                }
                
                exp.fulfill()
            }

        }
        
        wait(for: [exp], timeout: 30)
        
        let apiConfiguration = AppState.current.apiConfiguration
        
        XCTAssert(availableVaultedPaymentMethods.count == 1, "Primer Headless Vaulted Manager should return 1 available payment method")
        XCTAssert(availableVaultedPaymentMethods.first?.paymentMethodType == "PAYPAL", "Primer Headless Universal Checkout should include Adyen Giropay in its available payment methods")
        XCTAssert(availableVaultedPaymentMethods.first(where: { $0.paymentMethodType == "PAYPAL" }) != nil, "Primer Headless Universal Checkout should not include ADYEN_DOTPAY in its available payment methods")
        XCTAssert(apiConfiguration?.clientSession?.clientSessionId == clientSession.clientSessionId, "Primer configuration's client session's id should be \(clientSession.clientSessionId ?? "nil")")
        XCTAssert(apiConfiguration?.clientSession?.order != nil, "Primer configuration's client session's order should not be null")
        XCTAssert(apiConfiguration?.clientSession?.order?.currencyCode == clientSession.order?.currencyCode, "Primer configuration's client session's order currency should be \(clientSession.order?.currencyCode?.rawValue ?? "nil")")
        XCTAssert(apiConfiguration?.clientSession?.order?.lineItems?.count == clientSession.order?.lineItems?.count, "Primer configuration's client session's order's line items should include \(clientSession.order?.lineItems?.count ?? 0) item(s)")
        XCTAssert(apiConfiguration?.clientSession?.customer != nil, "Primer configuration's client session's customer should not be be nil")
    }
    
    func test_headless_vaulted_configuration_fail() throws {
        let exp = expectation(description: "Configuration of VaultManager should fail")
        
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
            binDataUrl: "https://primer.io/bindata",
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
        
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken) { _, _ in
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
    
    func test_headless_delete_vaulted_payment_method() throws {
        let exp = expectation(description: "Delete vaulted payment method")
        
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
            binDataUrl: "https://primer.io/bindata",
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
        
        var mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        mockApiClient.deleteVaultedPaymentMethodResult = ((), nil)
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken) { _, err in
            let vaultManager = PrimerHeadlessUniversalCheckout.VaultManager()
            try! vaultManager.configure()
            vaultManager.fetchVaultedPaymentMethods { vaultedPaymentMethods, err in
                if let err = err {
                    XCTAssert(true, "Failed with error \(err.localizedDescription)")
                    
                } else if let vaultedPaymentMethods = vaultedPaymentMethods {
                    if let testVaultedPaymentMethod = vaultedPaymentMethods.first(where: { $0.id == "test" }) {
                        mockApiClient = MockPrimerAPIClient()
                        mockApiClient.deleteVaultedPaymentMethodResult = ((), nil)
                        VaultService.apiClient = mockApiClient
                        
                        vaultManager.deleteVaultedPaymentMethod(id: testVaultedPaymentMethod.id) { err in
                            if let err = err {
                                XCTAssert(true, "Failed to delete vaulted payment method with id 'test'")
                            } else {
                                mockApiClient = MockPrimerAPIClient()
                                mockApiClient.fetchVaultedPaymentMethodsResult = (Response.Body.VaultedPaymentMethods(data: []), nil)
                                VaultService.apiClient = mockApiClient
                                vaultManager.fetchVaultedPaymentMethods { updatedVaultedPaymentMethods, err in
                                    if let err = err {
                                        XCTAssert(true, "Failed with error \(err.localizedDescription)")
                                        
                                    } else if let updatedVaultedPaymentMethods = updatedVaultedPaymentMethods {
                                        XCTAssert(updatedVaultedPaymentMethods.isEmpty, "Failed to delete vaulted payment method")
                                        exp.fulfill()
                                    } else {
                                        XCTAssert(true, "Should have received vaulted payment methods or error")
                                    }
                                }
                            }
                        }
                        
                    } else {
                        XCTAssert(true, "Should have received vaulted payment method with id 'test'")
                    }
                } else {
                    XCTAssert(true, "Should have received vaulted payment methods or error")
                }
            }
        }
        
        wait(for: [exp], timeout: 30)
    }
    
    func test_validate_recaptured_cvv() throws {
        let vaultManager = PrimerHeadlessUniversalCheckout.VaultManager()
        vaultManager.vaultedPaymentMethods = [
            PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
                id: "id",
                paymentMethodType: "PAYMENT_CARD",
                paymentInstrumentType: .paymentCard,
                paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData(
                    paypalBillingAgreementId: nil,
                    first6Digits: "411111",
                    last4Digits: "1111",
                    expirationMonth: "03",
                    expirationYear: "2030",
                    cardholderName: "John Smith",
                    network: "Visa",
                    isNetworkTokenized: nil,
                    klarnaCustomerToken: nil,
                    sessionData: nil,
                    externalPayerInfo: nil,
                    shippingAddress: nil,
                    binData: BinData(network: "VISA"),
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
                analyticsId: "analytics-id")
        ]
        
        var errors = vaultManager.validateAdditionalDataSynchronously(
            vaultedPaymentMethodId: "id",
            vaultedPaymentMethodAdditionalData: PrimerVaultedCardAdditionalData(cvv: "123"))
        
        XCTAssert(errors == nil, "Should not have received errors for valid CVV")
        
        errors = vaultManager.validateAdditionalDataSynchronously(
            vaultedPaymentMethodId: "id",
            vaultedPaymentMethodAdditionalData: PrimerVaultedCardAdditionalData(cvv: ""))
        
        XCTAssert(errors?.count == 1, "Should have received only one error")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorId == "invalid-cvv", "Should have received error with id [invalid-cvv] but received error id [\((errors?.first as? PrimerValidationError)?.errorId ?? "n/a")]")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorDescription == "[invalid-cvv] CVV cannot be blank.", "Should have received error with description \"[invalid-cvv] CVV cannot be blank.\" but received error with description \"\((errors?.first as? PrimerValidationError)?.errorDescription ?? "n/a")\"")
        
        errors = vaultManager.validateAdditionalDataSynchronously(
            vaultedPaymentMethodId: "id",
            vaultedPaymentMethodAdditionalData: PrimerVaultedCardAdditionalData(cvv: "12"))
        
        XCTAssert(errors?.count == 1, "Should have received only one error")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorId == "invalid-cvv", "Should have received error with id [invalid-cvv] but received error id [\((errors?.first as? PrimerValidationError)?.errorId ?? "n/a")]")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorDescription == "[invalid-cvv] CVV is not valid.", "Should have received error with description \"[invalid-cvv] CVV is not valid.\" but received error with description \"\((errors?.first as? PrimerValidationError)?.errorDescription ?? "n/a")\"")
        
        errors = vaultManager.validateAdditionalDataSynchronously(
            vaultedPaymentMethodId: "id",
            vaultedPaymentMethodAdditionalData: PrimerVaultedCardAdditionalData(cvv: "12345"))
        
        XCTAssert(errors?.count == 1, "Should have received only one error")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorId == "invalid-cvv", "Should have received error with id [invalid-cvv] but received error id [\((errors?.first as? PrimerValidationError)?.errorId ?? "n/a")]")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorDescription == "[invalid-cvv] CVV is not valid.", "Should have received error with description \"[invalid-cvv] CVV is not valid.\" but received error with description \"\((errors?.first as? PrimerValidationError)?.errorDescription ?? "n/a")\"")
        
        errors = vaultManager.validateAdditionalDataSynchronously(
            vaultedPaymentMethodId: "id",
            vaultedPaymentMethodAdditionalData: PrimerVaultedCardAdditionalData(cvv: "12a"))
        
        XCTAssert(errors?.count == 1, "Should have received only one error")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorId == "invalid-cvv", "Should have received error with id [invalid-cvv] but received error id [\((errors?.first as? PrimerValidationError)?.errorId ?? "n/a")]")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorDescription == "[invalid-cvv] CVV is not valid.", "Should have received error with description \"[invalid-cvv] CVV is not valid.\" but received error with description \"\((errors?.first as? PrimerValidationError)?.errorDescription ?? "n/a")\"")
        
        errors = vaultManager.validateAdditionalDataSynchronously(
            vaultedPaymentMethodId: "id",
            vaultedPaymentMethodAdditionalData: PrimerVaultedCardAdditionalData(cvv: "abc"))
        
        XCTAssert(errors?.count == 1, "Should have received only one error")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorId == "invalid-cvv", "Should have received error with id [invalid-cvv] but received error id [\((errors?.first as? PrimerValidationError)?.errorId ?? "n/a")]")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorDescription == "[invalid-cvv] CVV is not valid.", "Should have received error with description \"[invalid-cvv] CVV is not valid.\" but received error with description \"\((errors?.first as? PrimerValidationError)?.errorDescription ?? "n/a")\"")
        
        vaultManager.vaultedPaymentMethods = [
            PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
                id: "id",
                paymentMethodType: "PAYMENT_CARD",
                paymentInstrumentType: .paymentCard,
                paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData(
                    paypalBillingAgreementId: nil,
                    first6Digits: "378282",
                    last4Digits: "0005",
                    expirationMonth: "03",
                    expirationYear: "2030",
                    cardholderName: "John Smith",
                    network: "Amex",
                    isNetworkTokenized: nil,
                    klarnaCustomerToken: nil,
                    sessionData: nil,
                    externalPayerInfo: nil,
                    shippingAddress: nil,
                    binData: BinData(network: "AMEX"),
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
                analyticsId: "analytics-id")
        ]
        
        errors = vaultManager.validateAdditionalDataSynchronously(
            vaultedPaymentMethodId: "id",
            vaultedPaymentMethodAdditionalData: PrimerVaultedCardAdditionalData(cvv: "123"))
        
        XCTAssert(errors?.count == 1, "Should have received only one error")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorId == "invalid-cvv", "Should have received error with id [invalid-cvv] but received error id [\((errors?.first as? PrimerValidationError)?.errorId ?? "n/a")]")
        XCTAssert((errors?.first as? PrimerValidationError)?.errorDescription == "[invalid-cvv] CVV is not valid.", "Should have received error with description \"[invalid-cvv] CVV is not valid.\" but received error with description \"\((errors?.first as? PrimerValidationError)?.errorDescription ?? "n/a")\"")
        
        vaultManager.vaultedPaymentMethods = [
            PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
                id: "id",
                paymentMethodType: "PAYPAL",
                paymentInstrumentType: .payPalBillingAgreement,
                paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData(
                    paypalBillingAgreementId: "billing-agreement",
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
                analyticsId: "analytics-id")
        ]
        
        errors = vaultManager.validateAdditionalDataSynchronously(
            vaultedPaymentMethodId: "id",
            vaultedPaymentMethodAdditionalData: PrimerVaultedCardAdditionalData(cvv: "123"))
        
        XCTAssert(errors == nil, "Should not have received errors for payment methods that don't use additional data")
    }
}
