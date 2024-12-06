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

    func testParseMetadataWithInvalidMetadata() throws {
        let invalidMetadata = "invalid json"

        let result = metadataParser.parse(invalidMetadata)

        XCTAssertEqual(result.count, 0)
    }
}
