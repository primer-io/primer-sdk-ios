//
//  PrimerFormViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import PrimerUI
import XCTest

final class PrimerFormViewTests: XCTestCase {

    var sut: PrimerFormView!

    func testViewInit() throws {
        sut = PrimerFormView(formViews: [
            [ UILabel(text: "Testing 1"),
              UILabel(text: "Testing 2") ],
            [ UILabel(text: "Testing 3") ]
        ])

        let sections = sut.verticalStackView.arrangedSubviews
        XCTAssertTrue(sections[0] is UIStackView)
        XCTAssertTrue(sections[1] is UILabel)

        XCTAssertEqual((sections[0].subviews[0] as? UILabel)?.text, "Testing 1")
        XCTAssertEqual((sections[0].subviews[1] as? UILabel)?.text, "Testing 2")
        XCTAssertEqual((sections[1] as? UILabel)?.text, "Testing 3")
    }
}

extension UILabel {

    convenience init(text: String) {
        self.init(frame: .zero)
        self.text = text
        self.layoutIfNeeded()
    }

}
