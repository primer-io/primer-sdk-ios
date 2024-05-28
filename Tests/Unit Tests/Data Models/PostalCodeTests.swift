//
//  PostalCodeTests.swift
//  
//
//  Created by Jack Newcombe on 13/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PostalCodeTests: XCTestCase {

    func testPostcodes() {
        XCTAssertEqual(PostalCode.sample(for: .gb), "EC1A 1BB")
        XCTAssertEqual(PostalCode.sample(for: .us), "90210")
        XCTAssertEqual(PostalCode.sample(for: .ca), "K1A 0B1")

        XCTAssertEqual(PostalCode.sample(for: .ag), "90210")
        XCTAssertEqual(PostalCode.sample(for: nil), "90210")
    }
}
