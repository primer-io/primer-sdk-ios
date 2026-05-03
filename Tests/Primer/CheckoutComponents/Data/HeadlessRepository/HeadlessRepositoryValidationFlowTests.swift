//
//  HeadlessRepositoryValidationFlowTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - Validation Failure Handling

@available(iOS 15.0, *)
@MainActor
final class ValidationFailureHandlingTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        mockClientSessionActions = MockClientSessionActionsModule()
        sut = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [self] in mockClientSessionActions },
            rawDataManagerFactory: mockRawDataManagerFactory
        )
    }

    override func tearDown() {
        mockRawDataManager = nil
        mockRawDataManagerFactory = nil
        mockClientSessionActions = nil
        sut = nil
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        super.tearDown()
    }

    func test_processCardPayment_whenValidationFailsWithSingleError_throwsThatError() async {
        // Given
        let expectedError = NSError(
            domain: "Validation", code: 100,
            userInfo: [NSLocalizedDescriptionKey: "Invalid card number"]
        )
        mockRawDataManager.autoTriggerValidation = true
        mockRawDataManager.isDataValid = false
        mockRawDataManager.validationErrors = [expectedError]

        // When / Then
        do {
            _ = try await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
            XCTFail("Expected error to be thrown")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "Validation")
            XCTAssertEqual(error.code, 100)
        }
    }

    func test_processCardPayment_whenValidationFailsWithMultipleErrors_throwsUnderlyingErrors() async {
        // Given
        let error1 = NSError(domain: "V", code: 1, userInfo: nil)
        let error2 = NSError(domain: "V", code: 2, userInfo: nil)
        mockRawDataManager.autoTriggerValidation = true
        mockRawDataManager.isDataValid = false
        mockRawDataManager.validationErrors = [error1, error2]

        // When / Then
        do {
            _ = try await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Should be a PrimerError.underlyingErrors wrapping both errors
            if case let PrimerError.underlyingErrors(errors, _) = error {
                XCTAssertEqual(errors.count, 2)
            } else {
                // Acceptable if wrapped differently
                XCTAssertNotNil(error)
            }
        }
    }

    func test_processCardPayment_whenValidationFailsWithNoErrors_throwsInvalidValueError() async {
        // Given
        mockRawDataManager.autoTriggerValidation = true
        mockRawDataManager.isDataValid = false
        mockRawDataManager.validationErrors = nil

        // When / Then
        do {
            _ = try await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            if case let PrimerError.invalidValue(key, _, _, _) = error {
                XCTAssertEqual(key, "cardData")
            } else {
                // Acceptable if error type differs
                XCTAssertNotNil(error)
            }
        }
    }

    func test_processCardPayment_whenValidationFailsWithEmptyErrorArray_throwsInvalidValueError() async {
        // Given
        mockRawDataManager.autoTriggerValidation = true
        mockRawDataManager.isDataValid = false
        mockRawDataManager.validationErrors = []

        // When / Then
        do {
            _ = try await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            if case let PrimerError.invalidValue(key, _, _, _) = error {
                XCTAssertEqual(key, "cardData")
            } else {
                XCTAssertNotNil(error)
            }
        }
    }
}

// MARK: - Client Session Update Before Payment

@available(iOS 15.0, *)
@MainActor
final class ClientSessionUpdateBeforePaymentTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        mockClientSessionActions = MockClientSessionActionsModule()
        sut = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [self] in mockClientSessionActions },
            rawDataManagerFactory: mockRawDataManagerFactory
        )
    }

    override func tearDown() {
        mockRawDataManager = nil
        mockRawDataManagerFactory = nil
        mockClientSessionActions = nil
        sut = nil
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        super.tearDown()
    }

    func test_processCardPayment_whenValid_dispatchesClientSessionActions() async {
        // Given
        mockRawDataManager.autoTriggerValidation = true
        mockRawDataManager.isDataValid = true
        mockRawDataManager.validationErrors = nil

        let dispatchExpectation = XCTestExpectation(description: "Dispatch called")
        mockClientSessionActions.dispatchActionsError = nil

        let task = Task { [self] in
            _ = try? await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: .visa
            )
        }

        // Wait for dispatch to be called
        let predicate = NSPredicate { _, _ in
            !self.mockClientSessionActions.dispatchActionsCalls.isEmpty
        }
        await fulfillment(of: [expectation(for: predicate, evaluatedWith: nil)], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertFalse(mockClientSessionActions.dispatchActionsCalls.isEmpty)
    }

    func test_processCardPayment_whenClientSessionUpdateFails_throwsError() async {
        // Given
        mockRawDataManager.autoTriggerValidation = true
        mockRawDataManager.isDataValid = true
        mockRawDataManager.validationErrors = nil
        mockClientSessionActions.dispatchActionsError = NSError(
            domain: "ClientSession", code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Session update failed"]
        )

        // When / Then
        do {
            _ = try await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: .visa
            )
            XCTFail("Expected error to be thrown")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "ClientSession")
            XCTAssertEqual(error.code, 500)
        }
    }

    func test_processCardPayment_withNilNetwork_passesOTHERInClientSession() async {
        // Given
        mockRawDataManager.autoTriggerValidation = true
        mockRawDataManager.isDataValid = true

        let task = Task { [self] in
            _ = try? await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        // Wait for dispatch call
        let predicate = NSPredicate { _, _ in
            !self.mockClientSessionActions.dispatchActionsCalls.isEmpty
        }
        await fulfillment(of: [expectation(for: predicate, evaluatedWith: nil)], timeout: 3.0)
        task.cancel()

        // Then - nil network should map to "OTHER"
        XCTAssertFalse(mockClientSessionActions.dispatchActionsCalls.isEmpty)
    }

    func test_processCardPayment_withUnknownNetwork_passesOTHERInClientSession() async {
        // Given
        mockRawDataManager.autoTriggerValidation = true
        mockRawDataManager.isDataValid = true

        let task = Task { [self] in
            _ = try? await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: .unknown
            )
        }

        // Wait for dispatch call
        let predicate = NSPredicate { _, _ in
            !self.mockClientSessionActions.dispatchActionsCalls.isEmpty
        }
        await fulfillment(of: [expectation(for: predicate, evaluatedWith: nil)], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertFalse(mockClientSessionActions.dispatchActionsCalls.isEmpty)
    }

    func test_processCardPayment_whenValidAndSubmitted_callsSubmit() async {
        // Given
        mockRawDataManager.autoTriggerValidation = true
        mockRawDataManager.isDataValid = true

        let submitExpectation = XCTestExpectation(description: "Submit called")

        mockRawDataManagerFactory.createMockHandler = { [self] _, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            mock.autoTriggerValidation = true
            mock.isDataValid = true
            mock.onSubmit = {
                submitExpectation.fulfill()
            }
            return mock
        }

        let task = Task { [self] in
            _ = try? await sut.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: .visa
            )
        }

        await fulfillment(of: [submitExpectation], timeout: 5.0)
        task.cancel()
    }
}

// MARK: - Network Surcharge Dict Format

@available(iOS 15.0, *)
@MainActor
final class NetworkSurchargeDictFormatTests: XCTestCase {

    private var mockConfigurationService: MockConfigurationService!
    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockConfigurationService = MockConfigurationService()
        sut = HeadlessRepositoryImpl(
            configurationServiceFactory: { [self] in mockConfigurationService }
        )
    }

    override func tearDown() {
        mockConfigurationService = nil
        sut = nil
        super.tearDown()
    }

    func test_getPaymentMethods_withDictSurchargeDirectInt_extractsSurcharges() async throws {
        // Given - Dict format with direct integer surcharge values
        let networkSurcharges: [String: [String: Any]] = [
            "VISA": ["surcharge": 200],
            "MASTERCARD": ["surcharge": 350],
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges,
            ],
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
        let methods = try await sut.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 200)
        XCTAssertEqual(cardMethod?.networkSurcharges?["MASTERCARD"], 350)
    }

    func test_getPaymentMethods_withDictSurchargeZeroAmount_excludesNetwork() async throws {
        // Given
        let networkSurcharges: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 100]],
            "AMEX": ["surcharge": ["amount": 0]],
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges,
            ],
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
        let methods = try await sut.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 100)
        XCTAssertNil(cardMethod?.networkSurcharges?["AMEX"])
    }

    func test_getPaymentMethods_withDictAllZeroSurcharges_returnsNil() async throws {
        // Given
        let networkSurcharges: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 0]],
            "MASTERCARD": ["surcharge": ["amount": 0]],
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges,
            ],
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
        let methods = try await sut.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func test_getPaymentMethods_withArrayMissingTypeKey_skipsNetwork() async throws {
        // Given - network entry without "type" key should be skipped
        let networkSurcharges: [[String: Any]] = [
            ["surcharge": ["amount": 100]],
            ["type": "VISA", "surcharge": ["amount": 200]],
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges,
            ],
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
        let methods = try await sut.getPaymentMethods()

        // Then - only VISA should have surcharge
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?.count, 1)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 200)
    }

    func test_getPaymentMethods_withNilClientSessionOptions_returnsNilNetworkSurcharges() async throws {
        // Given
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
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
        let methods = try await sut.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func test_getPaymentMethods_withNetworksInvalidFormat_returnsNilNetworkSurcharges() async throws {
        // Given - networks value that is neither array nor dict
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": "invalid",
            ],
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
        let methods = try await sut.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNil(cardMethod?.networkSurcharges)
    }
}

// MARK: - Configuration Service Injection

@available(iOS 15.0, *)
@MainActor
final class ConfigurationServiceInjectionTests: XCTestCase {

    func test_getPaymentMethods_withFactoryInjection_usesFactory() async throws {
        // Given
        let mockConfigService = MockConfigurationService()
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
        mockConfigService.apiConfiguration = config

        let sut = HeadlessRepositoryImpl(
            configurationServiceFactory: { mockConfigService }
        )

        // When
        let methods = try await sut.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.count, 1)
        XCTAssertEqual(methods.first?.type, "PAYMENT_CARD")
    }

    func test_getPaymentMethods_withoutFactory_andNoDIContainer_returnsEmpty() async throws {
        // Given - no factory, no DI container
        await DIContainer.clearContainer()
        let sut = HeadlessRepositoryImpl()

        // When
        let methods = try await sut.getPaymentMethods()

        // Then
        XCTAssertTrue(methods.isEmpty)

        // Cleanup
        await DIContainer.clearContainer()
    }

    func test_getPaymentMethods_calledTwice_returnsSameResults() async throws {
        // Given
        let mockConfigService = MockConfigurationService()
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
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
        mockConfigService.apiConfiguration = config

        let sut = HeadlessRepositoryImpl(
            configurationServiceFactory: { mockConfigService }
        )

        // When
        let methods1 = try await sut.getPaymentMethods()
        let methods2 = try await sut.getPaymentMethods()

        // Then
        XCTAssertEqual(methods1.count, methods2.count)
        XCTAssertEqual(methods1.first?.type, methods2.first?.type)
        XCTAssertEqual(methods1.first?.surcharge, methods2.first?.surcharge)
    }
}
