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
}
