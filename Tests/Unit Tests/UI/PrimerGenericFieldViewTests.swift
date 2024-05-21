//
//  PrimerGenericFieldViewTests.swift
//  
//
//  Created by Jack Newcombe on 21/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerGenericFieldViewTests: XCTestCase {

    var view: PrimerGenericFieldView!

    override func setUpWithError() throws {
        view = PrimerGenericFieldView()
    }

    override func tearDownWithError() throws {
        view = nil
    }

    func testValidationValidGeneric() throws {
        view.text = ""
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

        view.isValid = { _ in true }

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
                           replacementString: "Anything")

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidGeneric() throws {
        view.text = ""
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

        view.isValid = { _ in false }

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNil(isValid)
            switch self.view.validation {
            case .invalid(let error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-card-number] Card number is not valid.")
                break
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                           replacementString: "Anything")

        waitForExpectations(timeout: 2.0)
    }
}
