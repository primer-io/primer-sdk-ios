//
//  PrimerCVVFieldViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) import PrimerUI

final class PrimerCVVFieldViewTests: XCTestCase {

    var view: PrimerCVVFieldView!

    var delegate: MockTextFieldViewDelegate!

    override func setUpWithError() throws {
        view = PrimerCVVFieldView()
        delegate = MockTextFieldViewDelegate()
        view.delegate = delegate
    }

    override func tearDownWithError() throws {
        delegate = nil
        view = nil
    }

    func testValidationValidCVV() {
        view.text = "1234"
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

        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 4),
            replacementString: "4567"
        )

        waitForExpectations(timeout: 2.0)
    }

    func testValidationInvalidCVV() {
        view.text = "1234"
        view.cardNetwork = .visa

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNotNil(isValid)
            XCTAssertFalse(isValid!)
            switch self.view.validation {
            case let .invalid(error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-cvv] CVV is not valid.")
                break
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 4),
            replacementString: "4567"
        )

        waitForExpectations(timeout: 2.0)
    }

    func testValidationEmptyCVV() {
        view.text = "1234"
        view.cardNetwork = .visa

        view.isValid = { _ in false }

        let expectation = self.expectation(description: "onIsValid is called")
        delegate.onIsValid = { isValid in
            XCTAssertNotNil(isValid)
            XCTAssertFalse(isValid!)
            switch self.view.validation {
            case let .invalid(error):
                XCTAssertEqual(error?.localizedDescription, "[invalid-cvv] CVV cannot be blank.")
                break
            default:
                XCTFail()
            }
            expectation.fulfill()
        }

        _ = view.textField(
            view.textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 4),
            replacementString: ""
        )

        waitForExpectations(timeout: 2.0)
    }
}
