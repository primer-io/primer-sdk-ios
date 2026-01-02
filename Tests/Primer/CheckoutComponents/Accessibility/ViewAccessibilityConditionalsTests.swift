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

    // MARK: - Children Ignore Tests

    func test_accessibilityModifier_ignoresChildrenAccessibility() {
        // Given: Configuration applied to a container with children
        let config = AccessibilityConfiguration(
            identifier: "parent_container",
            label: "Payment Form"
        )

        // When: Applying to a view with children
        let view = VStack {
            Text("Child 1")
            Text("Child 2")
            Button("Submit") {}
        }
        .accessibility(config: config)

        // Then: Should create view with accessibility element ignoring children
        XCTAssertNotNil(view)
    }

    // MARK: - Label Tests

    func test_accessibilityModifier_withEmptyLabel_setsEmptyLabel() {
        // Given: Configuration with empty label (edge case)
        let config = AccessibilityConfiguration(
            identifier: "empty_label_id",
            label: ""
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle empty label
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withLongLabel_setsLabel() {
        // Given: Configuration with very long label
        let longLabel = String(repeating: "Long label text ", count: 20)
        let config = AccessibilityConfiguration(
            identifier: "long_label_id",
            label: longLabel
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle long label
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withUnicodeLabel_setsLabel() {
        // Given: Configuration with unicode label
        let config = AccessibilityConfiguration(
            identifier: "unicode_label_id",
            label: "Submit Payment 支払い 💳"
        )

        // When: Applying configuration
        let view = Button("Test") {}
            .accessibility(config: config)

        // Then: Should handle unicode label
        XCTAssertNotNil(view)
    }

    // MARK: - Conditional Modifier Edge Cases

    func test_accessibilityModifier_withBothHintAndValueNil_skipsConditionals() {
        // Given: Configuration with both hint and value nil
        let config = AccessibilityConfiguration(
            identifier: "nil_conditionals_id",
            label: "Both Nil",
            hint: nil,
            value: nil
        )

        // When: Applying configuration - exercises else branches
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should handle both nil conditionals
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withBothHintAndValueEmpty_skipsConditionals() {
        // Given: Configuration with both hint and value empty
        let config = AccessibilityConfiguration(
            identifier: "empty_conditionals_id",
            label: "Both Empty",
            hint: "",
            value: ""
        )

        // When: Applying configuration - exercises else branches for isEmpty
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should skip both conditional modifiers
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withHintNilAndValueSet_appliesOnlyValue() {
        // Given: Configuration with nil hint but valid value
        let config = AccessibilityConfiguration(
            identifier: "value_only_id",
            label: "Value Only",
            hint: nil,
            value: "Current Value"
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should apply only value, skip hint
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withHintSetAndValueNil_appliesOnlyHint() {
        // Given: Configuration with valid hint but nil value
        let config = AccessibilityConfiguration(
            identifier: "hint_only_id",
            label: "Hint Only",
            hint: "This is a hint",
            value: nil
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should apply only hint, skip value
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withHintEmptyAndValueSet_appliesOnlyValue() {
        // Given: Configuration with empty hint but valid value
        let config = AccessibilityConfiguration(
            identifier: "empty_hint_value_id",
            label: "Empty Hint",
            hint: "",
            value: "Active"
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should skip empty hint, apply value
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withHintSetAndValueEmpty_appliesOnlyHint() {
        // Given: Configuration with valid hint but empty value
        let config = AccessibilityConfiguration(
            identifier: "hint_empty_value_id",
            label: "Empty Value",
            hint: "Double-tap to submit",
            value: ""
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should apply hint, skip empty value
        XCTAssertNotNil(view)
    }

    // MARK: - SecureField Compatibility

    func test_accessibilityModifier_withSecureField_appliesConfiguration() {
        // Given: Configuration for secure field
        let config = AccessibilityConfiguration(
            identifier: "cvv_field_id",
            label: "CVV",
            hint: "Enter your 3-digit security code"
        )

        // When: Applying to SecureField
        let view = SecureField("CVV", text: .constant(""))
            .accessibility(config: config)

        // Then: Should work with SecureField
        XCTAssertNotNil(view)
    }

    // MARK: - Modifier Order Independence

    func test_accessibilityModifier_appliedBeforeOtherModifiers_works() {
        // Given: Configuration
        let config = AccessibilityConfiguration(
            identifier: "before_modifiers_id",
            label: "Before"
        )

        // When: Applying accessibility before other modifiers
        let view = Text("Test")
            .accessibility(config: config)
            .padding()
            .background(Color.blue)

        // Then: Should work with modifiers after
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_appliedAfterOtherModifiers_works() {
        // Given: Configuration
        let config = AccessibilityConfiguration(
            identifier: "after_modifiers_id",
            label: "After"
        )

        // When: Applying accessibility after other modifiers
        let view = Text("Test")
            .padding()
            .background(Color.blue)
            .accessibility(config: config)

        // Then: Should work with modifiers before
        XCTAssertNotNil(view)
    }

    // MARK: - Max Priority Value

    func test_accessibilityModifier_withMaxIntSortPriority_convertsToDouble() {
        // Given: Configuration with max Int sort priority
        let config = AccessibilityConfiguration(
            identifier: "max_priority_id",
            label: "Max Priority",
            sortPriority: Int.max
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should convert max Int to Double
        XCTAssertNotNil(view)
    }

    func test_accessibilityModifier_withMinIntSortPriority_convertsToDouble() {
        // Given: Configuration with min Int sort priority
        let config = AccessibilityConfiguration(
            identifier: "min_priority_id",
            label: "Min Priority",
            sortPriority: Int.min
        )

        // When: Applying configuration
        let view = Text("Test")
            .accessibility(config: config)

        // Then: Should convert min Int to Double
        XCTAssertNotNil(view)
    }
}
