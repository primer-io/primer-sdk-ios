//
//  PrimerExpiryDateFieldViewTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

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

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                           replacementString: "03/30")

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCode() throws {
        view.text = ""

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNotNil(isValid)
            XCTAssertFalse(isValid!)
            switch self.view.validation {
            case .invalid(let error):
                XCTAssertEqual(error?.localizedDescription,
                               "[invalid-expiry-date] Expiry date is not valid. Valid expiry date format is 2 characters for expiry month and 4 characters for expiry year separated by \'/\'.")
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                           replacementString: "03/19")

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

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                           replacementString: "03")

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 3, length: 0),
                           replacementString: "40")

        waitForExpectations(timeout: 2.0)
    }

}
