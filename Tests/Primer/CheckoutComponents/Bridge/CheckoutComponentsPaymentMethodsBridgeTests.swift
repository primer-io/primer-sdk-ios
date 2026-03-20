//
//  CheckoutComponentsPaymentMethodsBridgeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

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

    // MARK: - Error Cases

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
        mockConfigurationService.apiConfiguration = createConfiguration(paymentMethods: nil)

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
        mockConfigurationService.apiConfiguration = createConfiguration(paymentMethods: [])

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

    // MARK: - Success & Field Mapping

    func test_execute_withValidPaymentMethods_mapsAllFieldsCorrectly() async throws {
        // Given
        let paymentMethods = [
            createPaymentMethod(type: "PAYMENT_CARD", name: "Card", processorConfigId: "config-123", surcharge: 150),
            createPaymentMethod(type: "PAYPAL", name: "PayPal")
        ]
        mockConfigurationService.apiConfiguration = createConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.count, 2)

        let card = result[0]
        XCTAssertEqual(card.id, "PAYMENT_CARD")
        XCTAssertEqual(card.type, "PAYMENT_CARD")
        XCTAssertEqual(card.name, "Card")
        XCTAssertEqual(card.configId, "config-123")
        XCTAssertTrue(card.isEnabled)
        XCTAssertEqual(card.surcharge, 150)

        let paypal = result[1]
        XCTAssertEqual(paypal.id, "PAYPAL")
        XCTAssertEqual(paypal.type, "PAYPAL")
        XCTAssertEqual(paypal.name, "PayPal")
    }

    // MARK: - Required Input Elements

    func test_execute_forPaymentCard_setsCardInputElements() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        mockConfigurationService.apiConfiguration = createConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        let expectedElements: [PrimerInputElementType] = [.cardNumber, .cvv, .expiryDate, .cardholderName]
        XCTAssertEqual(result.first?.requiredInputElements, expectedElements)
    }

    func test_execute_forNonCardPaymentMethod_setsEmptyInputElements() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYPAL", name: "PayPal")]
        mockConfigurationService.apiConfiguration = createConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.first?.requiredInputElements.isEmpty ?? false)
    }

    // MARK: - Multiple Payment Methods

    func test_execute_withMultiplePaymentMethods_preservesOrder() async throws {
        // Given
        let paymentMethods = [
            createPaymentMethod(type: "PAYPAL", name: "PayPal"),
            createPaymentMethod(type: "PAYMENT_CARD", name: "Card"),
            createPaymentMethod(type: "APPLE_PAY", name: "Apple Pay")
        ]
        mockConfigurationService.apiConfiguration = createConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].type, "PAYPAL")
        XCTAssertEqual(result[1].type, "PAYMENT_CARD")
        XCTAssertEqual(result[2].type, "APPLE_PAY")
    }

    // MARK: - Network Surcharges

    func test_execute_forNonCardPaymentMethod_networkSurchargesIsNil() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYPAL", name: "PayPal")]
        mockConfigurationService.apiConfiguration = createConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNil(result.first?.networkSurcharges)
    }

    func test_execute_forPaymentCard_withNoClientSession_networkSurchargesIsNil() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        mockConfigurationService.apiConfiguration = createConfiguration(paymentMethods: paymentMethods)

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNil(result.first?.networkSurcharges)
    }

    // MARK: - Network Surcharges Array Format

    func test_execute_forPaymentCard_withNetworksArrayNestedSurcharge_extractsSurcharges() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 100]],
            ["type": "MASTERCARD", "surcharge": ["amount": 150]]
        ]
        let clientSession = createClientSessionWithNetworks(networksArray: networksArray)
        mockConfigurationService.apiConfiguration = createConfiguration(
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
        mockConfigurationService.apiConfiguration = createConfiguration(
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
        mockConfigurationService.apiConfiguration = createConfiguration(
            paymentMethods: paymentMethods,
            clientSession: clientSession
        )

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertNil(result.first?.networkSurcharges)
    }

    // MARK: - Network Surcharges Dict Format

    func test_execute_forPaymentCard_withNetworksDictNestedSurcharge_extractsSurcharges() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 100]],
            "MASTERCARD": ["surcharge": ["amount": 200]]
        ]
        let clientSession = createClientSessionWithNetworks(networksDict: networksDict)
        mockConfigurationService.apiConfiguration = createConfiguration(
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
        mockConfigurationService.apiConfiguration = createConfiguration(
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

    func test_execute_forPaymentCard_withMissingNetworkType_skipsInvalidEntries() async throws {
        // Given
        let paymentMethods = [createPaymentMethod(type: "PAYMENT_CARD", name: "Card")]
        let networksArray: [[String: Any]] = [
            ["surcharge": 100], // Missing type
            ["type": "VISA", "surcharge": 200]
        ]
        let clientSession = createClientSessionWithNetworks(networksArray: networksArray)
        mockConfigurationService.apiConfiguration = createConfiguration(
            paymentMethods: paymentMethods,
            clientSession: clientSession
        )

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.first?.networkSurcharges?.count, 1)
        XCTAssertEqual(result.first?.networkSurcharges?["VISA"], 200)
    }

    // MARK: - Helpers

    private func createConfiguration(
        paymentMethods: [PrimerPaymentMethod]?,
        clientSession: ClientSession.APIResponse? = nil
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

    private func createClientSessionWithNetworks(
        networksArray: [[String: Any]]? = nil,
        networksDict: [String: [String: Any]]? = nil
    ) -> ClientSession.APIResponse {
        var paymentCardOption: [String: Any] = ["type": "PAYMENT_CARD"]
        if let networksArray {
            paymentCardOption["networks"] = networksArray
        } else if let networksDict {
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
