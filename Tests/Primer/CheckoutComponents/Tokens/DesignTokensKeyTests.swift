//
//  DesignTokensKeyTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for DesignTokensKey environment key functionality.
@available(iOS 15.0, *)
final class DesignTokensKeyTests: XCTestCase {

    // MARK: - Default Value Tests

    func test_defaultValue_isNil() {
        // Given
        let defaultValue = DesignTokensKey.defaultValue

        // Then
        XCTAssertNil(defaultValue)
    }

    // MARK: - EnvironmentValues Tests

    func test_environmentValues_getDesignTokens_defaultIsNil() {
        // Given
        var environmentValues = EnvironmentValues()

        // When
        let tokens = environmentValues.designTokens

        // Then
        XCTAssertNil(tokens)
    }

    func test_environmentValues_setDesignTokens_updatesValue() {
        // Given
        var environmentValues = EnvironmentValues()
        let tokens = DesignTokens()

        // When
        environmentValues.designTokens = tokens

        // Then
        XCTAssertNotNil(environmentValues.designTokens)
    }

    func test_environmentValues_setDesignTokens_toNil_clearsValue() {
        // Given
        var environmentValues = EnvironmentValues()
        environmentValues.designTokens = DesignTokens()

        // When
        environmentValues.designTokens = nil

        // Then
        XCTAssertNil(environmentValues.designTokens)
    }
}
