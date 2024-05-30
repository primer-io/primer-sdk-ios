//
//  ArrayExtensionTests.swift
//  
//
//  Created by Jack Newcombe on 10/05/2024.
//

import XCTest
@testable import PrimerSDK

final class ArrayExtensionTests: XCTestCase {

    func testUniqueArray() {
        let array = [1, 2, 2, 2, 3, 4, 5, 5, 6, 7]

        XCTAssertEqual(array.unique, [1, 2, 3, 4, 5, 6, 7])
    }

    func testToBatches() {
        let array = [1, 2 ,3 ,4 ,5 ,6, 7, 8, 9]

        let pairsBatches = array.toBatches(of: 2)
        XCTAssertEqual(pairsBatches, [[1, 2], [3, 4], [5, 6], [7, 8], [9]])

        let triosBatches = array.toBatches(of: 3)
        XCTAssertEqual(triosBatches, [[1, 2, 3], [4, 5, 6], [7, 8, 9]])

        let singleBatch = array.toBatches(of: 100)
        XCTAssertEqual(singleBatch, [array])
    }

}
