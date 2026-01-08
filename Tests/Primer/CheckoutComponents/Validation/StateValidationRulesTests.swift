//
//  StateValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class StateValidationRulesTests: XCTestCase {

    // MARK: - State Validation Tests

    func test_validateState_withValidState_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .state, isRequired: true)
        let state = TestData.States.validFullName

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateState_withStateRule_allowsAbbreviation() {
        // Given
        let rule = StateRule()
        let state = TestData.States.validAbbreviation

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateState_withEmpty_returnsInvalid() {
        // Given
        let rule = StateRule()
        let state = TestData.States.empty

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateState_withSingleChar_returnsInvalid() {
        // Given
        let rule = StateRule()
        let state = TestData.States.singleCharacter

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertFalse(result.isValid)
    }
}
