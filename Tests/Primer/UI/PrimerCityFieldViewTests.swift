//
//  PrimerCityFieldViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class PrimerCityFieldViewTests: XCTestCase {

    var view: PrimerCityFieldView!

    var delegate: MockTextFieldViewDelegate!

    override func setUpWithError() throws {
        view = PrimerCityFieldView()
        delegate = MockTextFieldViewDelegate()
        view.delegate = delegate
    }

    override func tearDownWithError() throws {
        delegate = nil
        view = nil
    }

    func testValidationValidCity() throws {
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

        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "Berlin"
        )

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCity() throws {
        view.text = ""

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNil(isValid)
            switch self.view.validation {
            case let .invalid(error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-city] City is not valid.")
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "123456"
        )

        waitForExpectations(timeout: 2.0)
    }
}
