//
//  HeadlessRepositoryGetPaymentMethodsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Get Payment Methods Tests

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
            clientSessionActionsFactory: { [weak self] in
                self?.mockClientSessionActions ?? MockClientSessionActionsModule()
            },
            configurationServiceFactory: { [weak self] in
                self?.mockConfigurationService ?? MockConfigurationService()
            }
        )
    }

    override func tearDown() {
        mockConfigurationService = nil
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func testGetPaymentMethods_WithNoConfig_ReturnsEmptyArray() async throws {
        // Given
        mockConfigurationService.apiConfiguration = nil

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertTrue(methods.isEmpty)
    }

    func testGetPaymentMethods_WithPaymentMethods_ReturnsMappedMethods() async throws {
        // Given
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.count, 1)
        XCTAssertEqual(methods.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(methods.first?.name, "Card")
        XCTAssertEqual(methods.first?.configId, "config-123")
        XCTAssertEqual(methods.first?.surcharge, 100)
    }

    func testGetPaymentMethods_WithMultiplePaymentMethods_ReturnsAll() async throws {
        // Given
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.count, 2)
        XCTAssertTrue(methods.contains { $0.type == "PAYMENT_CARD" })
        XCTAssertTrue(methods.contains { $0.type == "PAYPAL" })
    }

    func testGetPaymentMethods_WithEmptyPaymentMethods_ReturnsEmptyArray() async throws {
        // Given
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertTrue(methods.isEmpty)
    }

    func testGetPaymentMethods_PaymentCardHasRequiredInputElements() async throws {
        // Given
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.requiredInputElements)
        XCTAssertFalse(cardMethod?.requiredInputElements.isEmpty ?? true)
    }

    func testGetPaymentMethods_NonCardMethodHasNoRequiredInputElements() async throws {
        // Given
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let paypalMethod = methods.first { $0.type == "PAYPAL" }
        XCTAssertNotNil(paypalMethod)
        XCTAssertTrue(paypalMethod?.requiredInputElements.isEmpty ?? true)
    }

    // MARK: - Network Surcharges Tests

    func testGetPaymentMethods_WithNetworkSurcharges_ExtractsFromArray() async throws {
        // Given - Client session with network surcharges in array format
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 100)
        XCTAssertEqual(cardMethod?.networkSurcharges?["MASTERCARD"], 150)
    }

    func testGetPaymentMethods_WithNetworkSurcharges_ExtractsFromDict() async throws {
        // Given - Client session with network surcharges in dictionary format
        let networkSurcharges: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 200]],
            "AMEX": ["surcharge": ["amount": 300]]
        ]
        // For dictionary format, we need to convert to the options array format
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 200)
        XCTAssertEqual(cardMethod?.networkSurcharges?["AMEX"], 300)
    }

    func testGetPaymentMethods_NonCardMethod_HasNilNetworkSurcharges() async throws {
        // Given - PayPal doesn't have network surcharges
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let paypalMethod = methods.first { $0.type == "PAYPAL" }
        XCTAssertNotNil(paypalMethod)
        XCTAssertNil(paypalMethod?.networkSurcharges)
        XCTAssertEqual(paypalMethod?.surcharge, 50)  // Regular surcharge should still be present
    }

    // MARK: - hasUnknownSurcharge Mapping Tests

    func testGetPaymentMethods_WithUnknownSurcharge_MapsCorrectly() async throws {
        // Given
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertTrue(cardMethod?.hasUnknownSurcharge ?? false)
    }

    func testGetPaymentMethods_WithNoUnknownSurcharge_MapsFalse() async throws {
        // Given
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
        // hasUnknownSurcharge defaults to false
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertFalse(cardMethod?.hasUnknownSurcharge ?? true)
    }

    // MARK: - Icon/Logo Mapping Tests

    func testGetPaymentMethods_WithNilDisplayMetadata_IconIsNil() async throws {
        // Given - Payment method with nil displayMetadata (thus nil logo)
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        // Icon is nil because displayMetadata is nil (no logo to load)
        XCTAssertNil(cardMethod?.icon)
    }

    func testGetPaymentMethods_IconMappingDoesNotCrash() async throws {
        // Given - Payment method configured normally
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - Should complete without crash
        XCTAssertEqual(methods.count, 1)
        let paypalMethod = methods.first { $0.type == "PAYPAL" }
        XCTAssertNotNil(paypalMethod)
        // Icon is optional - may be nil without displayMetadata/logo
    }

    // MARK: - Network Surcharges Edge Cases

    func testGetPaymentMethods_ClientSessionWithNoPaymentMethodData_NilNetworkSurcharges() async throws {
        // Given - Client session exists but no paymentMethod data
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: nil,  // No payment method data
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_ClientSessionWithNilOptions_NilNetworkSurcharges() async throws {
        // Given - Client session with paymentMethod but nil options
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,  // Nil options
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_ClientSessionOptionsWithoutPaymentCardType_NilNetworkSurcharges() async throws {
        // Given - Options exist but no PAYMENT_CARD type
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYPAL",  // Not PAYMENT_CARD
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_PaymentCardOptionWithNoNetworksKey_NilNetworkSurcharges() async throws {
        // Given - PAYMENT_CARD option exists but no "networks" key
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "someOtherKey": "someValue"  // No "networks" key
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_WithDirectIntegerSurchargeFormat_ExtractsSurcharges() async throws {
        // Given - Direct integer surcharge format (not nested in "amount")
        let networkSurcharges: [[String: Any]] = [
            [
                "type": "VISA",
                "surcharge": 75  // Direct integer, not nested
            ],
            [
                "type": "MASTERCARD",
                "surcharge": 125  // Direct integer
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 75)
        XCTAssertEqual(cardMethod?.networkSurcharges?["MASTERCARD"], 125)
    }

    func testGetPaymentMethods_WithZeroSurcharge_ExcludesNetwork() async throws {
        // Given - Zero surcharge should be excluded
        let networkSurcharges: [[String: Any]] = [
            [
                "type": "VISA",
                "surcharge": ["amount": 100]
            ],
            [
                "type": "MASTERCARD",
                "surcharge": ["amount": 0]  // Zero - should be excluded
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 100)
        XCTAssertNil(cardMethod?.networkSurcharges?["MASTERCARD"])  // Zero excluded
    }

    func testGetPaymentMethods_MultipleMethodsWithMixedSurcharges_MapsCorrectly() async throws {
        // Given - Multiple payment methods with different surcharge configurations
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
            surcharge: 25,  // Method-level surcharge
            options: nil,
            displayMetadata: nil
        )
        let paypalMethod = PrimerPaymentMethod(
            id: "paypal-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: "paypal-config",
            surcharge: 100,  // PayPal has method-level surcharge
            options: nil,
            displayMetadata: nil
        )
        let applePayMethod = PrimerPaymentMethod(
            id: "applepay-id",
            implementationType: .nativeSdk,
            type: "APPLE_PAY",
            name: "Apple Pay",
            processorConfigId: "applepay-config",
            surcharge: nil,  // No surcharge
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.count, 3)

        // Card has both method-level and network surcharges
        let card = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertEqual(card?.surcharge, 25)
        XCTAssertNotNil(card?.networkSurcharges)
        XCTAssertEqual(card?.networkSurcharges?["VISA"], 50)

        // PayPal has method-level surcharge but no network surcharges
        let paypal = methods.first { $0.type == "PAYPAL" }
        XCTAssertEqual(paypal?.surcharge, 100)
        XCTAssertNil(paypal?.networkSurcharges)

        // Apple Pay has no surcharges
        let applePay = methods.first { $0.type == "APPLE_PAY" }
        XCTAssertNil(applePay?.surcharge)
        XCTAssertNil(applePay?.networkSurcharges)
    }

    func testGetPaymentMethods_MapsIdToPaymentMethodType() async throws {
        // Given - Verify ID mapping
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - ID should be set to type (not the original id)
        let cardMethod = methods.first
        XCTAssertEqual(cardMethod?.id, "PAYMENT_CARD")  // ID is mapped to type
        XCTAssertEqual(cardMethod?.type, "PAYMENT_CARD")
    }

    func testGetPaymentMethods_IsEnabledAlwaysTrue() async throws {
        // Given
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - isEnabled is always true
        XCTAssertTrue(methods.first?.isEnabled ?? false)
    }

    func testGetPaymentMethods_SupportedCurrenciesIsNil() async throws {
        // Given
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - supportedCurrencies is always nil (not yet implemented)
        XCTAssertNil(methods.first?.supportedCurrencies)
    }

    func testGetPaymentMethods_MetadataIsNil() async throws {
        // Given
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - metadata is always nil (not yet extracted)
        XCTAssertNil(methods.first?.metadata)
    }
}

// MARK: - Get Payment Methods Additional Edge Cases Tests

@available(iOS 15.0, *)
final class GetPaymentMethodsAdditionalEdgeCasesTests: XCTestCase {

    private var mockConfigurationService: MockConfigurationService!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockConfigurationService = MockConfigurationService()
        repository = HeadlessRepositoryImpl(
            configurationServiceFactory: { [weak self] in
                self?.mockConfigurationService ?? MockConfigurationService()
            }
        )
    }

    override func tearDown() {
        mockConfigurationService = nil
        repository = nil
        super.tearDown()
    }

    func testGetPaymentMethods_WithVeryLongPaymentMethodName_MapsCorrectly() async throws {
        // Given - Payment method with very long name
        let longName = String(repeating: "A", count: 1000)
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: longName,
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.first?.name, longName)
    }

    func testGetPaymentMethods_WithEmptyPaymentMethodName_MapsCorrectly() async throws {
        // Given - Payment method with empty name
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.first?.name, "")
    }

    func testGetPaymentMethods_WithSpecialCharactersInName_MapsCorrectly() async throws {
        // Given - Payment method with special characters
        let specialName = "Карта 💳 & 日本語 <script>"
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: specialName,
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.first?.name, specialName)
    }

    func testGetPaymentMethods_WithNilProcessorConfigId_MapsToNil() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: nil,
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertNil(methods.first?.configId)
    }

    func testGetPaymentMethods_WithLargeSurcharge_MapsCorrectly() async throws {
        // Given - Very large surcharge value
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: Int.max,
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

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.first?.surcharge, Int.max)
    }

    func testGetPaymentMethods_CalledMultipleTimes_ReturnsConsistentResults() async throws {
        // Given
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

        // When - Call multiple times
        let methods1 = try await repository.getPaymentMethods()
        let methods2 = try await repository.getPaymentMethods()
        let methods3 = try await repository.getPaymentMethods()

        // Then - All should return same results
        XCTAssertEqual(methods1.count, methods2.count)
        XCTAssertEqual(methods2.count, methods3.count)
        XCTAssertEqual(methods1.first?.type, methods2.first?.type)
        XCTAssertEqual(methods2.first?.surcharge, methods3.first?.surcharge)
    }
}
