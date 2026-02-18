//
//  PrimerKlarnaStateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class KlarnaStateTests: XCTestCase {

    // MARK: - Default Initialization Tests

    func test_defaultInit_stepIsLoading() {
        let state = PrimerKlarnaState()
        XCTAssertEqual(state.step, .loading)
    }

    func test_defaultInit_categoriesIsEmpty() {
        let state = PrimerKlarnaState()
        XCTAssertTrue(state.categories.isEmpty)
    }

    func test_defaultInit_selectedCategoryIdIsNil() {
        let state = PrimerKlarnaState()
        XCTAssertNil(state.selectedCategoryId)
    }

    // MARK: - Custom Initialization Tests

    func test_customInit_setsStep() {
        let state = PrimerKlarnaState(step: .categorySelection)
        XCTAssertEqual(state.step, .categorySelection)
    }

    func test_customInit_setsCategories() {
        let categories = KlarnaTestData.allCategories
        let state = PrimerKlarnaState(categories: categories)
        XCTAssertEqual(state.categories.count, 3)
    }

    func test_customInit_setsSelectedCategoryId() {
        let state = PrimerKlarnaState(selectedCategoryId: KlarnaTestData.Constants.categoryPayNow)
        XCTAssertEqual(state.selectedCategoryId, KlarnaTestData.Constants.categoryPayNow)
    }

    func test_customInit_allParameters() {
        let categories = [KlarnaTestData.payNowCategory]
        let state = PrimerKlarnaState(
            step: .viewReady,
            categories: categories,
            selectedCategoryId: KlarnaTestData.Constants.categoryPayNow
        )

        XCTAssertEqual(state.step, .viewReady)
        XCTAssertEqual(state.categories.count, 1)
        XCTAssertEqual(state.selectedCategoryId, KlarnaTestData.Constants.categoryPayNow)
    }

    // MARK: - Step Equatable Tests

    func test_step_loading_isEquatable() {
        XCTAssertEqual(PrimerKlarnaState.Step.loading, PrimerKlarnaState.Step.loading)
    }

    func test_step_categorySelection_isEquatable() {
        XCTAssertEqual(PrimerKlarnaState.Step.categorySelection, PrimerKlarnaState.Step.categorySelection)
    }

    func test_step_viewReady_isEquatable() {
        XCTAssertEqual(PrimerKlarnaState.Step.viewReady, PrimerKlarnaState.Step.viewReady)
    }

    func test_step_authorizationStarted_isEquatable() {
        XCTAssertEqual(PrimerKlarnaState.Step.authorizationStarted, PrimerKlarnaState.Step.authorizationStarted)
    }

    func test_step_awaitingFinalization_isEquatable() {
        XCTAssertEqual(PrimerKlarnaState.Step.awaitingFinalization, PrimerKlarnaState.Step.awaitingFinalization)
    }

    func test_step_differentSteps_areNotEqual() {
        XCTAssertNotEqual(PrimerKlarnaState.Step.loading, PrimerKlarnaState.Step.categorySelection)
        XCTAssertNotEqual(PrimerKlarnaState.Step.viewReady, PrimerKlarnaState.Step.authorizationStarted)
        XCTAssertNotEqual(PrimerKlarnaState.Step.awaitingFinalization, PrimerKlarnaState.Step.loading)
    }

    // MARK: - State Equatable Tests

    func test_state_equalStates_areEqual() {
        let categories = KlarnaTestData.allCategories
        let state1 = PrimerKlarnaState(step: .categorySelection, categories: categories, selectedCategoryId: "pay_now")
        let state2 = PrimerKlarnaState(step: .categorySelection, categories: categories, selectedCategoryId: "pay_now")
        XCTAssertEqual(state1, state2)
    }

    func test_state_differentSteps_areNotEqual() {
        let state1 = PrimerKlarnaState(step: .loading)
        let state2 = PrimerKlarnaState(step: .categorySelection)
        XCTAssertNotEqual(state1, state2)
    }

    func test_state_differentSelectedCategory_areNotEqual() {
        let categories = KlarnaTestData.allCategories
        let state1 = PrimerKlarnaState(step: .categorySelection, categories: categories, selectedCategoryId: "pay_now")
        let state2 = PrimerKlarnaState(step: .categorySelection, categories: categories, selectedCategoryId: "pay_later")
        XCTAssertNotEqual(state1, state2)
    }

    func test_state_differentCategories_areNotEqual() {
        let state1 = PrimerKlarnaState(step: .categorySelection, categories: [KlarnaTestData.payNowCategory])
        let state2 = PrimerKlarnaState(step: .categorySelection, categories: KlarnaTestData.allCategories)
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Initialization Overwrite Tests

    func test_state_canBeCreatedWithNewStep() {
        let state = PrimerKlarnaState(step: .viewReady)
        XCTAssertEqual(state.step, .viewReady)
    }

    func test_state_canBeCreatedWithNewCategories() {
        let state = PrimerKlarnaState(categories: KlarnaTestData.allCategories)
        XCTAssertEqual(state.categories.count, 3)
    }

    func test_state_canBeCreatedWithNewSelectedCategoryId() {
        let state = PrimerKlarnaState(selectedCategoryId: KlarnaTestData.Constants.categoryPayNow)
        XCTAssertEqual(state.selectedCategoryId, KlarnaTestData.Constants.categoryPayNow)
    }
}
