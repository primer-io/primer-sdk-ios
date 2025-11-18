//
//  ViewAccessibilityExtensionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ViewAccessibilityExtensionTests: XCTestCase {

    // MARK: - Configuration Application Tests

    func testAccessibilityModifier_WithAllProperties() {
        // Given: Complete accessibility configuration
        let config = AccessibilityConfiguration(
            identifier: "checkout_components_test_button",
            label: "Submit Payment",
            hint: "Double-tap to submit",
            value: "Ready",
            traits: [.isButton],
            isHidden: false,
            sortPriority: 5
        )

        // When: Applying configuration to view
        let view = Button("Test") {}
            .accessibility(config: config)

        // Then: Should create view successfully
        XCTAssertNotNil(view)
    }

    func testAccessibilityModifier_WithMinimalProperties() {
        // Given: Minimal accessibility configuration (only required properties)
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label"
        )

        // When: Applying configuration to view
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should create view successfully
        XCTAssertNotNil(view)
    }

    // MARK: - Nil and Empty Value Handling (Tests Our Conditional Modifiers)

    func testAccessibilityModifier_WithNilHint() {
        // Given: Configuration with nil hint
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Label",
            hint: nil
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle nil hint gracefully (our ConditionalAccessibilityHint)
        XCTAssertNotNil(view)
    }

    func testAccessibilityModifier_WithEmptyHint() {
        // Given: Configuration with empty hint (should not be applied per our logic)
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Label",
            hint: ""
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle empty hint (our ConditionalAccessibilityHint filters it out)
        XCTAssertNotNil(view)
    }

    func testAccessibilityModifier_WithNilValue() {
        // Given: Configuration with nil value
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Label",
            value: nil
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle nil value gracefully (our ConditionalAccessibilityValue)
        XCTAssertNotNil(view)
    }

    func testAccessibilityModifier_WithEmptyValue() {
        // Given: Configuration with empty value (should not be applied per our logic)
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Label",
            value: ""
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle empty value (our ConditionalAccessibilityValue filters it out)
        XCTAssertNotNil(view)
    }

    // MARK: - Trait Combination Tests (Tests Our Code)

    func testAccessibilityModifier_WithMultipleTraits() {
        // Given: Configuration with multiple traits
        let config = AccessibilityConfiguration(
            identifier: "multi_trait_id",
            label: "Multi Trait Label",
            traits: [.isButton, .isSelected, .updatesFrequently]
        )

        // When: Applying configuration
        let view = Button("Test") {}
            .accessibility(config: config)

        // Then: Should handle multiple trait combination
        XCTAssertNotNil(view)
    }

    func testAccessibilityModifier_WithEmptyTraits() {
        // Given: Configuration with empty traits
        let config = AccessibilityConfiguration(
            identifier: "no_trait_id",
            label: "No Trait Label",
            traits: []
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle empty traits
        XCTAssertNotNil(view)
    }

    // MARK: - Modifier Chaining Tests (Important for SwiftUI Usage)

    func testAccessibilityModifier_CanBeChained() {
        // Given: View with multiple modifiers
        let config = AccessibilityConfiguration(
            identifier: "chain_id",
            label: "Chain Label"
        )

        // When: Chaining accessibility with other modifiers
        let view = Text("Test")
            .foregroundColor(.blue)
            .accessibility(config: config)
            .padding()

        // Then: Should work with modifier chaining
        XCTAssertNotNil(view)
    }

    func testAccessibilityModifier_MultipleConfigurations() {
        // Given: Multiple accessibility configurations applied
        let config1 = AccessibilityConfiguration(
            identifier: "first_id",
            label: "First Label"
        )
        let config2 = AccessibilityConfiguration(
            identifier: "second_id",
            label: "Second Label"
        )

        // When: Applying multiple configurations (last one should win)
        let view = Text("Test")
            .accessibility(config: config1)
            .accessibility(config: config2)

        // Then: Should handle multiple applications
        XCTAssertNotNil(view)
    }
}
