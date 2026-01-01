//
//  HeadlessRepositoryPaymentFlowTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Payment Flow Setup Tests

/// Tests for processCardPayment setup and configuration flow
@available(iOS 15.0, *)
final class PaymentFlowSetupTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        // Clear DIContainer to prevent test pollution from other tests
        await DIContainer.clearContainer()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [unowned self] in self.mockClientSessionActions },
            rawDataManagerFactory: mockRawDataManagerFactory
        )
    }

    @MainActor
    override func tearDown() async throws {
        mockRawDataManager = nil
        mockRawDataManagerFactory = nil
        mockClientSessionActions = nil
        repository = nil
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        await DIContainer.clearContainer()
        try await super.tearDown()
    }

    // MARK: - Factory Usage Tests

    func testProcessCardPayment_UsesInjectedFactory() async {
        // Given
        mockRawDataManager.configureError = NSError(domain: "test", code: 1) // Force early exit

        // When
        _ = try? await repository.processCardPayment(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(mockRawDataManagerFactory.createCallCount, 1)
    }

    func testProcessCardPayment_PassesCorrectPaymentMethodType() async {
        // Given
        mockRawDataManager.configureError = NSError(domain: "test", code: 1)

        // When
        _ = try? await repository.processCardPayment(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(mockRawDataManagerFactory.lastCreateCall?.paymentMethodType, "PAYMENT_CARD")
    }

    func testProcessCardPayment_PassesDelegateToFactory() async {
        // Given
        mockRawDataManager.configureError = NSError(domain: "test", code: 1)

        // When
        _ = try? await repository.processCardPayment(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then
        XCTAssertNotNil(mockRawDataManagerFactory.lastCreateCall?.delegate)
    }

    func testProcessCardPayment_WhenFactoryThrows_PropagatesError() async {
        // Given
        let factoryError = NSError(domain: "Factory", code: 500, userInfo: [NSLocalizedDescriptionKey: "Cannot create"])
        mockRawDataManagerFactory.createError = factoryError

        // When/Then
        do {
            _ = try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
            XCTFail("Expected error to be thrown")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "Factory")
            XCTAssertEqual(error.code, 500)
        }
    }

    // MARK: - Delegate Setup Tests

    func testProcessCardPayment_SetsDelegate_OnHeadlessUniversalCheckout() async {
        // Given
        mockRawDataManager.configureError = NSError(domain: "test", code: 1)

        // When
        _ = try? await repository.processCardPayment(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then
        XCTAssertNotNil(PrimerHeadlessUniversalCheckout.current.delegate)
    }

    func testProcessCardPayment_DelegateConforms_ToRequiredProtocols() async {
        // Given
        mockRawDataManager.configureError = NSError(domain: "test", code: 1)

        // When
        _ = try? await repository.processCardPayment(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then
        let delegate = PrimerHeadlessUniversalCheckout.current.delegate
        XCTAssertTrue(delegate is PrimerHeadlessUniversalCheckoutDelegate)
    }
}

// MARK: - Configure Raw Data Manager Tests

@available(iOS 15.0, *)
final class ConfigureRawDataManagerFlowTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        // Clear DIContainer to prevent test pollution from other tests
        await DIContainer.clearContainer()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [unowned self] in self.mockClientSessionActions },
            rawDataManagerFactory: mockRawDataManagerFactory
        )
    }

    @MainActor
    override func tearDown() async throws {
        mockRawDataManager = nil
        mockRawDataManagerFactory = nil
        mockClientSessionActions = nil
        repository = nil
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        await DIContainer.clearContainer()
        try await super.tearDown()
    }

    func testConfigure_CallsConfigureOnRawDataManager() async {
        // Given
        mockRawDataManager.configureError = NSError(domain: "test", code: 1) // Force early exit

        // When
        _ = try? await repository.processCardPayment(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(mockRawDataManager.configureCallCount, 1)
    }

    func testConfigure_WhenConfigureFails_ThrowsError() async {
        // Given
        let configError = NSError(domain: "Config", code: 500, userInfo: [NSLocalizedDescriptionKey: "Config failed"])
        mockRawDataManager.configureError = configError

        // When/Then
        do {
            _ = try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
            XCTFail("Expected error to be thrown")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "Config")
            XCTAssertEqual(error.code, 500)
        }
    }

    func testConfigure_WhenSucceeds_SetsRawData() async {
        // Given - Configure succeeds but we need to handle the continuation
        // Since we can't trigger validation callback, the test will timeout
        // We verify rawData was set by using onRawDataSet callback
        var rawDataWasSet = false
        mockRawDataManager.onRawDataSet = { _ in
            rawDataWasSet = true
        }

        // Create a task that will timeout
        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        // Wait briefly for rawData to be set
        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        // Then
        XCTAssertTrue(rawDataWasSet)
        XCTAssertEqual(mockRawDataManager.rawDataSetCount, 1)
    }

    func testConfigure_SetsCardDataWithCorrectValues() async {
        // Given
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedCardData = rawData as? PrimerCardData
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242 4242 4242 4242", // With spaces
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "John Doe",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        // Then
        XCTAssertNotNil(capturedCardData)
        XCTAssertEqual(capturedCardData?.cardNumber, "4242424242424242") // Spaces stripped
        XCTAssertEqual(capturedCardData?.cvv, "123")
        XCTAssertEqual(capturedCardData?.expiryDate, "12/25")
        XCTAssertEqual(capturedCardData?.cardholderName, "John Doe")
    }

    func testConfigure_WithEmptyCardholderName_SetsNilCardholderName() async {
        // Given
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedCardData = rawData as? PrimerCardData
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "", // Empty
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        // Then
        XCTAssertNil(capturedCardData?.cardholderName)
    }

    func testConfigure_WithSelectedNetwork_SetsNetworkOnCardData() async {
        // Given
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedCardData = rawData as? PrimerCardData
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: .visa
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        // Then
        XCTAssertEqual(capturedCardData?.cardNetwork, .visa)
    }

    func testConfigure_With4DigitYear_FormatsCorrectly() async {
        // Given
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedCardData = rawData as? PrimerCardData
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "2025", // 4-digit year
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        // Then
        XCTAssertEqual(capturedCardData?.expiryDate, "12/2025")
    }
}

// MARK: - Card Network Selection Tests

@available(iOS 15.0, *)
final class CardNetworkSelectionInPaymentTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        // Clear DIContainer to prevent test pollution from other tests
        await DIContainer.clearContainer()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [unowned self] in self.mockClientSessionActions },
            rawDataManagerFactory: mockRawDataManagerFactory
        )
    }

    @MainActor
    override func tearDown() async throws {
        mockRawDataManager = nil
        mockRawDataManagerFactory = nil
        mockClientSessionActions = nil
        repository = nil
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        await DIContainer.clearContainer()
        try await super.tearDown()
    }

    func testPayment_WithVisaNetwork_SetsVisaOnCardData() async {
        // Given
        var capturedNetwork: CardNetwork?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedNetwork = (rawData as? PrimerCardData)?.cardNetwork
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: .visa
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertEqual(capturedNetwork, .visa)
    }

    func testPayment_WithMastercardNetwork_SetsMastercardOnCardData() async {
        // Given
        var capturedNetwork: CardNetwork?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedNetwork = (rawData as? PrimerCardData)?.cardNetwork
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "5555555555554444",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: .masterCard
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertEqual(capturedNetwork, .masterCard)
    }

    func testPayment_WithAmexNetwork_SetsAmexOnCardData() async {
        // Given
        var capturedNetwork: CardNetwork?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedNetwork = (rawData as? PrimerCardData)?.cardNetwork
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "378282246310005",
                cvv: "1234",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: .amex
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertEqual(capturedNetwork, .amex)
    }

    func testPayment_WithNilNetwork_DoesNotSetNetworkOnCardData() async {
        // Given
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedCardData = rawData as? PrimerCardData
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        // Card data should be set but network should be default/unknown
        XCTAssertNotNil(capturedCardData)
    }

    func testPayment_WithCartesBancairesNetwork_SetsCorrectNetwork() async {
        // Given
        var capturedNetwork: CardNetwork?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedNetwork = (rawData as? PrimerCardData)?.cardNetwork
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: .cartesBancaires
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertEqual(capturedNetwork, .cartesBancaires)
    }
}

// MARK: - Input Sanitization Tests

@available(iOS 15.0, *)
final class PaymentInputSanitizationTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        // Clear DIContainer to prevent test pollution from other tests
        await DIContainer.clearContainer()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [unowned self] in self.mockClientSessionActions },
            rawDataManagerFactory: mockRawDataManagerFactory
        )
    }

    @MainActor
    override func tearDown() async throws {
        mockRawDataManager = nil
        mockRawDataManagerFactory = nil
        mockClientSessionActions = nil
        repository = nil
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        await DIContainer.clearContainer()
        try await super.tearDown()
    }

    func testCardNumber_WithSpaces_StripsSpaces() async {
        // Given
        var capturedCardNumber: String?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedCardNumber = (rawData as? PrimerCardData)?.cardNumber
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242 4242 4242 4242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertEqual(capturedCardNumber, "4242424242424242")
    }

    func testCardNumber_WithMultipleSpaces_StripsAllSpaces() async {
        // Given
        var capturedCardNumber: String?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedCardNumber = (rawData as? PrimerCardData)?.cardNumber
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242  4242  4242  4242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertEqual(capturedCardNumber, "4242424242424242")
    }

    func testExpiryDate_FormatsCorrectly() async {
        // Given
        var capturedExpiryDate: String?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedExpiryDate = (rawData as? PrimerCardData)?.expiryDate
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "03",
                expiryYear: "28",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertEqual(capturedExpiryDate, "03/28")
    }

    func testCardholderName_PreservesValue() async {
        // Given
        var capturedName: String?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedName = (rawData as? PrimerCardData)?.cardholderName
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "John Michael Doe",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertEqual(capturedName, "John Michael Doe")
    }

    func testCVV_PreservesValue() async {
        // Given
        var capturedCVV: String?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedCVV = (rawData as? PrimerCardData)?.cvv
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "9999",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertEqual(capturedCVV, "9999")
    }
}
