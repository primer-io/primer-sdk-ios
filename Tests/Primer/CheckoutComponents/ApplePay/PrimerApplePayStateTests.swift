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

    // MARK: - Default Initialization Tests

    func test_init_default_hasCorrectDefaults() {
        // When
        let state = PrimerApplePayState()

        // Then
        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isAvailable)
        XCTAssertNil(state.availabilityError)
        XCTAssertEqual(state.buttonStyle, .black)
        XCTAssertEqual(state.buttonType, .plain)
        XCTAssertEqual(state.cornerRadius, 8.0)
    }

    func test_init_withCustomValues_setsAllProperties() {
        // When
        let state = PrimerApplePayState(
            isLoading: true,
            isAvailable: true,
            availabilityError: "Test error",
            buttonStyle: .white,
            buttonType: .buy,
            cornerRadius: 12.0
        )

        // Then
        XCTAssertTrue(state.isLoading)
        XCTAssertTrue(state.isAvailable)
        XCTAssertEqual(state.availabilityError, "Test error")
        XCTAssertEqual(state.buttonStyle, .white)
        XCTAssertEqual(state.buttonType, .buy)
        XCTAssertEqual(state.cornerRadius, 12.0)
    }

    // MARK: - Static Factory Method Tests

    func test_default_returnsDefaultState() {
        // When
        let state = PrimerApplePayState.default

        // Then
        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isAvailable)
        XCTAssertNil(state.availabilityError)
    }

    func test_available_returnsAvailableState() {
        // When
        let state = PrimerApplePayState.available()

        // Then
        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.isAvailable)
        XCTAssertNil(state.availabilityError)
        XCTAssertEqual(state.buttonStyle, .black)
        XCTAssertEqual(state.buttonType, .plain)
        XCTAssertEqual(state.cornerRadius, 8.0)
    }

    func test_available_withCustomization_appliesCustomValues() {
        // When
        let state = PrimerApplePayState.available(
            buttonStyle: .whiteOutline,
            buttonType: .checkout,
            cornerRadius: 16.0
        )

        // Then
        XCTAssertTrue(state.isAvailable)
        XCTAssertEqual(state.buttonStyle, .whiteOutline)
        XCTAssertEqual(state.buttonType, .checkout)
        XCTAssertEqual(state.cornerRadius, 16.0)
    }

    func test_unavailable_returnsUnavailableState() {
        // Given
        let errorMessage = "Apple Pay is not supported on this device"

        // When
        let state = PrimerApplePayState.unavailable(error: errorMessage)

        // Then
        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isAvailable)
        XCTAssertEqual(state.availabilityError, errorMessage)
    }

    func test_loading_returnsLoadingState() {
        // When
        let state = PrimerApplePayState.loading

        // Then
        XCTAssertTrue(state.isLoading)
        XCTAssertTrue(state.isAvailable)
        XCTAssertNil(state.availabilityError)
    }

    // MARK: - Equatable Tests

    func test_equatable_identicalStates_areEqual() {
        // Given
        let state1 = PrimerApplePayState(
            isLoading: true,
            isAvailable: true,
            availabilityError: nil,
            buttonStyle: .black,
            buttonType: .plain,
            cornerRadius: 8.0
        )
        let state2 = PrimerApplePayState(
            isLoading: true,
            isAvailable: true,
            availabilityError: nil,
            buttonStyle: .black,
            buttonType: .plain,
            cornerRadius: 8.0
        )

        // Then
        XCTAssertEqual(state1, state2)
    }

    func test_equatable_differentStates_areNotEqual() {
        // Given
        let state1 = PrimerApplePayState.available()
        let state2 = PrimerApplePayState.loading

        // Then
        XCTAssertNotEqual(state1, state2)
    }
}
