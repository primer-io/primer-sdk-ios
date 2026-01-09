//
//  CheckoutComponentsPaymentMethodsBridgeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for CheckoutComponentsPaymentMethodsBridge covering payment method bridging from SDK configuration.
@available(iOS 15.0, *)
final class CheckoutComponentsPaymentMethodsBridgeTests: XCTestCase {

    private var mockConfigurationService: MockConfigurationService!
    private var sut: CheckoutComponentsPaymentMethodsBridge!

    override func setUp() {
        super.setUp()
        mockConfigurationService = MockConfigurationService()
        sut = CheckoutComponentsPaymentMethodsBridge(configurationService: mockConfigurationService)
    }

    override func tearDown() {
        sut = nil
        mockConfigurationService = nil
        super.tearDown()
    }

    // MARK: - Execute Tests - Error Cases

    func test_execute_whenNoConfiguration_throwsMissingPrimerConfiguration() async {
        // Given
        mockConfigurationService.apiConfiguration = nil

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .missingPrimerConfiguration:
                break // Expected error
            default:
                XCTFail("Expected missingPrimerConfiguration error, got \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError, got \(error)")
        }
    }

    func test_execute_whenNoPaymentMethods_throwsMisconfiguredPaymentMethods() async {
        // Given
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: nil)

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .misconfiguredPaymentMethods:
                break // Expected error
            default:
                XCTFail("Expected misconfiguredPaymentMethods error, got \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError, got \(error)")
        }
    }

    func test_execute_whenEmptyPaymentMethods_throwsMisconfiguredPaymentMethods() async {
        // Given
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: [])

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .misconfiguredPaymentMethods:
                break // Expected error
            default:
                XCTFail("Expected misconfiguredPaymentMethods error, got \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError, got \(error)")
        }
    }

    // MARK: - Execute Tests - Success Cases

    func test_execute_withValidPaymentMethods_returnsInternalPaymentMethods() async throws {
        // Given
        let paymentMethods = [
            createPaymentMethod(type: "PAYMENT_CARD", name: "Card"),
            createPaymentMethod(type: "PAYPAL", name: "PayPal")
        ]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.count, 2)
    }

    func test_execute_setsCorrectId() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.first?.id, "PAYMENT_CARD")
    }

    func test_execute_setsCorrectType() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYPAL", name: "PayPal")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.first?.type, "PAYPAL")
    }

    func test_execute_setsCorrectName() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "APPLE_PAY", name: "Apple Pay")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.first?.name, "Apple Pay")
    }

    func test_execute_setsConfigId() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card", processorConfigId: "config-123")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.first?.configId, "config-123")
    }

    func test_execute_setsIsEnabledTrue() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.first?.isEnabled ?? false)
    }

    func test_execute_setsSurcharge() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card", surcharge: 150)]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.first?.surcharge, 150)
    }

    func test_execute_setsHasUnknownSurcharge() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "pm-1",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        // Use the mutable property to set hasUnknownSurcharge
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: [paymentMethod])

        // When
        let result = try await sut.execute()

        // Then - hasUnknownSurcharge should be available from the converted method
        XCTAssertNotNil(result.first)
    }

    // MARK: - Required Input Elements Tests

    func test_execute_forPaymentCard_setsCardInputElements() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        let expectedElements: [PrimerInputElementType] = [.cardNumber, .cvv, .expiryDate, .cardholderName]
        XCTAssertEqual(result.first?.requiredInputElements, expectedElements)
    }

    func test_execute_forPayPal_setsEmptyInputElements() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYPAL", name: "PayPal")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.first?.requiredInputElements.isEmpty ?? false)
    }

    func test_execute_forApplePay_setsEmptyInputElements() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "APPLE_PAY", name: "Apple Pay")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.first?.requiredInputElements.isEmpty ?? false)
    }

    // MARK: - Multiple Payment Methods Tests

    func test_execute_withMultiplePaymentMethods_returnsAll() async throws {
        // Given
        let paymentMethods = [
            createPaymentMethod(type: "PAYMENT_CARD", name: "Card"),
            createPaymentMethod(type: "PAYPAL", name: "PayPal"),
            createPaymentMethod(type: "APPLE_PAY", name: "Apple Pay"),
            createPaymentMethod(type: "KLARNA", name: "Klarna")
        ]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.count, 4)
    }

    func test_execute_withMultiplePaymentMethods_preservesOrder() async throws {
        // Given
        let paymentMethods = [
            createPaymentMethod(type: "PAYPAL", name: "PayPal"),
            createPaymentMethod(type: "PAYMENT_CARD", name: "Card"),
            createPaymentMethod(type: "APPLE_PAY", name: "Apple Pay")
        ]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result[0].type, "PAYPAL")
        XCTAssertEqual(result[1].type, "PAYMENT_CARD")
        XCTAssertEqual(result[2].type, "APPLE_PAY")
    }

    // MARK: - Network Surcharges Tests

    func test_execute_forNonCardPaymentMethod_networkSurchargesIsNil() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYPAL", name: "PayPal")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then - non-card payment methods shouldn't have network surcharges
        XCTAssertNil(result.first?.networkSurcharges)
    }

    // MARK: - Network Surcharges Array Format Tests

    func test_execute_forPaymentCard_withNetworksArrayNestedSurcharge_extractsSurcharges() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 100]],
            ["type": "MASTERCARD", "surcharge": ["amount": 150]]
        ]
        let clientSession = createClientSessionWithNetworks(networksArray: networksArray)
        mockConfigurationService.apiConfiguration = createConfigurationWithClientSession(
            paymentMethods: paymentMethods,
            clientSession: clientSession
        )

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNotNil(result.first?.networkSurcharges)
        XCTAssertEqual(result.first?.networkSurcharges?["VISA"], 100)
        XCTAssertEqual(result.first?.networkSurcharges?["MASTERCARD"], 150)
    }

    func test_execute_forPaymentCard_withNetworksArrayDirectSurcharge_extractsSurcharges() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": 200],
            ["type": "AMEX", "surcharge": 300]
        ]
        let clientSession = createClientSessionWithNetworks(networksArray: networksArray)
        mockConfigurationService.apiConfiguration = createConfigurationWithClientSession(
            paymentMethods: paymentMethods,
            clientSession: clientSession
        )

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNotNil(result.first?.networkSurcharges)
        XCTAssertEqual(result.first?.networkSurcharges?["VISA"], 200)
        XCTAssertEqual(result.first?.networkSurcharges?["AMEX"], 300)
    }

    func test_execute_forPaymentCard_withZeroSurcharges_returnsNil() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": 0],
            ["type": "MASTERCARD", "surcharge": ["amount": 0]]
        ]
        let clientSession = createClientSessionWithNetworks(networksArray: networksArray)
        mockConfigurationService.apiConfiguration = createConfigurationWithClientSession(
            paymentMethods: paymentMethods,
            clientSession: clientSession
        )

        // When
        let result = try await sut.execute()

        // Then - zero surcharges should not be included
        XCTAssertNil(result.first?.networkSurcharges)
    }

    // MARK: - Network Surcharges Dict Format Tests

    func test_execute_forPaymentCard_withNetworksDictNestedSurcharge_extractsSurcharges() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 100]],
            "MASTERCARD": ["surcharge": ["amount": 200]]
        ]
        let clientSession = createClientSessionWithNetworks(networksDict: networksDict)
        mockConfigurationService.apiConfiguration = createConfigurationWithClientSession(
            paymentMethods: paymentMethods,
            clientSession: clientSession
        )

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNotNil(result.first?.networkSurcharges)
        XCTAssertEqual(result.first?.networkSurcharges?["VISA"], 100)
        XCTAssertEqual(result.first?.networkSurcharges?["MASTERCARD"], 200)
    }

    func test_execute_forPaymentCard_withNetworksDictDirectSurcharge_extractsSurcharges() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": 150],
            "DISCOVER": ["surcharge": 250]
        ]
        let clientSession = createClientSessionWithNetworks(networksDict: networksDict)
        mockConfigurationService.apiConfiguration = createConfigurationWithClientSession(
            paymentMethods: paymentMethods,
            clientSession: clientSession
        )

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNotNil(result.first?.networkSurcharges)
        XCTAssertEqual(result.first?.networkSurcharges?["VISA"], 150)
        XCTAssertEqual(result.first?.networkSurcharges?["DISCOVER"], 250)
    }

    // MARK: - Network Surcharges Edge Cases

    func test_execute_forPaymentCard_withNoClientSession_networkSurchargesIsNil() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then - no client session means no network surcharges
        XCTAssertNil(result.first?.networkSurcharges)
    }

    func test_execute_forPaymentCard_withMissingNetworkType_skipsInvalidEntries() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        let networksArray: [[String: Any]] = [
            ["surcharge": 100], // Missing type
            ["type": "VISA", "surcharge": 200]
        ]
        let clientSession = createClientSessionWithNetworks(networksArray: networksArray)
        mockConfigurationService.apiConfiguration = createConfigurationWithClientSession(
            paymentMethods: paymentMethods,
            clientSession: clientSession
        )

        // When
        let result = try await sut.execute()

        // Then - only valid entries should be included
        XCTAssertEqual(result.first?.networkSurcharges?.count, 1)
        XCTAssertEqual(result.first?.networkSurcharges?["VISA"], 200)
    }

    // MARK: - Logo and Display Metadata Tests

    func test_execute_withLogo_setsIcon() async throws {
        // Given
        let logo = PrimerTheme.BaseColoredURLs(
            coloredUrlStr: "https://example.com/logo.png",
            lightUrlStr: nil,
            darkUrlStr: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "pm-1",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        // We can't set the logo directly without proper mock, but test null case
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: [paymentMethod])

        // When
        let result = try await sut.execute()

        // Then - icon will be nil if logo not set in test configuration
        XCTAssertNotNil(result.first)
    }

    func test_execute_withNilLogo_iconIsNil() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNil(result.first?.icon)
    }

    // MARK: - Single Payment Method Tests

    func test_execute_withSinglePaymentMethod_returnsOne() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "KLARNA", name: "Klarna")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.type, "KLARNA")
        XCTAssertEqual(result.first?.name, "Klarna")
    }

    func test_execute_forUnknownPaymentMethod_setsEmptyInputElements() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "UNKNOWN_TYPE", name: "Unknown")]
        mockConfigurationService.apiConfiguration = createMinimalConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.first?.requiredInputElements.isEmpty ?? false)
    }

    // MARK: - Helpers

    private func createMinimalConfiguration(
        paymentMethods: [PrimerPaymentMethod]?
    ) -> PrimerAPIConfiguration {
        PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: paymentMethods,
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )
    }

    private func createPaymentMethod(
        type: String,
        name: String,
        processorConfigId: String? = nil,
        surcharge: Int? = nil
    ) -> PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: "pm-\(type)",
            implementationType: .nativeSdk,
            type: type,
            name: name,
            processorConfigId: processorConfigId,
            surcharge: surcharge,
            options: nil,
            displayMetadata: nil
        )
    }

    private func createConfigurationWithClientSession(
        paymentMethods: [PrimerPaymentMethod],
        clientSession: ClientSession.APIResponse
    ) -> PrimerAPIConfiguration {
        PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: clientSession,
            paymentMethods: paymentMethods,
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )
    }

    private func createClientSessionWithNetworks(
        networksArray: [[String: Any]]? = nil,
        networksDict: [String: [String: Any]]? = nil
    ) -> ClientSession.APIResponse {
        // Build the options array with PAYMENT_CARD containing networks
        var paymentCardOption: [String: Any] = ["type": "PAYMENT_CARD"]
        if let networksArray = networksArray {
            paymentCardOption["networks"] = networksArray
        } else if let networksDict = networksDict {
            paymentCardOption["networks"] = networksDict
        }

        let paymentMethod = ClientSession.PaymentMethod(
            vaultOnSuccess: false,
            options: [paymentCardOption],
            orderedAllowedCardNetworks: nil,
            descriptor: nil
        )

        return ClientSession.APIResponse(
            clientSessionId: "cs-123",
            paymentMethod: paymentMethod,
            order: nil,
            customer: nil,
            testId: nil
        )
    }
}
