//
//  MetadataParserTests.swift
//  Debug App Tests
//
//  Created by Niall Quinn on 11/03/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import Debug_App

final class MetadataParserTests: XCTestCase {

    private let metadataParser = MetadataParser()

    func testParseMetadataWithJSON() throws {
        let jsonMetadata = #"{"key1": "value1", "key2": 123}"#

        let result = metadataParser.parse(jsonMetadata)

        XCTAssertEqual(result["key1"] as? String, "value1")
        XCTAssertEqual(result["key2"] as? Int, 123)
    }

    func testParseMetadataWithKeyValuePairs() throws {
        let keyValueMetadata = """
                key1=value1
                doubleKey=123.0
                intKey=123
                """

        let result = metadataParser.parse(keyValueMetadata)

        XCTAssertEqual(result["key1"] as? String, "value1")
        XCTAssertEqual(result["doubleKey"] as? Double, 123)
        XCTAssertEqual(result["intKey"] as? Int, 123)
    }

    func testParseMetadataWithInvalidMetadata() throws {
        let invalidMetadata = "invalid json"

        let result = metadataParser.parse(invalidMetadata)

        XCTAssertEqual(result.count, 0)
    }
}
