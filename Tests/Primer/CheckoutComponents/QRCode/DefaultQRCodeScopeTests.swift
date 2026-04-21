//
//  DefaultQRCodeScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class DefaultQRCodeScopeTests: XCTestCase {

    private var mockInteractor: MockProcessQRCodePaymentInteractor!

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        mockInteractor = MockProcessQRCodePaymentInteractor()
    }

    override func tearDown() async throws {
        mockInteractor = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    // MARK: - Full Success Flow

    func test_start_fullFlow_transitionsLoadingToDisplayingToSuccess() async throws {
        mockInteractor.startPaymentResult = .success(QRCodeTestData.defaultPaymentData)
        mockInteractor.pollAndCompleteResult = .success(QRCodeTestData.successPaymentResult)
        let sut = createScope()

        sut.start()

        let successState = try await awaitValue(sut.state, matching: { $0.status == .success })
        XCTAssertEqual(successState.status, .success)
        XCTAssertEqual(mockInteractor.startPaymentCallCount, 1)
        XCTAssertEqual(mockInteractor.pollAndCompleteCallCount, 1)
        XCTAssertEqual(mockInteractor.lastPollStatusUrl, QRCodeTestData.Constants.statusUrl)
        XCTAssertEqual(mockInteractor.lastPollPaymentId, QRCodeTestData.Constants.paymentId)
    }

    // MARK: - Displaying State

    func test_start_afterStartPayment_transitionsToDisplayingWithQRImage() async throws {
        mockInteractor.startPaymentResult = .success(QRCodeTestData.defaultPaymentData)
        mockInteractor.onPollAndComplete = {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            return QRCodeTestData.successPaymentResult
        }
        let sut = createScope()

        sut.start()

        let displayingState = try await awaitValue(sut.state, matching: { $0.status == .displaying })
        XCTAssertEqual(displayingState.status, .displaying)
        XCTAssertNotNil(displayingState.qrCodeImageData)
    }

    // MARK: - Error Handling

    func test_start_startPaymentError_transitionsToFailure() async throws {
        mockInteractor.startPaymentResult = .failure(
            PrimerError.invalidValue(key: "test", value: nil, reason: "Tokenization failed")
        )
        let sut = createScope()

        sut.start()

        let failureState = try await awaitValue(sut.state, matching: {
            if case .failure = $0.status { return true }
            return false
        })
        if case let .failure(message) = failureState.status {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected failure status")
        }
        XCTAssertEqual(mockInteractor.pollAndCompleteCallCount, 0)
    }

    func test_start_pollingError_transitionsToFailure() async throws {
        mockInteractor.startPaymentResult = .success(QRCodeTestData.defaultPaymentData)
        mockInteractor.pollAndCompleteResult = .failure(
            PrimerError.cancelled(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
        )
        let sut = createScope()

        sut.start()

        let failureState = try await awaitValue(sut.state, matching: {
            if case .failure = $0.status { return true }
            return false
        })
        if case .failure = failureState.status {
            XCTAssertEqual(mockInteractor.startPaymentCallCount, 1)
            XCTAssertEqual(mockInteractor.pollAndCompleteCallCount, 1)
        } else {
            XCTFail("Expected failure status")
        }
    }

    // MARK: - Cancellation

    func test_cancel_cancelsPollingOnInteractor() {
        let sut = createScope()

        sut.cancel()

        XCTAssertEqual(mockInteractor.cancelPollingCallCount, 1)
    }

    func test_onBack_cancelsPolling() {
        let sut = createScope(presentationContext: .fromPaymentSelection)

        sut.onBack()

        XCTAssertEqual(mockInteractor.cancelPollingCallCount, 1)
    }

    func test_cancel_cancelsPolling() {
        let sut = createScope()

        sut.cancel()

        XCTAssertEqual(mockInteractor.cancelPollingCallCount, 1)
    }

    // MARK: - Helpers

    private func createScope(
        presentationContext: PresentationContext = .fromPaymentSelection
    ) -> DefaultQRCodeScope {
        let checkoutScope = DefaultCheckoutScope(
            clientToken: QRCodeTestData.Constants.mockToken,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        return DefaultQRCodeScope(
            checkoutScope: checkoutScope,
            presentationContext: presentationContext,
            interactor: mockInteractor,
            paymentMethodType: "XENDIT_OVO"
        )
    }
}
