//
//  SecureTextFieldTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class SecureTextFieldTests: XCTestCase {

  func testTextPropertyReturnsMaskedValue() {
    let textField = SecureTextField()
    textField.internalText = "4242424242424242"

    XCTAssertEqual(textField.text, "****")
  }

  func testInternalTextReturnsActualValue() {
    let textField = SecureTextField()
    textField.internalText = "4242424242424242"

    XCTAssertEqual(textField.internalText, "4242424242424242")
  }

  func testSettingTextViaTextPropertyUpdatesInternalText() {
    let textField = SecureTextField()
    textField.text = "4111111111111111"

    XCTAssertEqual(textField.internalText, "4111111111111111")
    XCTAssertEqual(textField.text, "****")
  }

  func testInternalTextIsEmptyByDefault() {
    let textField = SecureTextField()

    XCTAssertEqual(textField.internalText, "")
    XCTAssertEqual(textField.text, "****")
  }

  func testCVVValueIsMasked() {
    let textField = SecureTextField()
    textField.internalText = "123"

    XCTAssertEqual(textField.text, "****")
    XCTAssertEqual(textField.internalText, "123")
  }

  func testEmptyStringIsMasked() {
    let textField = SecureTextField()
    textField.internalText = ""

    XCTAssertEqual(textField.text, "****")
    XCTAssertEqual(textField.internalText, "")
  }
}
