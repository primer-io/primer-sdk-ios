//
//  PrimerCardNumberFieldViewTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PrimerCardNumberFieldViewTests: XCTestCase {

    var view: PrimerCardNumberFieldView!

    var delegate: MockTextFieldViewDelegate!

    override func setUpWithError() throws {
        view = PrimerCardNumberFieldView()
        delegate = MockTextFieldViewDelegate()
        view.delegate = delegate
    }

    override func tearDownWithError() throws {
        delegate = nil
        view = nil
    }

    func testValidationValidCardNumber() throws {
        view.text = ""
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

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
                           replacementString: Constants.testCardNumbers[.masterCard]!.first!)

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCardNumber() throws {
        view.text = ""

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNotNil(isValid)
            XCTAssertFalse(isValid!)
            switch self.view.validation {
            case .invalid(let error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-card-number] Card number is not valid.")
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                           replacementString: "4111 1111 1111 1111 111")

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCardNumber_Empty() throws {
        view.text = "4111"

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNil(isValid)
            switch self.view.validation {
            case .invalid(let error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-card-number] Card number can not be blank.")
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 4),
                           replacementString: "")

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCardNumber_Partial() throws {
        view.text = ""

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNil(isValid)
            switch self.view.validation {
            case .invalid(let error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-card-number] Card number is not valid.")
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                           replacementString: "4111 1111 1111 11")

        waitForExpectations(timeout: 2.0)
    }

    func testCursorMovesToEndAfterPasting() throws {
        view.text = ""

        // Simulate pasting a card number
        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                           replacementString: "4242424242424242")

        // Add a small delay to ensure the cursor movement code has executed
        let expectation = XCTestExpectation(description: "Wait for cursor to move")

        DispatchQueue.main.async {
            // Check if the cursor is at the end of the text
            let expectedPosition = self.view.textField.position(from: self.view.textField.endOfDocument, offset: 0)
            XCTAssertEqual(self.view.textField.selectedTextRange?.start, expectedPosition)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.3)
    }
}
