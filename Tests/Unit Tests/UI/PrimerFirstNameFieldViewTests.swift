//
//  PrimerFirstNameFieldViewTests.swift
//  
//
//  Created by Jack Newcombe on 21/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerFirstNameFieldViewTests: XCTestCase {

    var view: PrimerFirstNameFieldView!

    override func setUpWithError() throws {
        view = PrimerFirstNameFieldView()
    }

    override func tearDownWithError() throws {
        view = nil
    }

    func testValidationValidFirstName() throws {
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
                           replacementString: "John")

        waitForExpectations(timeout: 2.0)
    }
}
