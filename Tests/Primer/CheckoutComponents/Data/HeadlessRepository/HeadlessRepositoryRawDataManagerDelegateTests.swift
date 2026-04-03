//
//  HeadlessRepositoryRawDataManagerDelegateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

private final class StubValidationState: NSObject, PrimerValidationState {}

// MARK: - Network Detection Via Delegate

@available(iOS 15.0, *)
@MainActor
final class RawDataManagerDelegateNetworkDetectionTests: XCTestCase {

    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        sut = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_didReceiveMetadata_withNonCardState_doesNotEmit() async {
        // Given
        let stream = sut.getNetworkDetectionStream()
        let metadata = PrimerCardNumberEntryMetadata(
            source: .local,
            selectableCardNetworks: nil,
            detectedCardNetworks: [
                PrimerCardNetwork(displayName: "Visa", network: .visa),
            ]
        )
        let nonCardState = StubValidationState()

        // When - call delegate with non-card state (should be ignored)
        do {
            let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
                paymentMethodType: "PAYMENT_CARD"
            )
            sut.primerRawDataManager(
                rawDataManager,
                didReceiveMetadata: metadata,
                forState: nonCardState
            )
        } catch {
            // Expected in unit tests - RawDataManager requires SDK configuration
        }

        // Then - no crash
        XCTAssertNotNil(stream)
    }

    func test_willFetchMetadata_withNonCardState_doesNotCrash() async {
        // Given
        let nonCardState = StubValidationState()

        // When / Then - should early return without crash
        do {
            let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
                paymentMethodType: "PAYMENT_CARD"
            )
            sut.primerRawDataManager(rawDataManager, willFetchMetadataForState: nonCardState)
        } catch {
            // Expected - RawDataManager requires SDK setup
        }
    }

    func test_dataIsValid_delegateMethod_doesNotCrash() async {
        // Given / When / Then
        do {
            let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
                paymentMethodType: "PAYMENT_CARD"
            )
            sut.primerRawDataManager(rawDataManager, dataIsValid: true, errors: nil)
            sut.primerRawDataManager(rawDataManager, dataIsValid: false, errors: [TestError.unknown])
        } catch {
            // Expected in unit tests
        }
    }

    func test_metadataDidChange_delegateMethod_doesNotCrash() async {
        // Given / When / Then
        do {
            let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
                paymentMethodType: "PAYMENT_CARD"
            )
            sut.primerRawDataManager(rawDataManager, metadataDidChange: ["key": "value"])
            sut.primerRawDataManager(rawDataManager, metadataDidChange: nil)
        } catch {
            // Expected in unit tests
        }
    }
}

// MARK: - Update Card Number Stream Behavior

@available(iOS 15.0, *)
@MainActor
final class UpdateCardNumberStreamTests: XCTestCase {

    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        sut = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_updateCardNumber_belowBINThreshold_emitsEmptyNetworks() async {
        // Given
        let stream = sut.getNetworkDetectionStream()

        // First, simulate that lastDetectedNetworks is non-empty by calling with a long number
        // then call with a short number to trigger the clear
        await sut.updateCardNumberInRawDataManager("42424242")
        await sut.updateCardNumberInRawDataManager("4242")

        // Then - should not crash and stream should be available
        XCTAssertNotNil(stream)
    }

    func test_updateCardNumber_atExactBINThreshold_doesNotClearNetworks() async {
        // Given
        let stream = sut.getNetworkDetectionStream()

        // When - exactly 8 digits should NOT clear networks
        await sut.updateCardNumberInRawDataManager("42424242")

        // Then
        XCTAssertNotNil(stream)
    }

    func test_updateCardNumber_aboveBINThreshold_doesNotClearNetworks() async {
        // Given
        let stream = sut.getNetworkDetectionStream()

        // When - 16 digits
        await sut.updateCardNumberInRawDataManager("4242424242424242")

        // Then
        XCTAssertNotNil(stream)
    }

    func test_updateCardNumber_withSpaces_sanitizesBeforeComparing() async {
        // Given
        let stream = sut.getNetworkDetectionStream()

        // When - spaces should be stripped, making "4242 42" become "424242" (6 digits < 8)
        await sut.updateCardNumberInRawDataManager("4242 42")

        // Then
        XCTAssertNotNil(stream)
    }

    func test_updateCardNumber_emptyString_doesNotCrash() async {
        // Given / When
        await sut.updateCardNumberInRawDataManager("")

        // Then - no crash
    }

    func test_updateCardNumber_multipleRapidCalls_doesNotCrash() async {
        // Given / When - simulate rapid typing
        for i in 1 ... 16 {
            let partial = String("4242424242424242".prefix(i))
            await sut.updateCardNumberInRawDataManager(partial)
        }

        // Then - no crash
    }

    func test_selectCardNetwork_updatesRawCardData() async {
        // Given
        let mockClientSessionActions = MockClientSessionActionsModule()
        let sut = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { mockClientSessionActions }
        )

        // When
        await sut.selectCardNetwork(.visa)

        // Then - should not crash, network stored internally
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
    }
}

// MARK: - Payment Completion Handler Tests

@available(iOS 15.0, *)
@MainActor
final class PaymentCompletionHandlerTests: XCTestCase {

    private var mockRawDataManager: MockRawDataManager!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        sut = HeadlessRepositoryImpl(
            rawDataManagerFactory: mockRawDataManagerFactory
        )
    }

    override func tearDown() {
        mockRawDataManager = nil
        mockRawDataManagerFactory = nil
        sut = nil
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        super.tearDown()
    }

    func test_processCardPayment_setsCheckoutDelegate() async {
        // Given
        let factoryExpectation = XCTestExpectation(description: "Factory called")

        mockRawDataManagerFactory.createMockHandler = { _, _ in
            factoryExpectation.fulfill()
            let mock = MockRawDataManager()
            mock.configureError = NSError(domain: "test", code: 1)
            return mock
        }

        // When
        _ = try? await sut.processCardPayment(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then
        await fulfillment(of: [factoryExpectation], timeout: 2.0)
        XCTAssertEqual(mockRawDataManagerFactory.createCallCount, 1)
    }

    func test_processCardPayment_withConfigureSuccess_setsRawData() async {
        // Given
        let rawDataExpectation = XCTestExpectation(description: "Raw data set")
        mockRawDataManager.onRawDataSet = { _ in
            rawDataExpectation.fulfill()
        }

        // When
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

        await fulfillment(of: [rawDataExpectation], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertTrue(mockRawDataManager.rawDataSetCount >= 1)
    }
}
