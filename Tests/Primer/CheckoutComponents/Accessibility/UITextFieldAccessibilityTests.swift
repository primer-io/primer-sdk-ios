//
//  UITextFieldAccessibilityTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

/// VoiceOver focuses the text field inside a card form field, so the field's name, error and hint have to be on it.
final class UITextFieldAccessibilityTests: XCTestCase {

  func test_applyAccessibility_readsTheNameErrorAndHint() {
    let textField = UITextField()

    textField.applyAccessibility(
      AccessibilityConfiguration(identifier: "field", label: "Card number", hint: "Enter the card number", value: "Invalid card number")
    )

    XCTAssertEqual(textField.accessibilityLabel, "Card number, Invalid card number")
    XCTAssertEqual(textField.accessibilityHint, "Enter the card number")
  }

  func test_applyAccessibility_errorCleared_readsTheNameOnly() {
    let textField = UITextField()
    textField.applyAccessibility(AccessibilityConfiguration(identifier: "field", label: "Card number", value: "Invalid card number"))

    textField.applyAccessibility(AccessibilityConfiguration(identifier: "field", label: "Card number"))

    XCTAssertEqual(textField.accessibilityLabel, "Card number")
  }
}
