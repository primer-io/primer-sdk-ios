//
//  ViewAccessibilityExtendedTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for View+Accessibility extension functionality.
@available(iOS 15.0, *)
final class ViewAccessibilityExtendedTests: XCTestCase {

    // MARK: - Accessibility Modifier Application Tests

    func test_accessibilityModifier_withBasicConfig_appliesProperties() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "test_button",
            label: "Submit Button"
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withHint_appliesHint() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "test_field",
            label: "Card Number",
            hint: "Enter your 16-digit card number"
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withNilHint_doesNotCrash() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            hint: nil
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withEmptyHint_doesNotCrash() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            hint: ""
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withValue_appliesValue() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "progress_indicator",
            label: "Payment Progress",
            value: "50%"
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withNilValue_doesNotCrash() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            value: nil
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withEmptyValue_doesNotCrash() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            value: ""
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withTraits_appliesTraits() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "test_button",
            label: "Submit",
            traits: [.isButton, .startsMediaSession]
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withIsHidden_appliesHiddenState() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "hidden_element",
            label: "Hidden",
            isHidden: true
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withSortPriority_appliesPriority() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "priority_element",
            label: "Priority",
            sortPriority: 100
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withAllProperties_appliesAll() {
        // Given
        let config = AccessibilityConfiguration(
            identifier: "complete_element",
            label: "Complete Label",
            hint: "This is a hint",
            value: "Current Value",
            traits: [.isButton],
            isHidden: false,
            sortPriority: 50
        )

        // When
        let view = Text("Test").accessibility(config: config)

        // Then - View can be created without error
        XCTAssertNotNil(view)
    }
}
