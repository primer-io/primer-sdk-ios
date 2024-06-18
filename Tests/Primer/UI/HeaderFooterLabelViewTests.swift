//
//  HeaderFooterLabelViewTests.swift
//  
//c
//  Created by Jack Newcombe on 11/06/2024.
//

import XCTest
@testable import PrimerSDK

final class HeaderFooterLabelViewTests: XCTestCase {

    var sut: HeaderFooterLabelView!

    func testViewInit() throws {
        sut = HeaderFooterLabelView(reuseIdentifier: "Test")
        sut.configure(text: "Testing")


        let labelView = sut.contentView.subviews.first?.subviews.first as? UILabel
        XCTAssertNotNil(labelView?.text)
        XCTAssertEqual(labelView?.text, "Testing")
    }
}
