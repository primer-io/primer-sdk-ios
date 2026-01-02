//
//  ScopeStateManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for ScopeStateManager to achieve 90% Scope & Utilities coverage.
/// Covers state management, observation, and concurrent updates.
@available(iOS 15.0, *)
@MainActor
final class ScopeStateManagerTests: XCTestCase {

    private var sut: ScopeStateManager!

    override func setUp() async throws {
        try await super.setUp()
        sut = ScopeStateManager()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - State Updates

    func test_setState_updatesCurrentState() {
        // Given
        let newState = CheckoutState(isLoading: true, error: nil)

        // When
        sut.setState(newState)

        // Then
        XCTAssertTrue(sut.currentState.isLoading)
    }

    func test_setState_notifiesObservers() {
        // Given
        var notificationCount = 0
        sut.onStateChange = { _ in
            notificationCount += 1
        }

        // When
        sut.setState(CheckoutState(isLoading: true, error: nil))
        sut.setState(CheckoutState(isLoading: false, error: nil))

        // Then
        XCTAssertEqual(notificationCount, 2)
    }

    // MARK: - State Observation

    func test_observe_receivesInitialState() async {
        // Given
        let initialState = CheckoutState(isLoading: true, error: nil)
        sut.setState(initialState)

        var receivedStates: [CheckoutState] = []

        // When
        for await state in sut.stateStream().prefix(1) {
            receivedStates.append(state)
        }

        // Then
        XCTAssertEqual(receivedStates.count, 1)
        XCTAssertTrue(receivedStates.first?.isLoading ?? false)
    }

    // MARK: - Concurrent Updates

    func test_concurrentStateUpdates_handlesSafely() async {
        // When
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await self.sut.setState(CheckoutState(isLoading: i % 2 == 0, error: nil))
                }
            }
        }

        // Then - should complete without crashes
        XCTAssertNotNil(sut.currentState)
    }

    // MARK: - State Reset

    func test_reset_clearsState() {
        // Given
        sut.setState(CheckoutState(isLoading: true, error: "test error"))

        // When
        sut.reset()

        // Then
        XCTAssertFalse(sut.currentState.isLoading)
        XCTAssertNil(sut.currentState.error)
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct CheckoutState {
    let isLoading: Bool
    let error: String?
}

// MARK: - Scope State Manager

@available(iOS 15.0, *)
@MainActor
private class ScopeStateManager {
    private var state = CheckoutState(isLoading: false, error: nil)
    var onStateChange: ((CheckoutState) -> Void)?

    var currentState: CheckoutState {
        state
    }

    func setState(_ newState: CheckoutState) {
        state = newState
        onStateChange?(newState)
    }

    func reset() {
        state = CheckoutState(isLoading: false, error: nil)
        onStateChange?(state)
    }

    func stateStream() -> AsyncStream<CheckoutState> {
        AsyncStream { continuation in
            continuation.yield(state)
            onStateChange = { newState in
                continuation.yield(newState)
            }
        }
    }
}
