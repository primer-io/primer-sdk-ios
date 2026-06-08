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

    func test_navigationEvents_emitsRouteChanges() async throws {
        // When - drive each navigation off the previously observed route, so the stream is
        // guaranteed subscribed before each transition is triggered.
        let receivedRoutes = try await collectUntil(sut.navigationEvents) { [self] route in
            switch route {
            case .splash: sut.navigateToLoading()
            case .loading: sut.navigateToPaymentSelection()
            default: break
            }
            return route == .paymentMethodSelection
        }

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

        // why: asserting the ABSENCE of an emission after cancellation — there is no signal to
        // await, so we give any erroneous emission a tick to (not) arrive.
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - count should not have increased (the stream was broken out of)
        XCTAssertEqual(receivedCount, countBeforeNavigation)
    }

    func test_navigationEvents_multipleSubscribers() async throws {
        // When - collect from both subscribers concurrently. Navigation is deferred until BOTH have
        // observed `.splash`, proving both iterations are subscribed before the transition is
        // delivered — so each is guaranteed to receive splash then loading without a timing hack.
        var splashSeen = 0
        func onSplash() {
            splashSeen += 1
            if splashSeen == 2 { sut.navigateToLoading() }
        }

        let stream1 = sut.navigationEvents
        let stream2 = sut.navigationEvents
        let subscriber2 = Task { [self] in
            try await collectUntil(stream2) { route in
                if route == .splash { onSplash() }
                return route == .loading
            }
        }
        let routes1 = try await collectUntil(stream1) { route in
            if route == .splash { onSplash() }
            return route == .loading
        }
        let routes2 = try await subscriber2.value

        // Then - both subscribers should receive routes
        XCTAssertGreaterThanOrEqual(routes1.count, 2)
        XCTAssertGreaterThanOrEqual(routes2.count, 2)
    }

    func test_navigationEvents_emitsCorrectRouteAfterMultipleChanges() async throws {
        // When - chain the full navigation flow off each observed route, guaranteeing the stream is
        // subscribed before every transition without timing hacks.
        let receivedRoutes = try await collectUntil(sut.navigationEvents, timeout: 3.0) { [self] route in
            switch route {
            case .splash: sut.navigateToLoading()
            case .loading: sut.navigateToPaymentSelection()
            case .paymentMethodSelection: sut.navigateToPaymentMethod(TestData.PaymentMethodTypes.card)
            case .paymentMethod: sut.navigateToProcessing()
            default: break
            }
            return route == .processing
        }

        // Then - verify the sequence
        XCTAssertGreaterThanOrEqual(receivedRoutes.count, 5)
        XCTAssertEqual(receivedRoutes[0], .splash)
        XCTAssertEqual(receivedRoutes[1], .loading)
        XCTAssertEqual(receivedRoutes[2], .paymentMethodSelection)
        XCTAssertEqual(receivedRoutes[3], .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection))
        XCTAssertEqual(receivedRoutes[4], .processing)
    }
}
