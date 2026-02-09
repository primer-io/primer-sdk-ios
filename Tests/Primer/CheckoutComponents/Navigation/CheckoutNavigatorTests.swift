//
//  CheckoutNavigatorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

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
        sut.navigateToPaymentMethod(TestData.PaymentMethodTypes.card)
        try? await Task.sleep(nanoseconds: 30_000_000)
        sut.navigateToProcessing()

        await fulfillment(of: [expectation], timeout: 3.0)
        task.cancel()

        // Then - verify the sequence
        XCTAssertGreaterThanOrEqual(receivedRoutes.count, 5)
        XCTAssertEqual(receivedRoutes[0], .splash)
        XCTAssertEqual(receivedRoutes[1], .loading)
        XCTAssertEqual(receivedRoutes[2], .paymentMethodSelection)
        XCTAssertEqual(receivedRoutes[3], .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))
        XCTAssertEqual(receivedRoutes[4], .processing)
    }
}
