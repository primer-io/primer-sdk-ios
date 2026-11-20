//
//  AccessibilityConfigurationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

/// Before iOS 18 a field's error is read with its label, so VoiceOver still finds it after the first announcement.
final class AccessibilityConfigurationTests: XCTestCase {

  func test_labelWithValue_readsTheValueAfterTheLabel() {
    let config = AccessibilityConfiguration(identifier: "field", label: "Card number", value: "Invalid card number")

    XCTAssertEqual(config.labelWithValue, "Card number, Invalid card number")
  }

  func test_labelWithValue_withoutAValue_isTheLabel() {
    XCTAssertEqual(AccessibilityConfiguration(identifier: "field", label: "Card number").labelWithValue, "Card number")
    XCTAssertEqual(AccessibilityConfiguration(identifier: "field", label: "Card number", value: "").labelWithValue, "Card number")
  }

  func test_submitButton_enabled_isNamedByItsTitleWithNoHintOrValue() {
    let config = submitButton(isEnabled: true, isLoading: false)

    XCTAssertEqual(config.label, "Pay")
    XCTAssertNil(config.hint)
    XCTAssertNil(config.value)
  }

  func test_submitButton_disabled_hintsWhyItCannotBePressed() {
    let config = submitButton(isEnabled: false, isLoading: false)

    XCTAssertEqual(config.label, "Pay")
    XCTAssertEqual(config.hint, CheckoutComponentsStrings.a11ySubmitButtonDisabled)
    XCTAssertNil(config.value)
  }

  func test_submitButton_loading_keepsItsTitleAndReadsProcessingAsItsValue() {
    for isEnabled in [true, false] {
      let config = submitButton(isEnabled: isEnabled, isLoading: true)

      XCTAssertEqual(config.label, "Pay")
      XCTAssertNil(config.hint)
      XCTAssertEqual(config.value, CheckoutComponentsStrings.a11ySubmitButtonLoading)
    }
  }

  private func submitButton(isEnabled: Bool, isLoading: Bool) -> AccessibilityConfiguration {
    .submitButton(identifier: "submit", title: "Pay", isEnabled: isEnabled, isLoading: isLoading)
  }
}
