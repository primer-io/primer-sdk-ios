//
//  DefaultPayPalScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class DefaultPayPalScopeTests: XCTestCase {

    private var mockCheckoutScope: DefaultCheckoutScope!
    private var mockInteractor: MockProcessPayPalInteractor!
    private var sut: DefaultPayPalScope!

    @MainActor
    override func setUp() {
        super.setUp()
        mockCheckoutScope = createCheckoutScope()
        mockInteractor = MockProcessPayPalInteractor()
    }

    @MainActor
    override func tearDown() {
        sut = nil
        mockInteractor = nil
        mockCheckoutScope = nil
        super.tearDown()
    }

    // MARK: - Mock Types

    private final class MockProcessPayPalInteractor: ProcessPayPalPaymentInteractor {
        var executeResult: Result<PaymentResult, Error> = .success(
            PaymentResult(paymentId: "mock-payment", status: .success)
        )

        func execute() async throws -> PaymentResult {
            try executeResult.get()
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
        mockInteractor.executeResult = .success(PaymentResult(paymentId: "success-id", status: .success))

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
    func test_submit_emitsRedirectingDuringPayment() async {
        // Given
        sut = DefaultPayPalScope(
            checkoutScope: mockCheckoutScope,
            processPayPalInteractor: mockInteractor
        )

        var receivedStates: [PrimerPayPalState.Step] = []
        let redirectingExpectation = expectation(description: "Receive redirecting state")
        redirectingExpectation.assertForOverFulfill = false

        let stateTask = Task { @MainActor in
            for await state in sut.state {
                receivedStates.append(state.step)
                if case .redirecting = state.step {
                    redirectingExpectation.fulfill()
                }
            }
        }

        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // When
        sut.submit()

        // Then
        await fulfillment(of: [redirectingExpectation], timeout: 2.0)
        stateTask.cancel()

        XCTAssertTrue(receivedStates.contains(.redirecting))
    }

    // MARK: - Helpers

    @MainActor
    private func createCheckoutScope() -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: "mock_token",
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )
    }
}
