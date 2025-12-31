//
//  PrimerEnvironmentTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for PrimerEnvironment keys and EnvironmentValues extensions.
@available(iOS 15.0, *)
final class PrimerEnvironmentTests: XCTestCase {

    // MARK: - primerCheckoutScope Tests

    func test_primerCheckoutScope_defaultValue_isNil() {
        // Given
        let environmentValues = EnvironmentValues()

        // Then
        XCTAssertNil(environmentValues.primerCheckoutScope)
    }

    func test_primerCheckoutScope_getterSetter_works() {
        // Given
        var environmentValues = EnvironmentValues()

        // When - verify getter works
        let initialValue = environmentValues.primerCheckoutScope

        // Then
        XCTAssertNil(initialValue)
    }

    // MARK: - primerCardFormScope Tests

    func test_primerCardFormScope_defaultValue_isNil() {
        // Given
        let environmentValues = EnvironmentValues()

        // Then
        XCTAssertNil(environmentValues.primerCardFormScope)
    }

    func test_primerCardFormScope_getterSetter_works() {
        // Given
        var environmentValues = EnvironmentValues()

        // When - verify getter works
        let initialValue = environmentValues.primerCardFormScope

        // Then
        XCTAssertNil(initialValue)
    }

    // MARK: - primerPaymentMethodSelectionScope Tests

    func test_primerPaymentMethodSelectionScope_defaultValue_isNil() {
        // Given
        let environmentValues = EnvironmentValues()

        // Then
        XCTAssertNil(environmentValues.primerPaymentMethodSelectionScope)
    }

    func test_primerPaymentMethodSelectionScope_getterSetter_works() {
        // Given
        var environmentValues = EnvironmentValues()

        // When - verify getter works
        let initialValue = environmentValues.primerPaymentMethodSelectionScope

        // Then
        XCTAssertNil(initialValue)
    }

    // MARK: - primerSelectCountryScope Tests

    func test_primerSelectCountryScope_defaultValue_isNil() {
        // Given
        let environmentValues = EnvironmentValues()

        // Then
        XCTAssertNil(environmentValues.primerSelectCountryScope)
    }

    func test_primerSelectCountryScope_getterSetter_works() {
        // Given
        var environmentValues = EnvironmentValues()

        // When - verify getter works
        let initialValue = environmentValues.primerSelectCountryScope

        // Then
        XCTAssertNil(initialValue)
    }
}
