//
//  DataExtensionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

private struct MockEncodable: Encodable {
    let name: String = "John Appleseed"
    let age: Int = 33
    let location = "California"
}

final class DataExtensionTests: XCTestCase {

    func testPrettyPrintString() throws {
        let data = try JSONEncoder().encode(MockEncodable())

        let expected = """
{
  "age" : 33,
  "location" : "California",
  "name" : "John Appleseed"
}
"""

        XCTAssertEqual(data.prettyPrintedJSONString, expected)
    }

}
