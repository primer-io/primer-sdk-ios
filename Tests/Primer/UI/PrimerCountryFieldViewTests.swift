//
//  PrimerCountryFieldViewTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PrimerCountryFieldViewTests: XCTestCase {

    var view: PrimerCountryFieldView!

    override func setUpWithError() throws {
        view = PrimerCountryFieldView()
    }

    override func tearDownWithError() throws {
        view = nil
    }

    func testValidationValidCountry() throws {
        let result  = view.textField(view.textField,
                                     shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                                     replacementString: "Australia")
        XCTAssertFalse(result)
    }
}
