//
//  ArrayExtensionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class ArrayExtensionTests: XCTestCase {

    func testToBatches() {
        let array = [1, 2, 3, 4, 5, 6, 7, 8, 9]

        let pairsBatches = array.toBatches(of: 2)
        XCTAssertEqual(pairsBatches, [[1, 2], [3, 4], [5, 6], [7, 8], [9]])

        let triosBatches = array.toBatches(of: 3)
        XCTAssertEqual(triosBatches, [[1, 2, 3], [4, 5, 6], [7, 8, 9]])

        let singleBatch = array.toBatches(of: 100)
        XCTAssertEqual(singleBatch, [array])
    }

}
