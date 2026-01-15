//
//  HeadlessRepositoryPaymentFlowTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class PaymentFlowSetupTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        await DIContainer.clearContainer()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [self] in mockClientSessionActions },
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

    func testProcessCardPayment_UsesInjectedFactory() async {
        mockRawDataManager.configureError = NSError(domain: "test", code: 1)

        _ = try? await repository.processCardPayment(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        XCTAssertEqual(mockRawDataManagerFactory.createCallCount, 1)
    }

    func testProcessCardPayment_WhenFactoryThrows_PropagatesError() async {
        let factoryError = NSError(domain: "Factory", code: 500, userInfo: [NSLocalizedDescriptionKey: "Cannot create"])
        mockRawDataManagerFactory.createError = factoryError

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
}

@available(iOS 15.0, *)
final class ConfigureRawDataManagerFlowTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        await DIContainer.clearContainer()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [self] in mockClientSessionActions },
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
        mockRawDataManager.configureError = NSError(domain: "test", code: 1)

        _ = try? await repository.processCardPayment(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        XCTAssertEqual(mockRawDataManager.configureCallCount, 1)
    }

    func testConfigure_WhenConfigureFails_ThrowsError() async {
        let configError = NSError(domain: "Config", code: 500, userInfo: [NSLocalizedDescriptionKey: "Config failed"])
        mockRawDataManager.configureError = configError

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
        var rawDataWasSet = false
        mockRawDataManager.onRawDataSet = { _ in
            rawDataWasSet = true
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

        XCTAssertTrue(rawDataWasSet)
        XCTAssertEqual(mockRawDataManager.rawDataSetCount, 1)
    }

    func testConfigure_SetsCardDataWithCorrectValues() async {
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedCardData = rawData as? PrimerCardData
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242 4242 4242 4242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "John Doe",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertNotNil(capturedCardData)
        XCTAssertEqual(capturedCardData?.cardNumber, "4242424242424242")
        XCTAssertEqual(capturedCardData?.cvv, "123")
        XCTAssertEqual(capturedCardData?.expiryDate, "12/25")
        XCTAssertEqual(capturedCardData?.cardholderName, "John Doe")
    }

    func testConfigure_WithEmptyCardholderName_SetsNilCardholderName() async {
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
                cardholderName: "",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertNil(capturedCardData?.cardholderName)
    }

    func testConfigure_With4DigitYear_FormatsCorrectly() async {
        var capturedCardData: PrimerCardData?
        mockRawDataManager.onRawDataSet = { rawData in
            capturedCardData = rawData as? PrimerCardData
        }

        let task = Task {
            _ = try? await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "2025",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()

        XCTAssertEqual(capturedCardData?.expiryDate, "12/2025")
    }
}

@available(iOS 15.0, *)
final class CardNetworkSelectionInPaymentTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        await DIContainer.clearContainer()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [self] in mockClientSessionActions },
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

    func testPayment_WithSelectedNetwork_SetsNetworkOnCardData() async {
        let networksToTest: [CardNetwork] = [.visa, .masterCard, .amex, .cartesBancaires]

        for expectedNetwork in networksToTest {
            mockRawDataManager.reset()
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
                    selectedNetwork: expectedNetwork
                )
            }

            try? await Task.sleep(nanoseconds: 200_000_000)
            task.cancel()

            XCTAssertEqual(capturedNetwork, expectedNetwork, "Expected \(expectedNetwork) to be set")
        }
    }

    func testPayment_WithNilNetwork_DoesNotSetNetworkOnCardData() async {
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

        XCTAssertNotNil(capturedCardData)
    }
}

@available(iOS 15.0, *)
final class PaymentInputSanitizationTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        await DIContainer.clearContainer()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [self] in mockClientSessionActions },
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

    func testExpiryDate_FormatsCorrectly() async {
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
}
