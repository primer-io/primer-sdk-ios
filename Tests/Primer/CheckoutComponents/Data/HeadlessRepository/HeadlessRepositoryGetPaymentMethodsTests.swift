//
//  HeadlessRepositoryGetPaymentMethodsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class GetPaymentMethodsTests: XCTestCase {

    private var mockConfigurationService: MockConfigurationService!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockConfigurationService = MockConfigurationService()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [self] in mockClientSessionActions },
            configurationServiceFactory: { [self] in mockConfigurationService }
        )
    }

    override func tearDown() {
        mockConfigurationService = nil
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func testGetPaymentMethods_WithNoConfig_ReturnsEmptyArray() async throws {
        mockConfigurationService.apiConfiguration = nil

        let methods = try await repository.getPaymentMethods()

        XCTAssertTrue(methods.isEmpty)
    }

    func testGetPaymentMethods_WithPaymentMethods_ReturnsMappedMethods() async throws {
        let paymentMethod = PrimerPaymentMethod(
            id: "payment-card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: 100,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        XCTAssertEqual(methods.count, 1)
        XCTAssertEqual(methods.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(methods.first?.name, "Card")
        XCTAssertEqual(methods.first?.configId, "config-123")
        XCTAssertEqual(methods.first?.surcharge, 100)
    }

    func testGetPaymentMethods_WithMultiplePaymentMethods_ReturnsAll() async throws {
        let cardMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "card-config",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let paypalMethod = PrimerPaymentMethod(
            id: "paypal-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: "paypal-config",
            surcharge: 50,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [cardMethod, paypalMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        XCTAssertEqual(methods.count, 2)
        XCTAssertTrue(methods.contains { $0.type == "PAYMENT_CARD" })
        XCTAssertTrue(methods.contains { $0.type == "PAYPAL" })
    }

    func testGetPaymentMethods_PaymentCardHasRequiredInputElements() async throws {
        let paymentMethod = PrimerPaymentMethod(
            id: "payment-card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.requiredInputElements)
        XCTAssertFalse(cardMethod?.requiredInputElements.isEmpty ?? true)
    }

    func testGetPaymentMethods_NonCardMethodHasNoRequiredInputElements() async throws {
        let paymentMethod = PrimerPaymentMethod(
            id: "paypal-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let paypalMethod = methods.first { $0.type == "PAYPAL" }
        XCTAssertNotNil(paypalMethod)
        XCTAssertTrue(paypalMethod?.requiredInputElements.isEmpty ?? true)
    }

    func testGetPaymentMethods_WithNetworkSurcharges_ExtractsFromArray() async throws {
        let networkSurcharges: [[String: Any]] = [
            [
                "type": "VISA",
                "surcharge": ["amount": 100]
            ],
            [
                "type": "MASTERCARD",
                "surcharge": ["amount": 150]
            ]
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 100)
        XCTAssertEqual(cardMethod?.networkSurcharges?["MASTERCARD"], 150)
    }

    func testGetPaymentMethods_WithNetworkSurcharges_ExtractsFromDict() async throws {
        let networkSurcharges: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 200]],
            "AMEX": ["surcharge": ["amount": 300]]
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 200)
        XCTAssertEqual(cardMethod?.networkSurcharges?["AMEX"], 300)
    }

    func testGetPaymentMethods_NonCardMethod_HasNilNetworkSurcharges() async throws {
        let paymentMethod = PrimerPaymentMethod(
            id: "paypal-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: "config-123",
            surcharge: 50,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let paypalMethod = methods.first { $0.type == "PAYPAL" }
        XCTAssertNotNil(paypalMethod)
        XCTAssertNil(paypalMethod?.networkSurcharges)
        XCTAssertEqual(paypalMethod?.surcharge, 50)
    }

    func testGetPaymentMethods_WithUnknownSurcharge_MapsCorrectly() async throws {
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: 100,
            options: nil,
            displayMetadata: nil
        )
        paymentMethod.hasUnknownSurcharge = true
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertTrue(cardMethod?.hasUnknownSurcharge ?? false)
    }

    func testGetPaymentMethods_WithNilDisplayMetadata_IconIsNil() async throws {
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.icon)
    }

    func testGetPaymentMethods_ClientSessionWithNoPaymentMethodData_NilNetworkSurcharges() async throws {
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: nil,
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_ClientSessionOptionsWithoutPaymentCardType_NilNetworkSurcharges() async throws {
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYPAL",
                "someKey": "someValue"
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_PaymentCardOptionWithNoNetworksKey_NilNetworkSurcharges() async throws {
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "someOtherKey": "someValue"
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_WithDirectIntegerSurchargeFormat_ExtractsSurcharges() async throws {
        let networkSurcharges: [[String: Any]] = [
            [
                "type": "VISA",
                "surcharge": 75
            ],
            [
                "type": "MASTERCARD",
                "surcharge": 125
            ]
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 75)
        XCTAssertEqual(cardMethod?.networkSurcharges?["MASTERCARD"], 125)
    }

    func testGetPaymentMethods_WithZeroSurcharge_ExcludesNetwork() async throws {
        let networkSurcharges: [[String: Any]] = [
            [
                "type": "VISA",
                "surcharge": ["amount": 100]
            ],
            [
                "type": "MASTERCARD",
                "surcharge": ["amount": 0]
            ]
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 100)
        XCTAssertNil(cardMethod?.networkSurcharges?["MASTERCARD"])
    }

    func testGetPaymentMethods_MultipleMethodsWithMixedSurcharges_MapsCorrectly() async throws {
        let networkSurcharges: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 50]]
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let cardMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "card-config",
            surcharge: 25,
            options: nil,
            displayMetadata: nil
        )
        let paypalMethod = PrimerPaymentMethod(
            id: "paypal-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: "paypal-config",
            surcharge: 100,
            options: nil,
            displayMetadata: nil
        )
        let applePayMethod = PrimerPaymentMethod(
            id: "applepay-id",
            implementationType: .nativeSdk,
            type: "APPLE_PAY",
            name: "Apple Pay",
            processorConfigId: "applepay-config",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [cardMethod, paypalMethod, applePayMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        XCTAssertEqual(methods.count, 3)

        let card = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertEqual(card?.surcharge, 25)
        XCTAssertNotNil(card?.networkSurcharges)
        XCTAssertEqual(card?.networkSurcharges?["VISA"], 50)

        let paypal = methods.first { $0.type == "PAYPAL" }
        XCTAssertEqual(paypal?.surcharge, 100)
        XCTAssertNil(paypal?.networkSurcharges)

        let applePay = methods.first { $0.type == "APPLE_PAY" }
        XCTAssertNil(applePay?.surcharge)
        XCTAssertNil(applePay?.networkSurcharges)
    }

    func testGetPaymentMethods_MapsIdToPaymentMethodType() async throws {
        let paymentMethod = PrimerPaymentMethod(
            id: "different-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        let cardMethod = methods.first
        XCTAssertEqual(cardMethod?.id, "PAYMENT_CARD")
        XCTAssertEqual(cardMethod?.type, "PAYMENT_CARD")
    }

    func testGetPaymentMethods_WithEmptyPaymentMethodName_MapsCorrectly() async throws {
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        let methods = try await repository.getPaymentMethods()

        XCTAssertEqual(methods.first?.name, "")
    }
}
