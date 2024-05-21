//
//  PrimerCityFieldViewTests.swift
//  
//
//  Created by Jack Newcombe on 21/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerCityFieldViewTests: XCTestCase {

    var view: PrimerCityFieldView!

    override func setUpWithError() throws {
        view = PrimerCityFieldView()
    }

    override func tearDownWithError() throws {
        view = nil
    }

    func testValidationValidCity() throws {
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
                           replacementString: "Berlin")

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCity() throws {
        view.text = ""
        let delegate = MockTextFieldViewDelegate()
        view.delegate = delegate

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNil(isValid)
            switch self.view.validation {
            case .invalid(let error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-city] City is not valid.")
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(view.textField,
                           shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                           replacementString: "123456")

        waitForExpectations(timeout: 2.0)
    }
}
