//
//  BankSelectorStateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class BankSelectorStateTests: XCTestCase {

    // MARK: - Default Initialization Tests

    func test_defaultInit_statusIsLoading() {
        let state = BankSelectorState()
        XCTAssertEqual(state.status, .loading)
    }

    func test_defaultInit_banksIsEmpty() {
        let state = BankSelectorState()
        XCTAssertTrue(state.banks.isEmpty)
    }

    func test_defaultInit_filteredBanksIsEmpty() {
        let state = BankSelectorState()
        XCTAssertTrue(state.filteredBanks.isEmpty)
    }

    func test_defaultInit_selectedBankIsNil() {
        let state = BankSelectorState()
        XCTAssertNil(state.selectedBank)
    }

    func test_defaultInit_searchQueryIsEmpty() {
        let state = BankSelectorState()
        XCTAssertTrue(state.searchQuery.isEmpty)
    }

    // MARK: - Custom Initialization Tests

    func test_customInit_allParameters() {
        let bank = BankSelectorTestData.ingBank
        let banks = BankSelectorTestData.allBanks
        let state = BankSelectorState(
            status: .selected(bank),
            banks: banks,
            filteredBanks: [bank],
            selectedBank: bank,
            searchQuery: "ING"
        )

        XCTAssertEqual(state.status, .selected(bank))
        XCTAssertEqual(state.banks.count, banks.count)
        XCTAssertEqual(state.filteredBanks.count, 1)
        XCTAssertEqual(state.selectedBank, bank)
        XCTAssertEqual(state.searchQuery, "ING")
    }

    // MARK: - Status Equatable Tests

    func test_status_loading_isEquatable() {
        XCTAssertEqual(BankSelectorState.Status.loading, BankSelectorState.Status.loading)
    }

    func test_status_ready_isEquatable() {
        XCTAssertEqual(BankSelectorState.Status.ready, BankSelectorState.Status.ready)
    }

    func test_status_selected_sameBankIsEqual() {
        let bank = BankSelectorTestData.ingBank
        XCTAssertEqual(
            BankSelectorState.Status.selected(bank),
            BankSelectorState.Status.selected(bank)
        )
    }

    func test_status_selected_differentBanksAreNotEqual() {
        XCTAssertNotEqual(
            BankSelectorState.Status.selected(BankSelectorTestData.ingBank),
            BankSelectorState.Status.selected(BankSelectorTestData.rabobankBank)
        )
    }

    func test_status_differentStatuses_areNotEqual() {
        XCTAssertNotEqual(BankSelectorState.Status.loading, BankSelectorState.Status.ready)
    }

    // MARK: - State Equatable Tests

    func test_state_equalStates_areEqual() {
        let banks = BankSelectorTestData.allBanks
        let state1 = BankSelectorState(status: .ready, banks: banks, filteredBanks: banks)
        let state2 = BankSelectorState(status: .ready, banks: banks, filteredBanks: banks)
        XCTAssertEqual(state1, state2)
    }

    func test_state_differentStatus_areNotEqual() {
        let state1 = BankSelectorState(status: .loading)
        let state2 = BankSelectorState(status: .ready)
        XCTAssertNotEqual(state1, state2)
    }

    func test_state_differentSearchQuery_areNotEqual() {
        let state1 = BankSelectorState(status: .ready, searchQuery: "ING")
        let state2 = BankSelectorState(status: .ready, searchQuery: "Rabo")
        XCTAssertNotEqual(state1, state2)
    }
}

// MARK: - Test Data

@available(iOS 15.0, *)
enum BankSelectorTestData {

    static let ingBank = Bank(
        id: "INGBNL2A",
        name: "ING Bank",
        iconUrl: URL(string: "https://example.com/ing.png"),
        isDisabled: false
    )

    static let rabobankBank = Bank(
        id: "RABONL2U",
        name: "Rabobank",
        iconUrl: URL(string: "https://example.com/rabo.png"),
        isDisabled: false
    )

    static let abnAmroBank = Bank(
        id: "ABNANL2A",
        name: "ABN AMRO",
        iconUrl: nil,
        isDisabled: false
    )

    static let disabledBank = Bank(
        id: "DISABLED1",
        name: "Disabled Bank",
        iconUrl: nil,
        isDisabled: true
    )

    static let allBanks = [ingBank, rabobankBank, abnAmroBank]

    static let allBanksWithDisabled = [ingBank, rabobankBank, abnAmroBank, disabledBank]

    static let testPaymentResult = PaymentResult(
        paymentId: "test-payment-id",
        status: .success,
        token: "test-token",
        paymentMethodType: "ADYEN_IDEAL"
    )
}
