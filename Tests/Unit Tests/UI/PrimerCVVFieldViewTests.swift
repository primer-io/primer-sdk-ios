//
//  PrimerCVVFieldViewTests.swift
//  
//
//  Created by Jack Newcombe on 21/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerCVVFieldViewTests: XCTestCase {

    var view: PrimerCVVFieldView!

    override func setUpWithError() throws {
        view = PrimerCVVFieldView()
    }

    override func tearDownWithError() throws {
        view = nil
    }

    func testValidationValidCVV() {
        view.text = "1234"
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

        view.cardNetwork = .amex

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
                           shouldChangeCharactersIn: NSRange(location: 0, length: 4),
                           replacementString: "4567")

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCVV() {
        view.text = "1234"
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

        view.cardNetwork = .visa

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNotNil(isValid)
            XCTAssertFalse(isValid!)
            switch self.view.validation {
            case .invalid(let error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-cvv] CVV is not valid.")
                break
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 4),
                           replacementString: "4567")

        waitForExpectations(timeout: 2.0)
    }

    func testValidationEmptyCVV() {
        view.text = "1234"
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

        view.cardNetwork = .visa

        view.isValid = { _ in false }

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNotNil(isValid)
            XCTAssertFalse(isValid!)
            switch self.view.validation {
            case .invalid(let error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-cvv] CVV cannot be blank.")
                break
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
}
