//
//  PrimerStateFieldViewTests.swift
//  
//
//  Created by Jack Newcombe on 21/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerStateFieldViewTests: XCTestCase {

    var view: PrimerStateFieldView!

    override func setUpWithError() throws {
        view = PrimerStateFieldView()
    }

    override func tearDownWithError() throws {
        view = nil
    }

    func testValidationValidState() throws {
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
                           replacementString: "Wyoming")

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidState() throws {
        view.text = "a"
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNil(isValid)
            switch self.view.validation {
            case .invalid(let error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-state] State is not valid.")
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 1),
                           replacementString: "")

        waitForExpectations(timeout: 2.0)
    }
}
