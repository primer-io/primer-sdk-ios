//
//  PrimerPaymentMethodOptionsTests.swift
//
//
//  Created by Jack Newcombe on 22/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerPaymentMethodOptionsTests: XCTestCase {

    func testUrlSchemeValid() throws {
        let model = PrimerPaymentMethodOptions(urlScheme: "urlscheme://valid")

        XCTAssertNoThrow(try model.validUrlForUrlScheme())
        XCTAssertEqual(try model.validUrlForUrlScheme(), URL(string: "urlscheme://valid"))

        XCTAssertNoThrow(try model.validSchemeForUrlScheme())
        XCTAssertEqual(try model.validSchemeForUrlScheme(), "urlscheme")
    }

    func testUrlSchemeInvalidSchemeValidUrl() throws {
        let model = PrimerPaymentMethodOptions(urlScheme: "urlscheme./")

        XCTAssertThrowsError(try model.validUrlForUrlScheme())
        XCTAssertThrowsError(try model.validSchemeForUrlScheme())
    }

    func testUrlSchemeInvalidUrl() throws {
        let model = PrimerPaymentMethodOptions(urlScheme: "!@£$%^&*()")

        XCTAssertThrowsError(try model.validUrlForUrlScheme())
        XCTAssertThrowsError(try model.validSchemeForUrlScheme())
    }

}
