//
//  PrimerCardNumberFieldViewTests.swift
//  
//
//  Created by Jack Newcombe on 21/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerCardNumberFieldViewTests: XCTestCase {

    var view: PrimerCardNumberFieldView!

    override func setUpWithError() throws {
        view = PrimerCardNumberFieldView()
    }

    override func tearDownWithError() throws {
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
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

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
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

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
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

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
}
