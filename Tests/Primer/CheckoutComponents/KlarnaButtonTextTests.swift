//
//  KlarnaButtonTextTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class KlarnaButtonTextTests: XCTestCase {

    func test_init_english_putsTextBeforeTheBadge() {
        assertSplit("Pay with Klarna", before: "Pay with", after: nil)
    }

    func test_init_german_putsTextOnBothSides() {
        assertSplit("Mit Klarna bezahlen", before: "Mit", after: "bezahlen")
    }

    func test_init_turkish_putsTextAfterTheBadge() {
        assertSplit("Klarna ile öde", before: nil, after: "ile öde")
    }

    func test_init_japaneseWithoutSpaces_putsTextAfterTheBadge() {
        assertSplit("Klarnaでお支払い", before: nil, after: "でお支払い")
    }

    func test_init_arabic_putsTextBeforeTheBadge() {
        assertSplit("الدفع بـ Klarna", before: "الدفع بـ", after: nil)
    }

    func test_init_brandOnly_showsTheBadgeAlone() {
        assertSplit("Klarna", before: nil, after: nil)
    }

    func test_init_noBrand_showsTheBadgeAlone() {
        assertSplit("Pay later", before: nil, after: nil)
    }

    // MARK: - Helpers

    private func assertSplit(
        _ label: String,
        before: String?,
        after: String?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // When
        let sut = KlarnaButtonText(label)

        // Then
        XCTAssertEqual(sut.before, before, file: file, line: line)
        XCTAssertEqual(sut.after, after, file: file, line: line)
    }
}
