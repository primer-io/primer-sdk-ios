//
//  PrimerFormViewTests.swift
//  
//
//  Created by Jack Newcombe on 11/06/2024.
//

import XCTest
@testable import PrimerSDK

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
