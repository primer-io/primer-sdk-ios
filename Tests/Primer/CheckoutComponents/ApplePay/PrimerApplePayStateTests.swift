//
//  PrimerApplePayStateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class PrimerApplePayStateTests: XCTestCase {

    // MARK: - Default State

    func test_default_hasExpectedValues() {
        let state = PrimerApplePayState.default

        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isAvailable)
        XCTAssertNil(state.availabilityError)
        XCTAssertEqual(state.buttonStyle, .black)
        XCTAssertEqual(state.buttonType, .plain)
        XCTAssertEqual(state.cornerRadius, 8.0)
    }

    // MARK: - Available Factory

    func test_available_withDefaults_isAvailableNotLoading() {
        let state = PrimerApplePayState.available()

        XCTAssertTrue(state.isAvailable)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.availabilityError)
    }

    func test_available_withCustomValues_appliesAllParameters() {
        let state = PrimerApplePayState.available(
            buttonStyle: .white,
            buttonType: .buy,
            cornerRadius: 12.0
        )

        XCTAssertTrue(state.isAvailable)
        XCTAssertEqual(state.buttonStyle, .white)
        XCTAssertEqual(state.buttonType, .buy)
        XCTAssertEqual(state.cornerRadius, 12.0)
    }

    // MARK: - Unavailable Factory

    func test_unavailable_setsErrorAndNotAvailable() {
        let state = PrimerApplePayState.unavailable(error: "Apple Pay is not configured")

        XCTAssertFalse(state.isAvailable)
        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.availabilityError, "Apple Pay is not configured")
    }

    // MARK: - Loading Factory

    func test_loading_isLoadingAndAvailable() {
        let state = PrimerApplePayState.loading

        XCTAssertTrue(state.isLoading)
        XCTAssertTrue(state.isAvailable)
        XCTAssertNil(state.availabilityError)
    }

    // MARK: - Equality

    func test_equality_sameStates_areEqual() {
        let state1 = PrimerApplePayState.default
        let state2 = PrimerApplePayState.default

        XCTAssertEqual(state1, state2)
    }

    func test_equality_differentStates_areNotEqual() {
        let state1 = PrimerApplePayState.default
        let state2 = PrimerApplePayState.loading

        XCTAssertNotEqual(state1, state2)
    }
}
