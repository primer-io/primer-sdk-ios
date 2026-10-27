//
//  PrimerExpiryDateFieldViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) import PrimerUI

final class PrimerExpiryDateFieldViewTests: XCTestCase {

    var view: PrimerExpiryDateFieldView!

    var delegate: MockTextFieldViewDelegate!

    override func setUpWithError() throws {
        view = PrimerExpiryDateFieldView()
        delegate = MockTextFieldViewDelegate()
        view.delegate = delegate
    }

    override func tearDownWithError() throws {
        delegate = nil
        view = nil
    }

    func testValidationValidCode() throws {
        view.text = ""

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNotNil(isValid)
            XCTAssertTrue(isValid!)
            switch self.view.validation {
            case .valid:
                break
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "03/30"
        )

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCode() throws {
        view.text = ""

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNotNil(isValid)
            XCTAssertFalse(isValid!)
            switch self.view.validation {
            case let .invalid(error):
                XCTAssertEqual(
                    error?.localizedDescription,
                    "[invalid-expiry-date] Expiry date is not valid. Valid expiry date format is 2 characters for expiry month and 4 characters for expiry year separated by \'/\'."
                )
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "03/19"
        )

        waitForExpectations(timeout: 2.0)
    }

    func testValidationValidCodePartials() throws {
        view.text = ""

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            if self.view.textField!.internalText!.count < 5 { return }
            XCTAssertNotNil(isValid)
            XCTAssertTrue(isValid!)
            switch self.view.validation {
            case .valid:
                break
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "03"
        )

        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 3, length: 0),
            replacementString: "40"
        )

        waitForExpectations(timeout: 2.0)
    }

    func testAutofillDateFormats() throws {
        for date in ["03/30", "03/2030", "3/30", "3/2030", "03 / 2030", "032030"] {
            view.text = ""
            _ = view.textField(
                view.textField,
                shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                replacementString: date
            )
            XCTAssertEqual(view.textField.internalText, "03/30", date)
            XCTAssertEqual(view.expiryMonth, "03", date)
            XCTAssertEqual(view.expiryYear, "30", date)
            XCTAssertTrue(view.isTextValid, date)
        }
    }

    func testAutofillReplacesExistingDate() throws {
        view.text = "01/29"
        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 5),
            replacementString: "12/2030"
        )
        XCTAssertEqual(view.textField.internalText, "12/30")
    }

    func testAutofillRejectsUnknownFormat() throws {
        view.text = ""
        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "12/203"
        )
        XCTAssertEqual(view.textField.internalText, "")
    }

    func testContentType() throws {
        if #available(iOS 17, *) {
            XCTAssertEqual(view.textField.textContentType, .creditCardExpiration)
        }
        XCTAssertEqual(view.textField.keyboardType, .numberPad)
    }

}
