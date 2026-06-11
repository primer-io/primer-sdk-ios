//
//  DefaultPayPalScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
final class DefaultPayPalScopeTests: XCTestCase {

    private var mockCheckoutScope: DefaultCheckoutScope!
    private var mockInteractor: MockProcessPayPalInteractor!
    private var sut: DefaultPayPalScope!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        mockCheckoutScope = createCheckoutScope()
        mockInteractor = MockProcessPayPalInteractor()
    }

    @MainActor
    override func tearDown() async throws {
        sut = nil
        mockInteractor = nil
        mockCheckoutScope = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    // MARK: - Mock Types

    private final class MockProcessPayPalInteractor: ProcessPayPalPaymentInteractor {
        var executeResult: Result<PaymentResult, Error> = .success(
            PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)
        )

        // When set, execute() suspends until release() is called — lets a test observe the
        // transient `.redirecting` step deterministically instead of racing a fast return.
        var shouldHold = false
        private var continuation: CheckedContinuation<Void, Never>?

        func execute() async throws -> PaymentResult {
            if shouldHold {
                await withCheckedContinuation { continuation = $0 }
            }
            return try executeResult.get()
        }

        func release() {
            continuation?.resume()
            continuation = nil
        }
    }

    // MARK: - Start Tests

    @MainActor
    func test_start_setsStateToIdle() async {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // When
        sut.start()

        // Then
        var receivedState: PrimerPayPalState?
        let expectation = expectation(description: "Receive state")

        Task {
            for await state in sut.state {
                receivedState = state
                expectation.fulfill()
                break
            }
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedState?.step, .idle)
    }

    // MARK: - Submit Tests

    @MainActor
    func test_submit_onSuccess_transitionsStateToSuccess() async {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )
        mockInteractor.executeResult = .success(PaymentResult(paymentId: TestData.PaymentIds.success, status: .success))

        var receivedStates: [PrimerPayPalState.Step] = []
        let expectation = expectation(description: "Receive success state")
        expectation.assertForOverFulfill = false

        let stateTask = Task { @MainActor in
            for await state in sut.state {
                receivedStates.append(state.step)
                if case .success = state.step {
                    expectation.fulfill()
                }
            }
        }

        // When
        sut.submit()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        stateTask.cancel()

        XCTAssertTrue(receivedStates.contains(.success))
    }

    @MainActor
    func test_submit_onFailure_transitionsStateToFailure() async {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )
        mockInteractor.executeResult = .failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"]))

        var receivedStates: [PrimerPayPalState.Step] = []
        let expectation = expectation(description: "Receive failure state")
        expectation.assertForOverFulfill = false

        let stateTask = Task { @MainActor in
            for await state in sut.state {
                receivedStates.append(state.step)
                if case .failure = state.step {
                    expectation.fulfill()
                }
            }
        }

        // When
        sut.submit()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        stateTask.cancel()

        let failureState = receivedStates.first {
            if case .failure = $0 { return true }
            return false
        }
        XCTAssertNotNil(failureState)
    }

    @MainActor
    func test_submit_cancelledError_doesNotTransitionToFailure() async throws {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )
        mockInteractor.executeResult = .failure(
            PrimerError.cancelled(paymentMethodType: PrimerPaymentMethodType.payPal.rawValue)
        )

        // When
        sut.submit()
        _ = try await awaitValue(sut.state, matching: { $0.step == .redirecting })
        await Task.yield()
        await Task.yield()

        // Then - dismissing the PayPal sheet is a clean dismissal, never a payment failure
        let firstState = try await awaitFirst(sut.state)
        if case .failure = firstState.step {
            XCTFail("Cancellation must not transition to failure")
        }
    }

    @MainActor
    func test_submit_emitsRedirectingDuringPayment() async throws {
        // Given — hold the interactor so the `.redirecting` step persists long enough to observe
        // deterministically (otherwise it is immediately replaced by `.success`).
        mockInteractor.shouldHold = true
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        // When
        sut.submit()

        // Then
        let state = try await awaitValue(sut.state, matching: { $0.step == .redirecting })
        XCTAssertEqual(state.step, .redirecting)
        mockInteractor.release()
    }

    // MARK: - Helpers

    @MainActor
    private func createCheckoutScope() -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            navigator: CheckoutNavigator()
        )
    }
}
