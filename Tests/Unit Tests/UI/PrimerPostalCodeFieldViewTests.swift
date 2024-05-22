//
//  PrimerPostalCodeFieldViewTests.swift
//  
//
//  Created by Jack Newcombe on 21/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerPostalCodeFieldViewTests: XCTestCase {

    var view: PrimerPostalCodeFieldView!

    var delegate: MockTextFieldViewDelegate!

    override func setUpWithError() throws {
        view = PrimerPostalCodeFieldView()
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
                           replacementString: "BS1 4DJ")

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCode() throws {
        view.text = ""

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNil(isValid)
            switch self.view.validation {
            case .invalid(let error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-postal-code] Postal code is not valid.")
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                           replacementString: "!!!!!!")

        waitForExpectations(timeout: 2.0)
    }
}
