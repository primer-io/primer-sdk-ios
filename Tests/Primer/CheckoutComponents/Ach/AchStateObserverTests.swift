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

    private var mockScope: MockPrimerAchScope!

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

    // MARK: - Deterministic Wait Helpers

    /// Yields cooperatively until the observer's published state satisfies `predicate`, failing fast on timeout.
    ///
    /// Replaces fixed `Task.sleep` waits: the observer applies `scope.state` values on its own `@MainActor`
    /// task, so we re-read the published property after each yield and return as soon as it converges.
    @MainActor
    @discardableResult
    private func waitUntil(
        _ observer: AchStateObserver,
        timeout: TimeInterval = 2.0,
        file: StaticString = #file,
        line: UInt = #line,
        _ predicate: @escaping @MainActor (AchStateObserver) -> Bool
    ) async -> Bool {
        do {
            return try await withTimeout(timeout) { @MainActor in
                while !predicate(observer) {
                    await Task.yield()
                }
                return true
            }
        } catch {
            XCTFail("Timed out waiting for observer state: \(error)", file: file, line: line)
            return false
        }
    }

    /// Verifies the observer holds `predicate` continuously for `duration`, proving no further update lands.
    @MainActor
    private func assertStable(
        _ observer: AchStateObserver,
        for duration: TimeInterval = 0.2,
        file: StaticString = #file,
        line: UInt = #line,
        _ predicate: @escaping @MainActor (AchStateObserver) -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(duration)
        while Date() < deadline {
            guard predicate(observer) else {
                XCTFail("Observer left the expected stable state", file: file, line: line)
                return
            }
            await Task.yield()
        }
        XCTAssertTrue(predicate(observer), file: file, line: line)
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
            initialState: PrimerAchState(step: .userDetailsCollection, isSubmitEnabled: true)
        )
        let observer = AchStateObserver(scope: mockScope)

        // Initial state is the default PrimerAchState until startObserving is called
        XCTAssertEqual(observer.achState.step, .loading)
    }

    // MARK: - startObserving Tests

    @MainActor
    func test_startObserving_subscribesToScopeState() async {
        mockScope = MockPrimerAchScope(
            initialState: PrimerAchState(step: .userDetailsCollection)
        )
        let observerWithState = AchStateObserver(scope: mockScope)

        observerWithState.startObserving()

        await waitUntil(observerWithState) { $0.achState.step == .userDetailsCollection }

        XCTAssertEqual(observerWithState.achState.step, .userDetailsCollection)
    }

    @MainActor
    func test_startObserving_calledTwice_doesNotDuplicateObservation() async {
        let countingScope = CountingAchScope(
            wrapped: MockPrimerAchScope(initialState: PrimerAchState(step: .userDetailsCollection))
        )
        let observer = AchStateObserver(scope: countingScope)

        observer.startObserving()
        // Second call must be a no-op: the guard keeps a single observation task.
        observer.startObserving()

        await waitUntil(observer) { $0.achState.step == .userDetailsCollection }

        // A single observation means the scope's `state` stream was subscribed to exactly once,
        // proving the second startObserving() did not spin up a duplicate consumer.
        XCTAssertEqual(countingScope.stateAccessCount, 1)

        // The lone subscription still applies updates, confirming observation wasn't torn down.
        countingScope.emit(PrimerAchState(step: .processing))
        await waitUntil(observer) { $0.achState.step == .processing }
        XCTAssertEqual(observer.achState.step, .processing)
        XCTAssertEqual(countingScope.stateAccessCount, 1)
    }

    @MainActor
    func test_startObserving_receivesInitialState() async {
        let initialState = PrimerAchState(
            step: .userDetailsCollection,
            userDetails: AchTestData.defaultUserDetailsState,
            isSubmitEnabled: true
        )
        mockScope = MockPrimerAchScope(initialState: initialState)
        let observer = AchStateObserver(scope: mockScope)

        observer.startObserving()

        await waitUntil(observer) { $0.achState.step == .userDetailsCollection && $0.achState.isSubmitEnabled }

        XCTAssertEqual(observer.achState.step, .userDetailsCollection)
        XCTAssertTrue(observer.achState.isSubmitEnabled)
    }

    // MARK: - Bank Collector Visibility Tests

    @MainActor
    func test_stateTransition_toBankAccountCollection_showsBankCollector() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        mockScope.emit(PrimerAchState(step: .bankAccountCollection))

        await waitUntil(observer) { $0.showBankCollector }

        XCTAssertTrue(observer.showBankCollector)
    }

    @MainActor
    func test_stateTransition_toBankAccountCollection_withNilVC_doesNotShowBankCollector() async {
        mockScope.bankCollectorViewController = nil
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        mockScope.emit(PrimerAchState(step: .bankAccountCollection))

        await waitUntil(observer) { $0.achState.step == .bankAccountCollection }

        XCTAssertFalse(observer.showBankCollector)
    }

    @MainActor
    func test_stateTransition_toMandateAcceptance_setsStripeFlowCompleted() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        // First go to bank collection
        mockScope.emit(PrimerAchState(step: .bankAccountCollection))
        await waitUntil(observer) { $0.showBankCollector }
        XCTAssertTrue(observer.showBankCollector)

        // Then transition to mandate acceptance
        mockScope.emit(PrimerAchState(step: .mandateAcceptance, mandateText: "Test"))
        await waitUntil(observer) { $0.achState.step == .mandateAcceptance }

        // Bank collector remains visible: mandateAcceptance only flags stripeFlowCompleted, it never hides.
        XCTAssertTrue(observer.showBankCollector)
        XCTAssertEqual(observer.achState.mandateText, "Test")
    }

    @MainActor
    func test_stateTransition_afterStripeFlowCompleted_doesNotShowBankCollectorAgain() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        // Go through bank collection to mandate acceptance
        mockScope.emit(PrimerAchState(step: .bankAccountCollection))
        await waitUntil(observer) { $0.showBankCollector }
        XCTAssertTrue(observer.showBankCollector)

        mockScope.emit(PrimerAchState(step: .mandateAcceptance, mandateText: "Test"))
        await waitUntil(observer) { $0.achState.step == .mandateAcceptance }

        // Go to loading to reset showBankCollector to false
        mockScope.emit(PrimerAchState(step: .loading))
        await waitUntil(observer) { !$0.showBankCollector }
        XCTAssertFalse(observer.showBankCollector)

        // Try to go back to bank collection - should NOT show again because stripeFlowCompleted is true
        mockScope.emit(PrimerAchState(step: .bankAccountCollection))
        await waitUntil(observer) { $0.achState.step == .bankAccountCollection }

        // Even though we're at bankAccountCollection with a VC, it should NOT show because stripeFlowCompleted is true
        XCTAssertFalse(observer.showBankCollector)
    }

    @MainActor
    func test_stateTransition_toUserDetailsCollection_hidesBankCollector() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        // First show bank collector
        mockScope.emit(PrimerAchState(step: .bankAccountCollection))
        await waitUntil(observer) { $0.showBankCollector }
        XCTAssertTrue(observer.showBankCollector)

        // Go back to user details
        mockScope.emit(PrimerAchState(step: .userDetailsCollection))
        await waitUntil(observer) { !$0.showBankCollector }

        XCTAssertFalse(observer.showBankCollector)
    }

    @MainActor
    func test_stateTransition_toLoading_hidesBankCollector() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        // First show bank collector
        mockScope.emit(PrimerAchState(step: .bankAccountCollection))
        await waitUntil(observer) { $0.showBankCollector }
        XCTAssertTrue(observer.showBankCollector)

        // Go to loading
        mockScope.emit(PrimerAchState(step: .loading))
        await waitUntil(observer) { !$0.showBankCollector }

        XCTAssertFalse(observer.showBankCollector)
    }

    @MainActor
    func test_processing_doesNotHideBankCollector() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        // First show bank collector
        mockScope.emit(PrimerAchState(step: .bankAccountCollection))
        await waitUntil(observer) { $0.showBankCollector }
        XCTAssertTrue(observer.showBankCollector)

        // Go to processing - should not hide (processing and bankAccountCollection don't hide)
        mockScope.emit(PrimerAchState(step: .processing))
        await waitUntil(observer) { $0.achState.step == .processing }

        // Per the logic, processing doesn't set showBankCollector to false
        // because the condition is: step != .bankAccountCollection AND step != .processing
        XCTAssertTrue(observer.showBankCollector)
    }

    // MARK: - State Update Tests

    @MainActor
    func test_stateUpdate_updatesAchState() async {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        let newState = PrimerAchState(
            step: .userDetailsCollection,
            userDetails: PrimerAchState.UserDetails(
                firstName: "Jane",
                lastName: "Smith",
                emailAddress: "jane@example.com"
            ),
            isSubmitEnabled: true
        )

        mockScope.emit(newState)
        await waitUntil(observer) { $0.achState.userDetails.firstName == "Jane" }

        XCTAssertEqual(observer.achState.userDetails.firstName, "Jane")
        XCTAssertEqual(observer.achState.userDetails.lastName, "Smith")
        XCTAssertEqual(observer.achState.userDetails.emailAddress, "jane@example.com")
    }

    @MainActor
    func test_stateUpdate_withMandateText_updatesMandateText() async {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        mockScope.emit(PrimerAchState(
            step: .mandateAcceptance,
            mandateText: "Test mandate text",
            isSubmitEnabled: true
        ))
        await waitUntil(observer) { $0.achState.mandateText == "Test mandate text" }

        XCTAssertEqual(observer.achState.mandateText, "Test mandate text")
    }

    @MainActor
    func test_stateUpdate_withFieldValidation_updatesFieldValidation() async {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()

        let stateWithValidation = PrimerAchState(
            step: .userDetailsCollection,
            fieldValidation: PrimerAchState.FieldValidation(
                firstNameError: "Invalid first name",
                lastNameError: nil,
                emailError: "Invalid email"
            ),
            isSubmitEnabled: false
        )

        mockScope.emit(stateWithValidation)
        await waitUntil(observer) { $0.achState.fieldValidation?.firstNameError == "Invalid first name" }

        XCTAssertEqual(observer.achState.fieldValidation?.firstNameError, "Invalid first name")
        XCTAssertEqual(observer.achState.fieldValidation?.emailError, "Invalid email")
        XCTAssertNil(observer.achState.fieldValidation?.lastNameError)
    }

    // MARK: - stopObserving Tests

    @MainActor
    func test_stopObserving_cancelsTask() async {
        mockScope = MockPrimerAchScope(
            initialState: PrimerAchState(step: .userDetailsCollection)
        )
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        await waitUntil(observer) { $0.achState.step == .userDetailsCollection }

        observer.stopObserving()

        // After stopping, further emissions must not be applied to the observer.
        mockScope.emit(PrimerAchState(step: .mandateAcceptance, mandateText: "Should not update"))

        // State remains at the last observed state before stopping.
        await assertStable(observer) { $0.achState.step == .userDetailsCollection }
    }

    @MainActor
    func test_stopObserving_allowsRestart() async {
        let observer = AchStateObserver(scope: mockScope)

        observer.startObserving()
        await waitUntil(observer) { $0.achState.step == .loading }
        observer.stopObserving()

        // Should be able to restart
        observer.startObserving()
        mockScope.emit(PrimerAchState(step: .userDetailsCollection))
        await waitUntil(observer) { $0.achState.step == .userDetailsCollection }

        XCTAssertEqual(observer.achState.step, .userDetailsCollection)
    }

    @MainActor
    func test_stopObserving_multipleCallsDoesNotCrash() async {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        await waitUntil(observer) { $0.achState.step == .loading }

        // Multiple stop calls must not crash and must leave observation inert.
        observer.stopObserving()
        observer.stopObserving()
        observer.stopObserving()

        mockScope.emit(PrimerAchState(step: .userDetailsCollection))
        await assertStable(observer) { $0.achState.step == .loading }
    }

    // MARK: - Deallocation Tests

    @MainActor
    func test_deinit_cancelsObservationTask() async {
        var observer: AchStateObserver? = AchStateObserver(scope: mockScope)
        observer?.startObserving()
        await waitUntil(observer!) { $0.achState.step == .loading }

        weak var weakObserver = observer
        // Deallocate
        observer = nil

        // The observation task holds the observer weakly, so dropping the strong ref must release it.
        XCTAssertNil(weakObserver)

        // Emitting after deallocation must not crash.
        mockScope.emit(PrimerAchState(step: .mandateAcceptance))
        await Task.yield()
        XCTAssertNil(weakObserver)
    }

    // MARK: - Full Flow Tests

    @MainActor
    func test_fullFlow_loadingToUserDetailsToMandateToProcessing() async {
        mockScope.bankCollectorViewController = UIViewController()
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        await waitUntil(observer) { $0.achState.step == .loading }

        // Start at loading
        XCTAssertEqual(observer.achState.step, .loading)
        XCTAssertFalse(observer.showBankCollector)

        // Transition to user details
        mockScope.emit(PrimerAchState(
            step: .userDetailsCollection,
            userDetails: AchTestData.defaultUserDetailsState,
            isSubmitEnabled: true
        ))
        await waitUntil(observer) { $0.achState.step == .userDetailsCollection }
        XCTAssertEqual(observer.achState.step, .userDetailsCollection)
        XCTAssertFalse(observer.showBankCollector)

        // Transition to bank account collection
        mockScope.emit(PrimerAchState(step: .bankAccountCollection))
        await waitUntil(observer) { $0.showBankCollector }
        XCTAssertEqual(observer.achState.step, .bankAccountCollection)
        XCTAssertTrue(observer.showBankCollector)

        // Transition to mandate acceptance
        mockScope.emit(PrimerAchState(
            step: .mandateAcceptance,
            mandateText: "Test mandate",
            isSubmitEnabled: true
        ))
        await waitUntil(observer) { $0.achState.step == .mandateAcceptance }
        XCTAssertEqual(observer.achState.step, .mandateAcceptance)
        XCTAssertEqual(observer.achState.mandateText, "Test mandate")

        // Transition to processing
        mockScope.emit(PrimerAchState(step: .processing))
        await waitUntil(observer) { $0.achState.step == .processing }
        XCTAssertEqual(observer.achState.step, .processing)
    }

    @MainActor
    func test_rapidStateChanges_handlesCorrectly() async {
        let observer = AchStateObserver(scope: mockScope)
        observer.startObserving()
        await waitUntil(observer) { $0.achState.step == .loading }

        // Rapid state changes
        mockScope.emit(PrimerAchState(step: .loading))
        mockScope.emit(PrimerAchState(step: .userDetailsCollection))
        mockScope.emit(PrimerAchState(step: .loading))
        mockScope.emit(PrimerAchState(step: .userDetailsCollection, isSubmitEnabled: true))

        await waitUntil(observer) { $0.achState.step == .userDetailsCollection && $0.achState.isSubmitEnabled }

        // Final state should be the last emitted
        XCTAssertEqual(observer.achState.step, .userDetailsCollection)
        XCTAssertTrue(observer.achState.isSubmitEnabled)
    }
}

// MARK: - Counting Scope

/// Wraps `MockPrimerAchScope` to count how many times `state` is subscribed to, so de-duplication of
/// observation can be asserted deterministically without a fixed sleep.
@available(iOS 15.0, *)
@MainActor
private final class CountingAchScope: PrimerAchScope {

    private let wrapped: MockPrimerAchScope

    private(set) var stateAccessCount = 0

    var state: AsyncStream<PrimerAchState> {
        stateAccessCount += 1
        return wrapped.state
    }

    var presentationContext: PresentationContext { wrapped.presentationContext }
    var dismissalMechanism: [DismissalMechanism] { wrapped.dismissalMechanism }
    var bankCollectorViewController: UIViewController? { wrapped.bankCollectorViewController }

    var screen: AchScreenComponent? {
        get { wrapped.screen }
        set { wrapped.screen = newValue }
    }

    var userDetailsScreen: AchScreenComponent? {
        get { wrapped.userDetailsScreen }
        set { wrapped.userDetailsScreen = newValue }
    }

    var mandateScreen: AchScreenComponent? {
        get { wrapped.mandateScreen }
        set { wrapped.mandateScreen = newValue }
    }

    var submitButton: AchButtonComponent? {
        get { wrapped.submitButton }
        set { wrapped.submitButton = newValue }
    }

    init(wrapped: MockPrimerAchScope) {
        self.wrapped = wrapped
    }

    func emit(_ state: PrimerAchState) { wrapped.emit(state) }

    func start() { wrapped.start() }
    func submit() { wrapped.submit() }
    func cancel() { wrapped.cancel() }
    func updateFirstName(_ value: String) { wrapped.updateFirstName(value) }
    func updateLastName(_ value: String) { wrapped.updateLastName(value) }
    func updateEmailAddress(_ value: String) { wrapped.updateEmailAddress(value) }
    func submitUserDetails() { wrapped.submitUserDetails() }
    func acceptMandate() { wrapped.acceptMandate() }
    func declineMandate() { wrapped.declineMandate() }
}
