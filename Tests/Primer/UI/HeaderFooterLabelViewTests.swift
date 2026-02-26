//
//  HeaderFooterLabelViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import PrimerUI
import XCTest

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
