//
//  CardNetworkMenuLayoutTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class CardNetworkMenuLayoutTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 375, height: 812)
    private let field = CGRect(x: 16, y: 100, width: 343, height: 44)
    private let menuSize = CGSize(width: 250, height: 89)

    func test_frame_leftToRight_opensBelowTheFieldEndingAtItsRightEdge() {
        let frame = makeLayout(isRightToLeft: false).frame(below: field, size: menuSize, in: screen)

        XCTAssertEqual(frame, CGRect(x: 109, y: 148, width: 250, height: 89))
    }

    func test_frame_rightToLeft_opensBelowTheFieldStartingAtItsLeftEdge() {
        let frame = makeLayout(isRightToLeft: true).frame(below: field, size: menuSize, in: screen)

        XCTAssertEqual(frame, CGRect(x: 16, y: 148, width: 250, height: 89))
    }

    func test_frame_narrowFieldAtTheLeftEdge_staysInsideTheScreen() {
        let narrowField = CGRect(x: 16, y: 100, width: 200, height: 44)

        let frame = makeLayout(isRightToLeft: false).frame(below: narrowField, size: menuSize, in: screen)

        XCTAssertEqual(frame.minX, 16)
    }

    func test_frame_narrowFieldAtTheRightEdgeInRightToLeft_staysInsideTheScreen() {
        let narrowField = CGRect(x: 200, y: 100, width: 159, height: 44)

        let frame = makeLayout(isRightToLeft: true).frame(below: narrowField, size: menuSize, in: screen)

        XCTAssertEqual(frame.maxX, 359)
    }

    private func makeLayout(isRightToLeft: Bool) -> CardNetworkMenuLayout {
        CardNetworkMenuLayout(gap: 4, edgeInset: 16, isRightToLeft: isRightToLeft)
    }
}
