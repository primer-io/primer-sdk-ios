//
//  PrimerStateFieldViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import PrimerUI
import XCTest

final class PrimerStateFieldViewTests: XCTestCase {

    var view: PrimerStateFieldView!

    var delegate: MockTextFieldViewDelegate!

    override func setUpWithError() throws {
        view = PrimerStateFieldView()
        delegate = MockTextFieldViewDelegate()
        view.delegate = delegate
    }

    override func tearDownWithError() throws {
        delegate = nil
        view = nil
    }

    func testValidationValidState() throws {
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
            replacementString: "Wyoming"
        )

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidState() throws {
        view.text = "a"

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNil(isValid)
            switch self.view.validation {
            case let .invalid(error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-state] State is not valid.")
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 1),
            replacementString: ""
        )

        waitForExpectations(timeout: 2.0)
    }
}
