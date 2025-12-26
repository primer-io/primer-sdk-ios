//
//  CheckoutNavigatorTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for CheckoutNavigator that provides high-level navigation APIs.
@available(iOS 15.0, *)
@MainActor
final class CheckoutNavigatorTests: XCTestCase {

    private var sut: CheckoutNavigator!
    private var coordinator: CheckoutCoordinator!

    override func setUp() async throws {
        try await super.setUp()
        coordinator = CheckoutCoordinator()
        sut = CheckoutNavigator(coordinator: coordinator)
    }

    override func tearDown() async throws {
        sut = nil
        coordinator = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_withCoordinator_usesProvidedCoordinator() {
        XCTAssertTrue(sut.checkoutCoordinator === coordinator)
    }

    func test_init_withoutCoordinator_createsDefaultCoordinator() {
        // Given/When
        let navigator = CheckoutNavigator()

        // Then
        XCTAssertNotNil(navigator.checkoutCoordinator)
    }

    // MARK: - NavigateToLoading Tests

    func test_navigateToLoading_setsLoadingRoute() {
        // When
        sut.navigateToLoading()

        // Then
        XCTAssertEqual(coordinator.currentRoute, .loading)
    }

    // MARK: - NavigateToPaymentSelection Tests

    func test_navigateToPaymentSelection_setsPaymentSelectionRoute() {
        // When
        sut.navigateToPaymentSelection()

        // Then
        XCTAssertEqual(coordinator.currentRoute, .paymentMethodSelection)
    }

    // MARK: - NavigateToPaymentMethod Tests

    func test_navigateToPaymentMethod_setsPaymentMethodRoute() {
        // Given
        sut.navigateToPaymentSelection()

        // When
        sut.navigateToPaymentMethod("PAYMENT_CARD")

        // Then
        XCTAssertEqual(coordinator.currentRoute, .paymentMethod("PAYMENT_CARD", .fromPaymentSelection))
    }

    func test_navigateToPaymentMethod_withDirectContext_setsCorrectRoute() {
        // When
        sut.navigateToPaymentMethod("APPLE_PAY", context: .direct)

        // Then
        XCTAssertEqual(coordinator.currentRoute, .paymentMethod("APPLE_PAY", .direct))
    }

    func test_navigateToPaymentMethod_defaultContext_isFromPaymentSelection() {
        // Given
        sut.navigateToPaymentSelection()

        // When
        sut.navigateToPaymentMethod("PAYMENT_CARD")

        // Then - verify default context is fromPaymentSelection
        XCTAssertEqual(coordinator.currentRoute, .paymentMethod("PAYMENT_CARD", .fromPaymentSelection))
    }

    // MARK: - NavigateToProcessing Tests

    func test_navigateToProcessing_setsProcessingRoute() {
        // When
        sut.navigateToProcessing()

        // Then
        XCTAssertEqual(coordinator.currentRoute, .processing)
    }

    // MARK: - NavigateToError Tests

    func test_navigateToError_setsFailureRoute() {
        // Given
        let error = PrimerError.invalidValue(key: "test", value: nil, reason: nil, diagnosticsId: "test-diagnostics")

        // When
        sut.navigateToError(error)

        // Then
        XCTAssertEqual(coordinator.currentRoute, .failure(error))
    }

    // MARK: - HandleOtherPaymentMethods Tests

    func test_handleOtherPaymentMethods_navigatesToPaymentSelection() {
        // Given - start at a payment method
        sut.navigateToPaymentMethod("PAYMENT_CARD", context: .direct)

        // When
        sut.handleOtherPaymentMethods()

        // Then
        XCTAssertEqual(coordinator.currentRoute, .paymentMethodSelection)
    }

    // MARK: - NavigateBack Tests

    func test_navigateBack_goesBackOnStack() {
        // Given
        sut.navigateToPaymentSelection()
        sut.navigateToPaymentMethod("PAYMENT_CARD")

        // When
        sut.navigateBack()

        // Then
        XCTAssertEqual(coordinator.currentRoute, .paymentMethodSelection)
    }

    // MARK: - Dismiss Tests

    func test_dismiss_clearsNavigationStack() {
        // Given
        sut.navigateToPaymentSelection()
        sut.navigateToPaymentMethod("PAYMENT_CARD")

        // When
        sut.dismiss()

        // Then
        XCTAssertTrue(coordinator.navigationStack.isEmpty)
    }

    // MARK: - CheckoutCoordinator Access Tests

    func test_checkoutCoordinator_returnsUnderlyingCoordinator() {
        // When/Then
        XCTAssertTrue(sut.checkoutCoordinator === coordinator)
    }

    // MARK: - Full Flow Tests

    func test_fullNavigationFlow_maintainsCorrectState() {
        // 1. Loading
        sut.navigateToLoading()
        XCTAssertEqual(coordinator.currentRoute, .loading)

        // 2. Payment selection
        sut.navigateToPaymentSelection()
        XCTAssertEqual(coordinator.currentRoute, .paymentMethodSelection)

        // 3. Select card
        sut.navigateToPaymentMethod("PAYMENT_CARD")
        XCTAssertEqual(coordinator.currentRoute, .paymentMethod("PAYMENT_CARD", .fromPaymentSelection))

        // 4. Processing
        sut.navigateToProcessing()
        XCTAssertEqual(coordinator.currentRoute, .processing)

        // 5. Dismiss
        sut.dismiss()
        XCTAssertTrue(coordinator.navigationStack.isEmpty)
    }

    func test_errorRecoveryFlow() {
        // 1. Navigate to processing
        sut.navigateToProcessing()

        // 2. Error occurs
        let error = PrimerError.invalidValue(key: "test", value: nil, reason: nil, diagnosticsId: "test-diagnostics")
        sut.navigateToError(error)
        XCTAssertEqual(coordinator.currentRoute, .failure(error))

        // 3. User wants to try different payment method
        sut.handleOtherPaymentMethods()
        XCTAssertEqual(coordinator.currentRoute, .paymentMethodSelection)
    }

    // MARK: - NavigationEvents Stream Tests

    func test_navigationEvents_emitsInitialRoute() async {
        // Given
        let expectation = XCTestExpectation(description: "Receive initial route")

        // When - subscribe to navigation events
        let task = Task {
            for await route in sut.navigationEvents {
                // Then - first emission should be splash (empty stack)
                XCTAssertEqual(route, .splash)
                expectation.fulfill()
                break
            }
        }

        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()
    }

    func test_navigationEvents_emitsRouteChanges() async {
        // Given
        let expectation = XCTestExpectation(description: "Receive navigation updates")
        var receivedRoutes: [CheckoutRoute] = []

        // When - subscribe and make navigation changes
        let task = Task {
            for await route in sut.navigationEvents {
                receivedRoutes.append(route)
                if receivedRoutes.count >= 3 {
                    expectation.fulfill()
                    break
                }
            }
        }

        // Give stream time to start
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        // Navigate
        sut.navigateToLoading()
        try? await Task.sleep(nanoseconds: 50_000_000)
        sut.navigateToPaymentSelection()

        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()

        // Then - should have received splash, loading, paymentMethodSelection
        XCTAssertGreaterThanOrEqual(receivedRoutes.count, 3)
        XCTAssertEqual(receivedRoutes[0], .splash)
        XCTAssertEqual(receivedRoutes[1], .loading)
        XCTAssertEqual(receivedRoutes[2], .paymentMethodSelection)
    }

    func test_navigationEvents_stopsEmittingAfterCancellation() async {
        // Given
        let expectation = XCTestExpectation(description: "Task cancelled")
        var receivedCount = 0

        // When - subscribe then cancel
        let task = Task {
            for await _ in sut.navigationEvents {
                receivedCount += 1
                if receivedCount == 1 {
                    break
                }
            }
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()

        // Navigate after cancellation
        let countBeforeNavigation = receivedCount
        sut.navigateToLoading()

        // Small delay to ensure no more emissions
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - count should not have increased significantly
        // (the stream was broken out of)
        XCTAssertEqual(receivedCount, countBeforeNavigation)
    }

    func test_navigationEvents_multipleSubscribers() async {
        // Given
        let expectation1 = XCTestExpectation(description: "Subscriber 1 receives")
        let expectation2 = XCTestExpectation(description: "Subscriber 2 receives")
        var routes1: [CheckoutRoute] = []
        var routes2: [CheckoutRoute] = []

        // When - create two subscribers
        let task1 = Task {
            for await route in sut.navigationEvents {
                routes1.append(route)
                if routes1.count >= 2 {
                    expectation1.fulfill()
                    break
                }
            }
        }

        let task2 = Task {
            for await route in sut.navigationEvents {
                routes2.append(route)
                if routes2.count >= 2 {
                    expectation2.fulfill()
                    break
                }
            }
        }

        // Give streams time to start
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Navigate
        sut.navigateToLoading()

        await fulfillment(of: [expectation1, expectation2], timeout: 2.0)
        task1.cancel()
        task2.cancel()

        // Then - both subscribers should receive routes
        XCTAssertGreaterThanOrEqual(routes1.count, 2)
        XCTAssertGreaterThanOrEqual(routes2.count, 2)
    }

    func test_navigationEvents_emitsCorrectRouteAfterMultipleChanges() async {
        // Given
        let expectation = XCTestExpectation(description: "Receive all routes")
        var receivedRoutes: [CheckoutRoute] = []

        // When
        let task = Task {
            for await route in sut.navigationEvents {
                receivedRoutes.append(route)
                if receivedRoutes.count >= 5 {
                    expectation.fulfill()
                    break
                }
            }
        }

        try? await Task.sleep(nanoseconds: 50_000_000)

        // Full navigation flow
        sut.navigateToLoading()
        try? await Task.sleep(nanoseconds: 30_000_000)
        sut.navigateToPaymentSelection()
        try? await Task.sleep(nanoseconds: 30_000_000)
        sut.navigateToPaymentMethod("PAYMENT_CARD")
        try? await Task.sleep(nanoseconds: 30_000_000)
        sut.navigateToProcessing()

        await fulfillment(of: [expectation], timeout: 3.0)
        task.cancel()

        // Then - verify the sequence
        XCTAssertGreaterThanOrEqual(receivedRoutes.count, 5)
        XCTAssertEqual(receivedRoutes[0], .splash)
        XCTAssertEqual(receivedRoutes[1], .loading)
        XCTAssertEqual(receivedRoutes[2], .paymentMethodSelection)
        XCTAssertEqual(receivedRoutes[3], .paymentMethod("PAYMENT_CARD", .fromPaymentSelection))
        XCTAssertEqual(receivedRoutes[4], .processing)
    }
}
