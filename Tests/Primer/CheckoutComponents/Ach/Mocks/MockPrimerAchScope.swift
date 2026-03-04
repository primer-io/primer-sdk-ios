//
//  MockPrimerAchScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit

@available(iOS 15.0, *)
@MainActor
final class MockPrimerAchScope: PrimerAchScope, ObservableObject {

    // MARK: - State Properties

    @Published private var internalState: PrimerAchState
    private var continuation: AsyncStream<PrimerAchState>.Continuation?

    // MARK: - Configurable Properties

    var presentationContext: PresentationContext
    var dismissalMechanism: [DismissalMechanism]
    var bankCollectorViewController: UIViewController?

    // MARK: - UI Customization Properties

    var screen: AchScreenComponent?
    var userDetailsScreen: AchScreenComponent?
    var mandateScreen: AchScreenComponent?
    var submitButton: AchButtonComponent?

    // MARK: - Call Tracking

    private(set) var startCallCount = 0
    private(set) var submitCallCount = 0
    private(set) var cancelCallCount = 0
    private(set) var updateFirstNameCallCount = 0
    private(set) var updateLastNameCallCount = 0
    private(set) var updateEmailAddressCallCount = 0
    private(set) var submitUserDetailsCallCount = 0
    private(set) var acceptMandateCallCount = 0
    private(set) var declineMandateCallCount = 0
    private(set) var onBackCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastFirstName: String?
    private(set) var lastLastName: String?
    private(set) var lastEmailAddress: String?

    // MARK: - Computed Properties

    var state: AsyncStream<PrimerAchState> {
        AsyncStream { continuation in
            // Emit current state immediately
            continuation.yield(internalState)

            // Store continuation for controlled emission
            self.continuation = continuation

            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in
                    self?.continuation = nil
                }
            }
        }
    }

    /// Returns the current internal state
    var currentState: PrimerAchState {
        internalState
    }

    // MARK: - Initialization

    init(
        initialState: PrimerAchState = PrimerAchState(),
        presentationContext: PresentationContext = .fromPaymentSelection,
        dismissalMechanism: [DismissalMechanism] = [.closeButton],
        bankCollectorViewController: UIViewController? = nil
    ) {
        internalState = initialState
        self.presentationContext = presentationContext
        self.dismissalMechanism = dismissalMechanism
        self.bankCollectorViewController = bankCollectorViewController
    }

    // MARK: - State Emission

    /// Emits a new state to all active observers
    func emit(_ state: PrimerAchState) {
        internalState = state
        continuation?.yield(state)
    }

    // MARK: - PrimerPaymentMethodScope Methods

    func start() {
        startCallCount += 1
    }

    func submit() {
        submitCallCount += 1
    }

    func cancel() {
        cancelCallCount += 1
    }

    // MARK: - User Details Actions

    func updateFirstName(_ value: String) {
        updateFirstNameCallCount += 1
        lastFirstName = value
    }

    func updateLastName(_ value: String) {
        updateLastNameCallCount += 1
        lastLastName = value
    }

    func updateEmailAddress(_ value: String) {
        updateEmailAddressCallCount += 1
        lastEmailAddress = value
    }

    func submitUserDetails() {
        submitUserDetailsCallCount += 1
    }

    // MARK: - Mandate Actions

    func acceptMandate() {
        acceptMandateCallCount += 1
    }

    func declineMandate() {
        declineMandateCallCount += 1
    }

    // MARK: - Navigation Methods

    func onBack() {
        onBackCallCount += 1
    }

    // MARK: - Test Helpers

    func reset() {
        startCallCount = 0
        submitCallCount = 0
        cancelCallCount = 0
        updateFirstNameCallCount = 0
        updateLastNameCallCount = 0
        updateEmailAddressCallCount = 0
        submitUserDetailsCallCount = 0
        acceptMandateCallCount = 0
        declineMandateCallCount = 0
        onBackCallCount = 0

        lastFirstName = nil
        lastLastName = nil
        lastEmailAddress = nil
    }
}

// MARK: - Factory Methods

@available(iOS 15.0, *)
extension MockPrimerAchScope {

    static func withLoadingState() -> MockPrimerAchScope {
        MockPrimerAchScope(initialState: PrimerAchState(step: .loading))
    }

    static func withUserDetailsState() -> MockPrimerAchScope {
        MockPrimerAchScope(
            initialState: PrimerAchState(
                step: .userDetailsCollection,
                userDetails: AchTestData.defaultUserDetailsState,
                isSubmitEnabled: true
            )
        )
    }

    static func withBankCollectionState(viewController: UIViewController? = nil) -> MockPrimerAchScope {
        MockPrimerAchScope(
            initialState: PrimerAchState(step: .bankAccountCollection),
            bankCollectorViewController: viewController ?? UIViewController()
        )
    }

    static func withMandateState() -> MockPrimerAchScope {
        MockPrimerAchScope(
            initialState: PrimerAchState(
                step: .mandateAcceptance,
                userDetails: AchTestData.defaultUserDetailsState,
                mandateText: AchTestData.Constants.mandateText,
                isSubmitEnabled: true
            )
        )
    }

    static func withProcessingState() -> MockPrimerAchScope {
        MockPrimerAchScope(initialState: PrimerAchState(step: .processing))
    }
}
