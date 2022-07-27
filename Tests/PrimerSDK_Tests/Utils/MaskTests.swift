//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

import XCTest
@testable import PrimerSDK

class MaskTests: XCTestCase {

    func test_card_number_formats_correctly() throws {
        let numberMask = Mask(pattern: "#### #### #### #### ###")
        let text = numberMask.apply(on: "4242424242424242")

        XCTAssertEqual(text, "4242 4242 4242 4242")
    }

    func test_card_number_formats_length_correctly() throws {
        let numberMask = Mask(pattern: "#### #### #### #### ###")
        let text = numberMask.apply(on: "424242424242424242444")

        XCTAssertEqual(text, "4242 4242 4242 4242 424")
    }

    func test_card_number_formats_only_digits() throws {
        let numberMask = Mask(pattern: "#### #### #### #### ###")
        let text = numberMask.apply(on: "bla")

        XCTAssertEqual(text, "    ")
    }

    func test_date_formats_correctly() throws {
        let numberMask = Mask(pattern: "##/##")
        let text = numberMask.apply(on: "1223")

        XCTAssertEqual(text, "12/23")
    }

    func test_date_formats_length_correctly() throws {
        let numberMask = Mask(pattern: "##/##")
        let text = numberMask.apply(on: "122333333")

        XCTAssertEqual(text, "12/23")
    }

    func test_date_formats_only_digits() throws {
        let numberMask = Mask(pattern: "##/##")
        let text = numberMask.apply(on: "bla")

        XCTAssertEqual(text, "/")
    }

}
