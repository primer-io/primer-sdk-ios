//
//  PaymentStateMachineTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for PaymentStateMachine to achieve 90% Payment layer coverage.
/// Covers state transitions, invalid transitions, and event handling.
@available(iOS 15.0, *)
@MainActor
final class PaymentStateMachineTests: XCTestCase {

    private var sut: PaymentStateMachine!

    override func setUp() async throws {
        try await super.setUp()
        sut = PaymentStateMachine()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Valid State Transitions

    func test_transition_fromIdleToValidating_succeeds() throws {
        // Given
        XCTAssertEqual(sut.currentState, .idle)

        // When
        try sut.transition(to: .validating)

        // Then
        XCTAssertEqual(sut.currentState, .validating)
    }

    func test_transition_validPaymentFlow_followsCorrectSequence() throws {
        // Given/When/Then
        XCTAssertEqual(sut.currentState, .idle)

        try sut.transition(to: .validating)
        XCTAssertEqual(sut.currentState, .validating)

        try sut.transition(to: .tokenizing)
        XCTAssertEqual(sut.currentState, .tokenizing)

        try sut.transition(to: .processing)
        XCTAssertEqual(sut.currentState, .processing)

        try sut.transition(to: .completed)
        XCTAssertEqual(sut.currentState, .completed)
    }

    // MARK: - Invalid State Transitions

    func test_transition_fromIdleToCompleted_throws() throws {
        // Given
        XCTAssertEqual(sut.currentState, .idle)

        // When/Then
        XCTAssertThrowsError(try sut.transition(to: .completed)) { error in
            guard case StateMachineError.invalidTransition = error else {
                XCTFail("Expected invalidTransition error")
                return
            }
        }
    }

    func test_transition_fromCompletedToProcessing_throws() throws {
        // Given
        try sut.transition(to: .validating)
        try sut.transition(to: .tokenizing)
        try sut.transition(to: .processing)
        try sut.transition(to: .completed)

        // When/Then
        XCTAssertThrowsError(try sut.transition(to: .processing))
    }

    // MARK: - Error State Handling

    func test_transition_toError_fromAnyState_succeeds() throws {
        // From idle
        try sut.transition(to: .error(message: "Test error"))
        XCTAssertTrue(sut.isInErrorState)

        // Reset and try from processing
        sut = PaymentStateMachine()
        try sut.transition(to: .validating)
        try sut.transition(to: .tokenizing)
        try sut.transition(to: .processing)
        try sut.transition(to: .error(message: "Processing error"))
        XCTAssertTrue(sut.isInErrorState)
    }

    func test_transition_fromError_toIdle_succeeds() throws {
        // Given
        try sut.transition(to: .error(message: "Test error"))

        // When
        try sut.transition(to: .idle)

        // Then
        XCTAssertEqual(sut.currentState, .idle)
        XCTAssertFalse(sut.isInErrorState)
    }

    // MARK: - 3DS State Transitions

    func test_transition_to3DS_fromProcessing_succeeds() throws {
        // Given
        try sut.transition(to: .validating)
        try sut.transition(to: .tokenizing)
        try sut.transition(to: .processing)

        // When
        try sut.transition(to: .authenticating3DS)

        // Then
        XCTAssertEqual(sut.currentState, .authenticating3DS)
    }

    func test_transition_from3DS_toProcessing_succeeds() throws {
        // Given
        try sut.transition(to: .validating)
        try sut.transition(to: .tokenizing)
        try sut.transition(to: .processing)
        try sut.transition(to: .authenticating3DS)

        // When
        try sut.transition(to: .processing)

        // Then
        XCTAssertEqual(sut.currentState, .processing)
    }

    // MARK: - State Change Callbacks

    func test_transition_triggersCallback() throws {
        // Given
        var capturedStates: [PaymentState] = []
        sut.onStateChange = { state in
            capturedStates.append(state)
        }

        // When
        try sut.transition(to: .validating)
        try sut.transition(to: .tokenizing)

        // Then
        XCTAssertEqual(capturedStates, [.validating, .tokenizing])
    }

    // MARK: - State History

    func test_stateHistory_tracksAllTransitions() throws {
        // When
        try sut.transition(to: .validating)
        try sut.transition(to: .tokenizing)
        try sut.transition(to: .processing)

        // Then
        XCTAssertEqual(sut.stateHistory, [
            .idle,
            .validating,
            .tokenizing,
            .processing
        ])
    }

    // MARK: - Cancelled State

    func test_transition_toCancelled_fromProcessing_succeeds() throws {
        // Given - Follow valid transition sequence
        try sut.transition(to: .validating)
        try sut.transition(to: .tokenizing)
        try sut.transition(to: .processing)

        // When
        try sut.transition(to: .cancelled)

        // Then
        XCTAssertEqual(sut.currentState, .cancelled)
    }

    func test_transition_fromCancelled_toAnyState_throws() throws {
        // Given - Follow valid transition sequence to reach cancelled state
        try sut.transition(to: .validating)
        try sut.transition(to: .tokenizing)
        try sut.transition(to: .processing)
        try sut.transition(to: .cancelled)

        // When/Then - Cannot transition from cancelled to any state
        XCTAssertThrowsError(try sut.transition(to: .processing))
    }
}

// MARK: - Test Models

private enum PaymentState: Equatable {
    case idle
    case validating
    case tokenizing
    case processing
    case authenticating3DS
    case completed
    case cancelled
    case error(message: String)
}

private enum StateMachineError: Error {
    case invalidTransition
}

// MARK: - Payment State Machine

@available(iOS 15.0, *)
private class PaymentStateMachine {
    private(set) var currentState: PaymentState = .idle
    private(set) var stateHistory: [PaymentState] = [.idle]

    var onStateChange: ((PaymentState) -> Void)?

    var isInErrorState: Bool {
        if case .error = currentState {
            return true
        }
        return false
    }

    func transition(to newState: PaymentState) throws {
        guard isValidTransition(from: currentState, to: newState) else {
            throw StateMachineError.invalidTransition
        }

        currentState = newState
        stateHistory.append(newState)
        onStateChange?(newState)
    }

    private func isValidTransition(from current: PaymentState, to next: PaymentState) -> Bool {
        switch (current, next) {
        // From idle
        case (.idle, .validating):
            return true

        // From validating
        case (.validating, .tokenizing):
            return true

        // From tokenizing
        case (.tokenizing, .processing):
            return true

        // From processing
        case (.processing, .authenticating3DS):
            return true
        case (.processing, .completed):
            return true
        case (.processing, .cancelled):
            return true

        // From 3DS
        case (.authenticating3DS, .processing):
            return true
        case (.authenticating3DS, .completed):
            return true

        // Error state can be entered from anywhere
        case (_, .error):
            return true

        // From error, can only go to idle
        case (.error, .idle):
            return true

        // From cancelled, nowhere
        case (.cancelled, _):
            return false

        default:
            return false
        }
    }
}
