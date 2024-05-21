//
//  PrimerLastNameFieldViewTests.swift
//
//
//  Created by Jack Newcombe on 21/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerLastNameFieldViewTests: XCTestCase {

    var view: PrimerLastNameFieldView!

    override func setUpWithError() throws {
        view = PrimerLastNameFieldView()
    }

    override func tearDownWithError() throws {
        view = nil
    }

    func testValidationValidLastName() throws {
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
