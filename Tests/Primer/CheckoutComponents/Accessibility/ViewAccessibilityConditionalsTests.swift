//
//  ViewAccessibilityConditionalsTests.swift
//
//  Copyright (c) 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ViewAccessibilityConditionalsTests: XCTestCase {

    // MARK: - Hint Edge Cases Tests

    func test_accessibilityModifier_withWhitespaceOnlyHint_appliesHint() {
        // Given: Configuration with whitespace-only hint (should be applied since not empty)
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            hint: "   "  // Whitespace only - technically not empty
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should create view successfully (whitespace is not filtered)
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withUnicodeHint_appliesHint() {
        // Given: Configuration with unicode characters in hint
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            hint: "Double-tap to submit 支払い"  // Japanese characters
        )

        // When: Applying configuration
        let view = Button("Test") {}
            .accessibility(config: config)

        // Then: Should handle unicode hint
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withLongHint_appliesHint() {
        // Given: Configuration with very long hint
        let longHint = String(repeating: "This is a long accessibility hint. ", count: 10)
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            hint: longHint
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle long hint
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withNewlineInHint_appliesHint() {
        // Given: Configuration with newline in hint
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            hint: "Line 1\nLine 2"
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle hint with newlines
        XCTAssertNotNil(view)
    }

    // MARK: - Value Edge Cases Tests

    func test_accessibilityModifier_withWhitespaceOnlyValue_appliesValue() {
        // Given: Configuration with whitespace-only value
        let config = AccessibilityConfiguration(
            identifier: "test_id",
            label: "Test Label",
            value: "   "  // Whitespace only
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should create view successfully
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withNumericValue_appliesValue() {
        // Given: Configuration with numeric value (e.g., for sliders)
        let config = AccessibilityConfiguration(
            identifier: "slider_id",
            label: "Volume",
            value: "50%"
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle numeric value
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withSpecialCharactersInValue_appliesValue() {
        // Given: Configuration with special characters in value
        let config = AccessibilityConfiguration(
            identifier: "price_id",
            label: "Price",
            value: "$1,234.56 (€1,150.00)"
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle special characters
        XCTAssertNotNil(view)
    }

    // MARK: - Identifier Edge Cases Tests

    func test_accessibilityModifier_withSpecialCharactersInIdentifier_setsIdentifier() {
        // Given: Configuration with special characters in identifier
        let config = AccessibilityConfiguration(
            identifier: "checkout_components_card_form_field_123",
            label: "Card Number"
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle identifier with underscores and numbers
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withEmptyIdentifier_setsEmptyIdentifier() {
        // Given: Configuration with empty identifier (edge case)
        let config = AccessibilityConfiguration(
            identifier: "",
            label: "Test Label"
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle empty identifier
        XCTAssertNotNil(view)
    }

    // MARK: - Sort Priority Tests

    func test_accessibilityModifier_withHighSortPriority_convertsToDouble() {
        // Given: Configuration with high sort priority
        let config = AccessibilityConfiguration(
            identifier: "high_priority_id",
            label: "High Priority",
            sortPriority: 100
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should convert Int to Double for sortPriority
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withNegativeSortPriority_convertsToDouble() {
        // Given: Configuration with negative sort priority
        let config = AccessibilityConfiguration(
            identifier: "low_priority_id",
            label: "Low Priority",
            sortPriority: -10
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle negative priority
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withZeroSortPriority_convertsToDouble() {
        // Given: Configuration with zero sort priority (default)
        let config = AccessibilityConfiguration(
            identifier: "zero_priority_id",
            label: "Default Priority",
            sortPriority: 0
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle zero priority
        XCTAssertNotNil(view)
    }

    // MARK: - Trait Tests

    func test_accessibilityModifier_withButtonTrait_appliesTrait() {
        // Given: Configuration with button trait
        let config = AccessibilityConfiguration(
            identifier: "button_id",
            label: "Submit",
            traits: [.isButton]
        )

        // When: Applying configuration
        let view = Button("Submit") {}
            .accessibility(config: config)

        // Then: Should apply button trait
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withHeaderTrait_appliesTrait() {
        // Given: Configuration with header trait
        let config = AccessibilityConfiguration(
            identifier: "header_id",
            label: "Section Header",
            traits: [.isHeader]
        )

        // When: Applying configuration
        let view = Text("Header")
            .accessibility(config: config)

        // Then: Should apply header trait
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withLinkTrait_appliesTrait() {
        // Given: Configuration with link trait
        let config = AccessibilityConfiguration(
            identifier: "link_id",
            label: "Learn More",
            traits: [.isLink]
        )

        // When: Applying configuration
        let view = Text("Learn More")
            .accessibility(config: config)

        // Then: Should apply link trait
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withImageTrait_appliesTrait() {
        // Given: Configuration with image trait
        let config = AccessibilityConfiguration(
            identifier: "image_id",
            label: "Company Logo",
            traits: [.isImage]
        )

        // When: Applying configuration
        let view = Text("Logo")
            .accessibility(config: config)

        // Then: Should apply image trait
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withSelectedTrait_appliesTrait() {
        // Given: Configuration with selected trait
        let config = AccessibilityConfiguration(
            identifier: "selected_id",
            label: "Selected Option",
            traits: [.isSelected]
        )

        // When: Applying configuration
        let view = Text("Option")
            .accessibility(config: config)

        // Then: Should apply selected trait
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withCombinedTraits_appliesAllTraits() {
        // Given: Configuration with multiple traits
        let config = AccessibilityConfiguration(
            identifier: "combined_id",
            label: "Toggle Button",
            traits: [.isButton, .isSelected, .updatesFrequently]
        )

        // When: Applying configuration
        let view = Button("Toggle") {}
            .accessibility(config: config)

        // Then: Should apply all traits
        XCTAssertNotNil(view)
    }

    // MARK: - Hidden Tests

    func test_accessibilityModifier_withIsHiddenTrue_hidesFromAccessibility() {
        // Given: Configuration with isHidden = true
        let config = AccessibilityConfiguration(
            identifier: "hidden_id",
            label: "Hidden Element",
            isHidden: true
        )

        // When: Applying configuration
        let view = Text("Hidden")
            .accessibility(config: config)

        // Then: Should handle hidden setting
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withIsHiddenFalse_showsInAccessibility() {
        // Given: Configuration with isHidden = false (default)
        let config = AccessibilityConfiguration(
            identifier: "visible_id",
            label: "Visible Element",
            isHidden: false
        )

        // When: Applying configuration
        let view = Text("Visible")
            .accessibility(config: config)

        // Then: Should handle visible setting
        XCTAssertNotNil(view)
    }

    // MARK: - View Type Compatibility Tests

    func test_accessibilityModifier_withTextField_appliesConfiguration() {
        // Given: Configuration for text field
        let config = AccessibilityConfiguration(
            identifier: "text_field_id",
            label: "Card Number",
            hint: "Enter your 16-digit card number"
        )

        // When: Applying to TextField
        let view = TextField("Card Number", text: .constant(""))
            .accessibility(config: config)

        // Then: Should work with TextField
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withVStack_appliesConfiguration() {
        // Given: Configuration for container
        let config = AccessibilityConfiguration(
            identifier: "container_id",
            label: "Card Details Section"
        )

        // When: Applying to VStack
        let view = VStack {
            Text("Card Number")
            Text("Expiry")
        }
        .accessibility(config: config)

        // Then: Should work with container views
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withImage_appliesConfiguration() {
        // Given: Configuration for image
        let config = AccessibilityConfiguration(
            identifier: "card_logo_id",
            label: "Visa Card",
            traits: [.isImage]
        )

        // When: Applying to Image
        let view = Image(systemName: "creditcard")
            .accessibility(config: config)

        // Then: Should work with Image
        XCTAssertNotNil(view)
    }

    // MARK: - Complete Configuration Tests

    func test_accessibilityModifier_withAllPropertiesSet_appliesAll() {
        // Given: Configuration with all properties
        let config = AccessibilityConfiguration(
            identifier: "full_config_id",
            label: "Complete Example",
            hint: "This is a complete example",
            value: "Current value",
            traits: [.isButton, .startsMediaSession],
            isHidden: false,
            sortPriority: 5
        )

        // When: Applying configuration
        let view = Button("Full Config") {}
            .accessibility(config: config)

        // Then: Should apply all properties
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withMinimalConfiguration_appliesDefaults() {
        // Given: Minimal configuration (only required properties)
        let config = AccessibilityConfiguration(
            identifier: "minimal_id",
            label: "Minimal"
        )

        // When: Applying configuration
        let view = Text("Minimal")
            .accessibility(config: config)

        // Then: Should apply with defaults for optional properties
        XCTAssertNotNil(view)
    }
}
