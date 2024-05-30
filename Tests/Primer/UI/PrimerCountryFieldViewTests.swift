//
//  PrimerCountryFieldViewTests.swift
//  
//
//  Created by Jack Newcombe on 21/05/2024.
//

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
