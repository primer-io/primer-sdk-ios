//
//  PrimerExpiryDateFieldViewTests.swift
//  
//
//  Created by Jack Newcombe on 21/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerExpiryDateFieldViewTests: XCTestCase {

    var view: PrimerExpiryDateFieldView!

    override func setUpWithError() throws {
        view = PrimerExpiryDateFieldView()
    }

    override func tearDownWithError() throws {
        view = nil
    }

    func testValidationValidCode() throws {
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
                           replacementString: "03/30")

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCode() throws {
        view.text = ""
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

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
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            print(">>>>> IS VALID TEXT: \(self.view.textField!.internalText!)")
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
