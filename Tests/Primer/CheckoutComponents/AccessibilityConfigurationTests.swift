//
//  AccessibilityConfigurationTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

@available(iOS 15.0, *)
final class AccessibilityConfigurationTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitWithAllProperties() {
        // Given: All properties for AccessibilityConfiguration
        let identifier = "checkout_components_test_identifier"
        let label = "Test Label"
        let hint = "Test Hint"
        let value = "Test Value"
        let traits: SwiftUI.AccessibilityTraits = [.isButton, .isSelected]
        let isHidden = true
        let sortPriority = 5

        // When: Creating configuration with all properties
        let config = AccessibilityConfiguration(
            identifier: identifier,
            label: label,
            hint: hint,
            value: value,
            traits: traits,
            isHidden: isHidden,
            sortPriority: sortPriority
        )

        // Then: All properties should be set correctly
        XCTAssertEqual(config.identifier, identifier)
        XCTAssertEqual(config.label, label)
        XCTAssertEqual(config.hint, hint)
        XCTAssertEqual(config.value, value)
        XCTAssertEqual(config.traits, traits)
        XCTAssertEqual(config.isHidden, isHidden)
        XCTAssertEqual(config.sortPriority, sortPriority)
    }

    func testInitWithMinimalProperties() {
        // Given: Only required properties
        let identifier = "checkout_components_test_identifier"
        let label = "Test Label"

        // When: Creating configuration with default optional values
        let config = AccessibilityConfiguration(
            identifier: identifier,
            label: label
        )

        // Then: Required properties set, optional properties use defaults
        XCTAssertEqual(config.identifier, identifier)
        XCTAssertEqual(config.label, label)
        XCTAssertNil(config.hint)
        XCTAssertNil(config.value)
        XCTAssertEqual(config.traits, [])
        XCTAssertEqual(config.isHidden, false)
        XCTAssertEqual(config.sortPriority, 0)
    }

    // MARK: - Equatable Tests (Important - Used in Code)

    func testEquatable_IdenticalConfigurations() {
        // Given: Two identical configurations
        let config1 = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            hint: "Test Hint",
            value: "Test Value",
            traits: [.isButton],
            isHidden: false,
            sortPriority: 0
        )

        let config2 = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            hint: "Test Hint",
            value: "Test Value",
            traits: [.isButton],
            isHidden: false,
            sortPriority: 0
        )

        // When: Comparing configurations
        let areEqual = config1 == config2

        // Then: Configurations should be equal
        XCTAssertTrue(areEqual)
    }

    func testEquatable_DifferentIdentifiers() {
        // Given: Two configurations with different identifiers
        let config1 = AccessibilityConfiguration(
            identifier: "test_id_1",
            label: "Test Label"
        )

        let config2 = AccessibilityConfiguration(
            identifier: "test_id_2",
            label: "Test Label"
        )

        // When: Comparing configurations
        let areEqual = config1 == config2

        // Then: Configurations should not be equal
        XCTAssertFalse(areEqual)
    }

    func testEquatable_DifferentLabels() {
        // Given: Two configurations with different labels
        let config1 = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Label 1"
        )

        let config2 = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Label 2"
        )

        // When: Comparing configurations
        let areEqual = config1 == config2

        // Then: Configurations should not be equal
        XCTAssertFalse(areEqual)
    }

    func testEquatable_DifferentTraits() {
        // Given: Two configurations with different traits
        let config1 = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            traits: [.isButton]
        )

        let config2 = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            traits: [.isHeader]
        )

        // When: Comparing configurations
        let areEqual = config1 == config2

        // Then: Configurations should not be equal
        XCTAssertFalse(areEqual)
    }

    // MARK: - Traits Tests

    func testTraits_MultipleTraits() {
        // Given: Configuration with multiple traits
        let traits: SwiftUI.AccessibilityTraits = [.isButton, .isSelected, .updatesFrequently]
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            traits: traits
        )

        // When: Accessing traits
        let configTraits = config.traits

        // Then: All traits should be preserved
        XCTAssertEqual(configTraits, traits)
    }

    func testTraits_EmptyTraits() {
        // Given: Configuration with empty traits
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            traits: []
        )

        // When: Accessing traits
        let configTraits = config.traits

        // Then: Traits should be empty
        XCTAssertEqual(configTraits, [])
    }
}
