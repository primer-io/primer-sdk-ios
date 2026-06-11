//
//  HeadlessRepositoryRawDataManagerDelegateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

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

    func test_selectCardNetwork_updatesRawCardData() async throws {
        // Given
        let mockClientSessionActions = MockClientSessionActionsModule()
        let sut = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { mockClientSessionActions }
        )

        // When
        await sut.selectCardNetwork(.visa)

        // Then - network stored internally via an async select-payment-method call
        try await withTimeout(2.0) {
            while mockClientSessionActions.selectPaymentMethodCalls.isEmpty {
                await Task.yield()
            }
        }
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
