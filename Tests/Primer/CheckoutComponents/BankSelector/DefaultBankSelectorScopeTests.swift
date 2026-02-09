//
//  DefaultBankSelectorScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class DefaultBankSelectorScopeTests: XCTestCase {

    // MARK: - Properties

    var mockInteractor: MockProcessBankSelectorPaymentInteractor!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockInteractor = MockProcessBankSelectorPaymentInteractor()
    }

    override func tearDown() {
        mockInteractor = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    @MainActor
    func test_init_defaultPresentationContext_isFromPaymentSelection() {
        let scope = createScope()
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    @MainActor
    func test_init_directPresentationContext_isDirect() {
        let scope = createScope(presentationContext: .direct)
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    @MainActor
    func test_init_customizationPropertiesAreNil() {
        let scope = createScope()
        XCTAssertNil(scope.screen)
        XCTAssertNil(scope.bankItemComponent)
        XCTAssertNil(scope.searchBarComponent)
        XCTAssertNil(scope.emptyStateComponent)
    }

    // MARK: - UI Customization Tests

    @MainActor
    func test_screen_canBeSet() {
        let scope = createScope()
        scope.screen = { _ in EmptyView() }
        XCTAssertNotNil(scope.screen)
    }

    @MainActor
    func test_bankItemComponent_canBeSet() {
        let scope = createScope()
        scope.bankItemComponent = { _ in EmptyView() }
        XCTAssertNotNil(scope.bankItemComponent)
    }

    @MainActor
    func test_searchBarComponent_canBeSet() {
        let scope = createScope()
        scope.searchBarComponent = { EmptyView() }
        XCTAssertNotNil(scope.searchBarComponent)
    }

    @MainActor
    func test_emptyStateComponent_canBeSet() {
        let scope = createScope()
        scope.emptyStateComponent = { EmptyView() }
        XCTAssertNotNil(scope.emptyStateComponent)
    }

    // MARK: - Start Tests

    @MainActor
    func test_start_setsStatusToLoading() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        let scope = createScope()

        // When
        scope.start()

        // Then — first emitted state should be loading
        let state = try await awaitFirst(scope.state)
        XCTAssertEqual(state.status, .loading)
    }

    @MainActor
    func test_start_callsFetchBanks() async {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        let scope = createScope()

        // When
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.fetchBanksCallCount, 1)
    }

    @MainActor
    func test_start_transitionsToReadyWithBanks() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        let scope = createScope()

        // When
        scope.start()

        // Then — wait for ready state
        let state = try await awaitValue(scope.state, matching: { $0.status == .ready })
        XCTAssertEqual(state.status, .ready)
        XCTAssertEqual(state.banks.count, BankSelectorTestData.allBanks.count)
        XCTAssertEqual(state.filteredBanks.count, BankSelectorTestData.allBanks.count)
    }

    @MainActor
    func test_start_withEmptyBankList_setsReadyWithEmptyBanks() async throws {
        // Given
        mockInteractor.banksToReturn = []
        let scope = createScope()

        // When
        scope.start()

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.status == .ready })
        XCTAssertEqual(state.status, .ready)
        XCTAssertTrue(state.banks.isEmpty)
        XCTAssertTrue(state.filteredBanks.isEmpty)
    }

    @MainActor
    func test_start_withFetchError_doesNotCrash() async {
        // Given
        mockInteractor.fetchBanksError = TestError.networkFailure
        let scope = createScope()

        // When
        scope.start()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then — should not crash, error handled internally
        XCTAssertEqual(mockInteractor.fetchBanksCallCount, 1)
    }

    // MARK: - State AsyncStream Tests

    @MainActor
    func test_state_emitsInitialState() async {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        let scope = createScope()

        // When
        var receivedStates: [BankSelectorState] = []
        let task = Task {
            for await state in scope.state {
                receivedStates.append(state)
                if receivedStates.count >= 1 { break }
            }
        }

        // Wait for initial emission
        try? await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        // Then
        XCTAssertFalse(receivedStates.isEmpty)
    }

    @MainActor
    func test_state_streamCanBeCancelled() async {
        // Given
        let scope = createScope()

        // When
        let task = Task {
            for await _ in scope.state {
                // Just iterate
            }
        }

        task.cancel()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then
        XCTAssertTrue(task.isCancelled)
    }

    // MARK: - selectBank Tests

    @MainActor
    func test_selectBank_setsSelectedState() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        mockInteractor.paymentResultToReturn = BankSelectorTestData.testPaymentResult
        let scope = createScope()
        scope.start()

        // Wait for banks to load
        _ = try await awaitValue(scope.state, matching: { $0.status == .ready })

        // When
        let bank = BankSelectorTestData.ingBank
        scope.selectBank(bank)

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.status == .selected(bank) })
        XCTAssertEqual(state.selectedBank, bank)
        XCTAssertEqual(state.status, .selected(bank))
    }

    @MainActor
    func test_selectBank_callsInteractorExecute() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        mockInteractor.paymentResultToReturn = BankSelectorTestData.testPaymentResult
        let scope = createScope()
        scope.start()

        _ = try await awaitValue(scope.state, matching: { $0.status == .ready })

        // When
        scope.selectBank(BankSelectorTestData.ingBank)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.executeCallCount, 1)
        XCTAssertEqual(mockInteractor.lastExecuteBankId, BankSelectorTestData.ingBank.id)
    }

    @MainActor
    func test_selectBank_withDisabledBank_doesNotCallExecute() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanksWithDisabled
        let scope = createScope()
        scope.start()

        _ = try await awaitValue(scope.state, matching: { $0.status == .ready })

        // When
        scope.selectBank(BankSelectorTestData.disabledBank)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertEqual(mockInteractor.executeCallCount, 0)
    }

    @MainActor
    func test_selectBank_failure_doesNotCrash() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        mockInteractor.executeError = TestError.networkFailure
        let scope = createScope()
        scope.start()

        _ = try await awaitValue(scope.state, matching: { $0.status == .ready })

        // When
        scope.selectBank(BankSelectorTestData.ingBank)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then — should not crash, error delegated to checkout scope
        XCTAssertEqual(mockInteractor.executeCallCount, 1)
    }

    // MARK: - Search Tests

    @MainActor
    func test_search_filtersBanksCaseInsensitively() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        let scope = createScope()
        scope.start()

        _ = try await awaitValue(scope.state, matching: { $0.status == .ready })

        // When
        scope.search(query: "ing")

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.searchQuery == "ing" })
        XCTAssertEqual(state.filteredBanks.count, 1)
        XCTAssertEqual(state.filteredBanks.first?.id, BankSelectorTestData.ingBank.id)
    }

    @MainActor
    func test_search_emptyQuery_restoresFullList() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        let scope = createScope()
        scope.start()

        _ = try await awaitValue(scope.state, matching: { $0.status == .ready })

        // Filter first
        scope.search(query: "ING")
        _ = try await awaitValue(scope.state, matching: { $0.searchQuery == "ING" })

        // When
        scope.search(query: "")

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.searchQuery == "" && $0.filteredBanks.count == BankSelectorTestData.allBanks.count })
        XCTAssertEqual(state.filteredBanks.count, BankSelectorTestData.allBanks.count)
    }

    @MainActor
    func test_search_noMatch_returnsEmptyList() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        let scope = createScope()
        scope.start()

        _ = try await awaitValue(scope.state, matching: { $0.status == .ready })

        // When
        scope.search(query: "xyz_nonexistent")

        // Then
        let state = try await awaitValue(scope.state, matching: { $0.searchQuery == "xyz_nonexistent" })
        XCTAssertTrue(state.filteredBanks.isEmpty)
    }

    // MARK: - Navigation Tests

    @MainActor
    func test_onBack_withFromPaymentSelectionContext_shouldShowBackButton() {
        let scope = createScope(presentationContext: .fromPaymentSelection)
        XCTAssertTrue(scope.presentationContext.shouldShowBackButton)
        scope.onBack()
    }

    @MainActor
    func test_onBack_withDirectContext_shouldNotShowBackButton() {
        let scope = createScope(presentationContext: .direct)
        XCTAssertFalse(scope.presentationContext.shouldShowBackButton)
        scope.onBack()
    }

    @MainActor
    func test_onCancel_shouldNotCrash() {
        let scope = createScope()
        scope.onCancel()
    }

    @MainActor
    func test_cancel_shouldNotCrash() {
        let scope = createScope()
        scope.cancel()
    }

    // MARK: - Dismissal Mechanism Tests

    @MainActor
    func test_dismissalMechanism_returnsCheckoutScopeDismissalMechanism() {
        let scope = createScope()
        let mechanism = scope.dismissalMechanism
        XCTAssertNotNil(mechanism)
    }

    // MARK: - Submit Tests

    @MainActor
    func test_submit_withSelectedBank_callsSelectBank() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        mockInteractor.paymentResultToReturn = BankSelectorTestData.testPaymentResult
        let scope = createScope()
        scope.start()

        _ = try await awaitValue(scope.state, matching: { $0.status == .ready })

        // Select a bank first to set selectedBank
        scope.selectBank(BankSelectorTestData.ingBank)
        try? await Task.sleep(nanoseconds: 200_000_000)

        let initialExecuteCount = mockInteractor.executeCallCount

        // When
        scope.submit()
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then — submit calls selectBank again, which calls execute
        XCTAssertGreaterThan(mockInteractor.executeCallCount, initialExecuteCount)
    }

    // MARK: - Full Flow Tests

    @MainActor
    func test_fullFlow_start_loadBanks_selectBank_payment() async throws {
        // Given
        mockInteractor.banksToReturn = BankSelectorTestData.allBanks
        mockInteractor.paymentResultToReturn = BankSelectorTestData.testPaymentResult
        let scope = createScope()

        // When — start loads banks
        scope.start()
        _ = try await awaitValue(scope.state, matching: { $0.status == .ready })

        // Select bank
        scope.selectBank(BankSelectorTestData.ingBank)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertEqual(mockInteractor.fetchBanksCallCount, 1)
        XCTAssertEqual(mockInteractor.executeCallCount, 1)
        XCTAssertEqual(mockInteractor.lastExecuteBankId, BankSelectorTestData.ingBank.id)
    }

    // MARK: - Helper

    @MainActor
    private func createScope(
        presentationContext: PresentationContext = .fromPaymentSelection
    ) -> DefaultBankSelectorScope {
        let checkoutScope = DefaultCheckoutScope(
            clientToken: "mock_token",
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        return DefaultBankSelectorScope(
            checkoutScope: checkoutScope,
            presentationContext: presentationContext,
            interactor: mockInteractor,
            paymentMethodType: PrimerPaymentMethodType.adyenIDeal.rawValue
        )
    }
}
