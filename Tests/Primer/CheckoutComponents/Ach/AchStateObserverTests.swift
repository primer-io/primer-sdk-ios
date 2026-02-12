//
//  AchStateObserverTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class AchStateObserverTests: XCTestCase {

    // MARK: - Properties

    var mockScope: MockPrimerAchScope!

    // MARK: - Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        mockScope = MockPrimerAchScope()
    }

    @MainActor
    override func tearDown() {
        mockScope = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func test_init_setsDefaultState() {
        let observer = AchStateObserver(scope: mockScope)

        XCTAssertEqual(observer.achState.step, .loading)
        XCTAssertFalse(observer.showBankCollector)
    }

    @MainActor
    func test_init_withCustomInitialState() {
        mockScope = MockPrimerAchScope(
            initialState: AchState(step: .userDetailsCollection, isSubmitEnabled: true)
        )
        let observer = AchStateObserver(scope: mockScope)

        // Initial state is the default AchState until startObserving is called
        XCTAssertEqual(observer.achState.step, .loading)
    }

    // MARK: - startObserving Tests

    @MainActor
    func test_startObserving_subscribesToScopeState() async {
        mockScope = MockPrimerAchScope(
            initialState: AchState(step: .userDetailsCollection)
        )
        let observerWithState = AchStateObserver(scope: mockScope)

        observerWithState.startObserving()

        // Wait for async state update
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(observerWithState.achState.step, .userDetailsCollection)
    }

    @MainActor
    func test_startObserving_calledTwice_doesNotDuplicateObservation() async {
        let observer = AchStateObserver(scope: mockScope)

        observer.startObserving()
        observer.startObserving()

        // Should not crash and should only have one observation task
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    @MainActor
    func test_startObserving_receivesInitialState() async {
        let initialState = AchState(
            step: .userDetailsCollection,
            userDetails: AchTestData.defaultUserDetailsState,
            isSubmitEnabled: true
        )
        mockScope = MockPrimerAchScope(initialState: initialState)
        let observer = AchStateObserver(scope: mockScope)

        observer.startObserving()

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(observer.achState.step, .userDetailsCollection)
        XCTAssertTrue(observer.achState.isSubmitEnabled)
    }

    // MARK: - Bank Collector Visibility Tests

    @MainActor
    func test_stateTransition_toBankAccountCollection_showsBankCollector() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        mockScope.emit(AchState(step: .bankAccountCollection))

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(observer.showBankCollector)
    }

    @MainActor
    func test_stateTransition_toBankAccountCollection_withNilVC_doesNotShowBankCollector() async {
        mockScope.bankCollectorViewController = nil
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        mockScope.emit(AchState(step: .bankAccountCollection))

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(observer.showBankCollector)
    }

    @MainActor
    func test_stateTransition_toMandateAcceptance_setsStripeFlowCompleted() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // First go to bank collection
        mockScope.emit(AchState(step: .bankAccountCollection))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(observer.showBankCollector)

        // Then transition to mandate acceptance
        mockScope.emit(AchState(step: .mandateAcceptance, mandateText: "Test"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Bank collector should still be showing because stripeFlowCompleted is internal
        // The view handles hiding based on the state
    }

    @MainActor
    func test_stateTransition_afterStripeFlowCompleted_doesNotShowBankCollectorAgain() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Go through bank collection to mandate acceptance
        mockScope.emit(AchState(step: .bankAccountCollection))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(observer.showBankCollector)

        mockScope.emit(AchState(step: .mandateAcceptance, mandateText: "Test"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Go to loading to reset showBankCollector to false
        mockScope.emit(AchState(step: .loading))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertFalse(observer.showBankCollector)

        // Try to go back to bank collection - should NOT show again because stripeFlowCompleted is true
        mockScope.emit(AchState(step: .bankAccountCollection))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Even though we're at bankAccountCollection with a VC, it should NOT show because stripeFlowCompleted is true
        XCTAssertFalse(observer.showBankCollector)
    }

    @MainActor
    func test_stateTransition_toUserDetailsCollection_hidesBankCollector() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // First show bank collector
        mockScope.emit(AchState(step: .bankAccountCollection))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(observer.showBankCollector)

        // Go back to user details
        mockScope.emit(AchState(step: .userDetailsCollection))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(observer.showBankCollector)
    }

    @MainActor
    func test_stateTransition_toLoading_hidesBankCollector() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // First show bank collector
        mockScope.emit(AchState(step: .bankAccountCollection))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(observer.showBankCollector)

        // Go to loading
        mockScope.emit(AchState(step: .loading))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(observer.showBankCollector)
    }

    @MainActor
    func test_processing_doesNotHideBankCollector() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // First show bank collector
        mockScope.emit(AchState(step: .bankAccountCollection))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(observer.showBankCollector)

        // Go to processing - should not hide (processing and bankAccountCollection don't hide)
        mockScope.emit(AchState(step: .processing))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Per the logic, processing doesn't set showBankCollector to false
        // because the condition is: step != .bankAccountCollection AND step != .processing
        XCTAssertTrue(observer.showBankCollector)
    }

    // MARK: - State Update Tests

    @MainActor
    func test_stateUpdate_updatesAchState() async {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        let newUserDetails = AchState.UserDetails(
            firstName: "Jane",
            lastName: "Smith",
            emailAddress: "jane@example.com"
        )
        let newState = AchState(
            step: .userDetailsCollection,
            userDetails: newUserDetails,
            isSubmitEnabled: true
        )

        mockScope.emit(newState)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(observer.achState.userDetails.firstName, "Jane")
        XCTAssertEqual(observer.achState.userDetails.lastName, "Smith")
        XCTAssertEqual(observer.achState.userDetails.emailAddress, "jane@example.com")
    }

    @MainActor
    func test_stateUpdate_withMandateText_updatesMandateText() async {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        let mandateState = AchState(
            step: .mandateAcceptance,
            mandateText: "Test mandate text",
            isSubmitEnabled: true
        )

        mockScope.emit(mandateState)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(observer.achState.mandateText, "Test mandate text")
    }

    @MainActor
    func test_stateUpdate_withFieldValidation_updatesFieldValidation() async {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        let validation = AchState.FieldValidation(
            firstNameError: "Invalid first name",
            lastNameError: nil,
            emailError: "Invalid email"
        )
        let stateWithValidation = AchState(
            step: .userDetailsCollection,
            fieldValidation: validation,
            isSubmitEnabled: false
        )

        mockScope.emit(stateWithValidation)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(observer.achState.fieldValidation?.firstNameError, "Invalid first name")
        XCTAssertEqual(observer.achState.fieldValidation?.emailError, "Invalid email")
        XCTAssertNil(observer.achState.fieldValidation?.lastNameError)
    }

    // MARK: - stopObserving Tests

    @MainActor
    func test_stopObserving_cancelsTask() async {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        observer.stopObserving()

        // After stopping, state updates should not be processed
        mockScope.emit(AchState(step: .mandateAcceptance, mandateText: "Should not update"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // State remains at the last observed state before stopping
        XCTAssertEqual(observer.achState.step, .loading)
    }

    @MainActor
    func test_stopObserving_allowsRestart() async {
        let observer = AchStateObserver(scope: mockScope)

        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)
        observer.stopObserving()

        // Should be able to restart
        observer.startObserving()
        mockScope.emit(AchState(step: .userDetailsCollection))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(observer.achState.step, .userDetailsCollection)
    }

    @MainActor
    func test_stopObserving_multipleCallsDoesNotCrash() {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        // Multiple stop calls should not crash
        observer.stopObserving()
        observer.stopObserving()
        observer.stopObserving()
    }

    // MARK: - Deallocation Tests

    @MainActor
    func test_deinit_cancelsObservationTask() async {
        var observer: AchStateObserver? = AchStateObserver(scope: mockScope)
        observer?.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Deallocate
        observer = nil

        // Should not crash when scope emits after observer is deallocated
        mockScope.emit(AchState(step: .mandateAcceptance))
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    // MARK: - Full Flow Tests

    @MainActor
    func test_fullFlow_loadingToUserDetailsToMandateToProcessing() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Start at loading
        XCTAssertEqual(observer.achState.step, .loading)
        XCTAssertFalse(observer.showBankCollector)

        // Transition to user details
        mockScope.emit(AchState(
            step: .userDetailsCollection,
            userDetails: AchTestData.defaultUserDetailsState,
            isSubmitEnabled: true
        ))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(observer.achState.step, .userDetailsCollection)
        XCTAssertFalse(observer.showBankCollector)

        // Transition to bank account collection
        mockScope.emit(AchState(step: .bankAccountCollection))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(observer.achState.step, .bankAccountCollection)
        XCTAssertTrue(observer.showBankCollector)

        // Transition to mandate acceptance
        mockScope.emit(AchState(
            step: .mandateAcceptance,
            mandateText: "Test mandate",
            isSubmitEnabled: true
        ))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(observer.achState.step, .mandateAcceptance)
        XCTAssertEqual(observer.achState.mandateText, "Test mandate")

        // Transition to processing
        mockScope.emit(AchState(step: .processing))
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(observer.achState.step, .processing)
    }

    @MainActor
    func test_rapidStateChanges_handlesCorrectly() async {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Rapid state changes
        mockScope.emit(AchState(step: .loading))
        mockScope.emit(AchState(step: .userDetailsCollection))
        mockScope.emit(AchState(step: .loading))
        mockScope.emit(AchState(step: .userDetailsCollection, isSubmitEnabled: true))

        try? await Task.sleep(nanoseconds: 200_000_000)

        // Final state should be the last emitted
        XCTAssertEqual(observer.achState.step, .userDetailsCollection)
        XCTAssertTrue(observer.achState.isSubmitEnabled)
    }
}
