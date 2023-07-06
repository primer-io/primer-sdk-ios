//
//  PrimerValidatorTests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 5/7/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PrimerValidatorTests: XCTestCase {
    
    /// Validators will collect data from various places, such as the configuration response,
    /// the client session, the SDK settings and the payment method's configuration and
    /// validate them.
    ///
    /// Therefore, we need to set a mock app state, and mock settings before each test.
    
    func test_apaya_validator() throws {
        var exp = expectation(description: "Await Apaya validator")
        var expectationsToBeFulfilled = [exp]
        
        let settings = PrimerSettings()
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
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
        
        var apaya = PrimerPaymentMethod(
            id: "apaya-id",
            implementationType: .nativeSdk,
            type: "APAYA",
            name: "Apaya",
            processorConfigId: "processor-config-id",
            surcharge: nil,
            options: MerchantOptions(
                merchantId: "merchant-id",
                merchantAccountId: "merchant-account-id"),
            displayMetadata: nil)
        
        var appState = MockAppState(
            clientToken: MockAppState.mockClientToken)
        appState.clientToken = MockAppState.mockClientToken
        appState.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            clientSession: clientSession,
            paymentMethods: [apaya],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)
        
        
        DependencyContainer.register(appState as AppStateProtocol)
        
        var orchestrator = PrimerPaymentMethodOrchestrator(paymentMethodConfig: apaya)
        var validator = PrimerApayaValidator(paymentMethodOrchestrator: orchestrator)
        
        try self.test_invalid_client_token(for: apaya, with: validator)
        try self.test_primer_configuration_validation(for: apaya, with: validator)
        try self.test_checkout_required_params_validation(for: apaya, with: validator)
        
        firstly {
            validator.validate()
        }
        .done {
            exp.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
            exp.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 3)
        
        exp = expectation(description: "Await Apaya validator")
        expectationsToBeFulfilled = [exp]
        
        apaya = PrimerPaymentMethod(
            id: "apaya-id",
            implementationType: .nativeSdk,
            type: "APAYA",
            name: "Apaya",
            processorConfigId: "processor-config-id",
            surcharge: nil,
            options: nil,
            displayMetadata: nil)
        
        appState = MockAppState(
            clientToken: MockAppState.mockClientToken)
        appState.clientToken = MockAppState.mockClientToken
        appState.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            clientSession: clientSession,
            paymentMethods: [apaya],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)
        
        DependencyContainer.register(appState as AppStateProtocol)
        
        orchestrator = PrimerPaymentMethodOrchestrator(paymentMethodConfig: apaya)
        validator = PrimerApayaValidator(paymentMethodOrchestrator: orchestrator)
        
        firstly {
            validator.validate()
        }
        .done {
            XCTAssert(false, "Validator should have failed with `invalidValue error for 'productId'")
            exp.fulfill()
        }
        .catch { err in
            exp.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 3)
        
        exp = expectation(description: "Await Apaya validator")
        expectationsToBeFulfilled = [exp]
        
        apaya = PrimerPaymentMethod(
            id: nil,
            implementationType: .nativeSdk,
            type: "APAYA",
            name: "Apaya",
            processorConfigId: "processor-config-id",
            surcharge: nil,
            options: MerchantOptions(
                merchantId: "merchant-id",
                merchantAccountId: "merchant-account-id"),
            displayMetadata: nil)
        
        appState = MockAppState(
            clientToken: MockAppState.mockClientToken)
        appState.clientToken = MockAppState.mockClientToken
        appState.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            clientSession: clientSession,
            paymentMethods: [apaya],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)
        
        DependencyContainer.register(appState as AppStateProtocol)
        
        orchestrator = PrimerPaymentMethodOrchestrator(paymentMethodConfig: apaya)
        validator = PrimerApayaValidator(paymentMethodOrchestrator: orchestrator)
        
        firstly {
            validator.validate()
        }
        .done {
            XCTAssert(false, "Validator should have failed with `invalidValue error for 'configuration.id'")
            exp.fulfill()
        }
        .catch { err in
            //            XCTAssert(false, err.localizedDescription)
            exp.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 3)
    }
    
    func test_apple_pay_validator() throws {
//        var exp = expectation(description: "Await Apple Pay validator")
//        var expectationsToBeFulfilled = [exp]
        
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: "merchant-id",
                    merchantName: "Merchant Name")))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        let applePay = PrimerPaymentMethod(
            id: "apple-pay-id",
            implementationType: .nativeSdk,
            type: "APPLE_PAY",
            name: "Apple Pay",
            processorConfigId: "processor-config-id",
            surcharge: nil,
            options: nil,
            displayMetadata: nil)
        
        let orchestrator = PrimerPaymentMethodOrchestrator(paymentMethodConfig: applePay)
        let validator = PrimerApplePayValidator(paymentMethodOrchestrator: orchestrator)
        
        try self.test_invalid_client_token(for: applePay, with: validator)
        try self.test_primer_configuration_validation(for: applePay, with: validator)
        try self.test_checkout_required_params_validation(for: applePay, with: validator)
        
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
        
        let appState = MockAppState(
            clientToken: MockAppState.mockClientToken)
        appState.clientToken = MockAppState.mockClientToken
        appState.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            clientSession: clientSession,
            paymentMethods: [applePay],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)
        
        
        DependencyContainer.register(appState as AppStateProtocol)
    }
    
    func test_invalid_client_token(for paymentMethod: PrimerPaymentMethod, with validator: PrimerValidator) throws {
        var exp = expectation(description: "Await client token validation")
        var expectationsToBeFulfilled = [exp]
        
        self.setUpValidState(with: [paymentMethod])
        AppState.current.clientToken = nil
        
        firstly {
            validator.validate()
        }
        .done {
            XCTAssert(false, "Should have failed with .invalidClientToken error")
            exp.fulfill()
        }
        .catch { err in
            if let primerErr = err as? PrimerError {
                switch primerErr {
                case .invalidClientToken:
                    XCTAssert(true)
                default:
                    XCTAssert(false, "Error should be PrimerError.invalidClientToken")
                }
            } else {
                XCTAssert(false, "Error should be PrimerError.invalidClientToken")
            }
            
            exp.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 3)
        
        exp = expectation(description: "Await client token validation")
        expectationsToBeFulfilled = [exp]
        
        self.setUpValidState(with: [paymentMethod])
        
        firstly {
            validator.validate()
        }
        .done {
            XCTAssert(true)
            exp.fulfill()
        }
        .catch { err in
            XCTAssert(false, "Should have passed validation, but failed with error \(err.localizedDescription)")
            exp.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 3)
    }
    
    func setUpValidState(with paymentMethods: [PrimerPaymentMethod]) {
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
        
        let appState = MockAppState(
            clientToken: MockAppState.mockClientToken)
        appState.clientToken = MockAppState.mockClientToken
        appState.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            clientSession: clientSession,
            paymentMethods: paymentMethods,
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)
        
        
        DependencyContainer.register(appState as AppStateProtocol)
    }
    
    func test_primer_configuration_validation(for paymentMethod: PrimerPaymentMethod, with validator: PrimerValidator) throws {
        var exp = expectation(description: "Await Primer configuration validation")
        var expectationsToBeFulfilled = [exp]
        
        self.setUpValidState(with: [paymentMethod])
        AppState.current.apiConfiguration = nil
        
        firstly {
            validator.validate()
        }
        .done {
            XCTAssert(false, "Should have failed with .missingPrimerConfiguration error")
            exp.fulfill()
        }
        .catch { err in
            if let primerErr = err as? PrimerError {
                switch primerErr {
                case .missingPrimerConfiguration:
                    XCTAssert(true)
                default:
                    XCTAssert(false, "Error should be PrimerError.missingPrimerConfiguration")
                }
            } else {
                XCTAssert(false, "Error should be PrimerError.missingPrimerConfiguration")
            }
            
            exp.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 3)
        
        exp = expectation(description: "Await Primer configuration validation")
        expectationsToBeFulfilled = [exp]
        
        self.setUpValidState(with: [paymentMethod])
        
        firstly {
            validator.validate()
        }
        .done {
            XCTAssert(true)
            exp.fulfill()
        }
        .catch { err in
            XCTAssert(false, "Should have passed validation, but failed with error \(err.localizedDescription)")
            exp.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 3)
    }
    
    func test_checkout_required_params_validation(for paymentMethod: PrimerPaymentMethod, with validator: PrimerValidator) throws {
        var exp = expectation(description: "Await payment method configuration id validation")
        var expectationsToBeFulfilled = [exp]
        
        let appState = MockAppState(clientToken: MockAppState.mockClientToken)
        appState.apiConfiguration = nil
        
        DependencyContainer.register(appState as AppStateProtocol)
        
        var clientSession = ClientSession.APIResponse(
            clientSessionId: "mock-client-session-id-1",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil),
            order: ClientSession.Order(
                id: "mock-client-session-order-id-1",
                merchantAmount: nil,
                totalOrderAmount: nil,
                totalTaxAmount: nil,
                countryCode: nil,
                currencyCode: nil,
                fees: nil,
                lineItems: nil,
                shippingAmount: nil),
            customer: nil,
            testId: nil)
        
        AppState.current.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)
        
        PrimerInternal.shared.intent = .checkout
        
        firstly {
            validator.validate()
        }
        .done {
            XCTAssert(false, "Should have failed with .underlyingErrors error")
            exp.fulfill()
        }
        .catch { err in
            if let primerErr = err as? PrimerError {
                switch primerErr {
                case .underlyingErrors(let errors, _, _):
                    if let primerErrors = errors as? [PrimerError], primerErrors.count == 2 {
                        XCTAssert(true)
                    } else {
                        XCTAssert(false, "PrimerError.underlyingErrors should contain 2 errors")
                    }
                default:
                    XCTAssert(false, "Error should be PrimerError.underlyingErrors")
                }
            } else {
                XCTAssert(false, "Error should be PrimerError.underlyingErrors")
            }
            
            exp.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 3)
        
        exp = expectation(description: "Await Primer configuration validation")
        expectationsToBeFulfilled = [exp]
        
        clientSession = ClientSession.APIResponse(
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
        
        AppState.current.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://primer.io/core",
            pciUrl: "https://primer.io/pci",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)
        
        firstly {
            validator.validate()
        }
        .done {
            exp.fulfill()
        }
        .catch { err in
            XCTAssert(false, "Validator should have succeeded, but failed with error \(err.localizedDescription)")
            exp.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 3)
    }
}

#endif
