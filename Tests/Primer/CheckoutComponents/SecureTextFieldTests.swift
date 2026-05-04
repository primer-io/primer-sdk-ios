//
//  SecureTextFieldTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class SecureTextFieldTests: XCTestCase {

    func test_textProperty_returnssMaskedValue() {
        let textField = SecureTextField()
        textField.internalText = "4242424242424242"

        XCTAssertEqual(textField.text, "****")
    }

    func test_internalText_returnsActualValue() {
        let textField = SecureTextField()
        textField.internalText = "4242424242424242"

        XCTAssertEqual(textField.internalText, "4242424242424242")
    }

    func test_settingTextViaTextProperty_updatesInternalText() {
        let textField = SecureTextField()
        textField.text = "4111111111111111"

        XCTAssertEqual(textField.internalText, "4111111111111111")
        XCTAssertEqual(textField.text, "****")
    }

    func test_internalText_isEmptyByDefault() {
        let textField = SecureTextField()

        XCTAssertEqual(textField.internalText, "")
        XCTAssertEqual(textField.text, "****")
    }

    func test_cvvValue_isMasked() {
        let textField = SecureTextField()
        textField.internalText = "123"

        XCTAssertEqual(textField.text, "****")
        XCTAssertEqual(textField.internalText, "123")
    }

    func test_emptyString_isMasked() {
        let textField = SecureTextField()
        textField.internalText = ""

        XCTAssertEqual(textField.text, "****")
        XCTAssertEqual(textField.internalText, "")
    }
}
