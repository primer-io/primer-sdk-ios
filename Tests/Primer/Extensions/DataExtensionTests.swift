//
//  DataExtensionTests.swift
//  
//
//  Created by Jack Newcombe on 10/05/2024.
//

import XCTest
@testable import PrimerSDK

fileprivate struct MockEncodable: Encodable {
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
