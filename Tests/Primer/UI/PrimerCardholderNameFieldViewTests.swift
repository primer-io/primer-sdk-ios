//
//  PrimerCardholderNameFieldViewTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PrimerCardholderNameFieldViewTests: XCTestCase {

    var view: PrimerCardholderNameFieldView!

    override func setUpWithError() throws {
        view = PrimerCardholderNameFieldView()
    }

    override func tearDownWithError() throws {
        view = nil
    }

    func testTextValidity() throws {
        setText("")
        XCTAssertFalse(view.isTextValid)

        setText("123")
        XCTAssertFalse(view.isTextValid)

        setText("JA")
        XCTAssertTrue(view.isTextValid)
        XCTAssertEqual(view.cardholderName, "JA")

        setText("John Appleseed")
        XCTAssertTrue(view.isTextValid)
        XCTAssertEqual(view.cardholderName, "John Appleseed")

        setText(nil)
        XCTAssertFalse(view.isTextValid)
        XCTAssertNil(view.text)
        XCTAssertEqual(view.cardholderName, "")
    }

    func testRangeReplacement() {
        let range = NSRange(location: 0, length: 6)

        setText("abcdef")
        XCTAssertTrue(view.isTextValid)

        let resultInvalidString = view.textField(view.textField, shouldChangeCharactersIn: range, replacementString: "123456")
        XCTAssertFalse(resultInvalidString)
        XCTAssertEqual(view.cardholderName, "abcdef")

        let resultEmptyString = view.textField(view.textField, shouldChangeCharactersIn: range, replacementString: "")
        XCTAssertFalse(resultEmptyString)
        XCTAssertEqual(view.cardholderName, "")

        setText("abcdef")

        let resultValidString = view.textField(view.textField, shouldChangeCharactersIn: range, replacementString: "ghijkl")
        XCTAssertFalse(resultValidString)
        XCTAssertEqual(view.cardholderName, "ghijkl")
    }

    // MARK: Helpers

    private func setText(_ text: String?) {
        view.textFieldDidBeginEditing(view.textField)
        view.text = text
        view.textFieldDidEndEditing(view.textField)
    }
}
