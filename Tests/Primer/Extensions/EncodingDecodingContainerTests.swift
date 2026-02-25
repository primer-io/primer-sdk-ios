//
//  EncodingDecodingContainerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
@testable import PrimerSDK
import XCTest

class EncodingDecodingTests: XCTestCase {

    var event: Analytics.Event {
        .message(
            message: "This is a test message",
            messageType: .error,
            severity: .error,
            context: [
                "bool": true,
                "int": 123,
                "double": 1.123,
                "string": "This is a string",
                "dict": [
                    "string": "This is another string"
                ],
                "array": [
                    false,
                    321,
                    3.321,
                    "This is a string in an array"
                ]
            ]
        )
    }

    var eventWithoutContext: Analytics.Event {
        .message(
            message: "This is a test message",
            messageType: .error,
            severity: .error
        )
    }

    func testEncodingEventContext() throws {
        let data = try JSONEncoder().encode(event)

        let dictionary = (try JSONSerialization.jsonObject(with: data)) as? [String: Any]
        XCTAssertNotNil(dictionary)

        let properties = dictionary!["properties"] as? [String: Any]
        XCTAssertNotNil(properties)

        let context = properties!["context"] as? [String: Any]
        XCTAssertNotNil(context)

        let boolValue = context!["bool"] as? Bool
        XCTAssertNotNil(boolValue)
        XCTAssertTrue(boolValue!)

        let intValue = context!["int"] as? Int
        XCTAssertNotNil(intValue)
        XCTAssertEqual(intValue!, 123)

        let doubleValue = context!["double"] as? Double
        XCTAssertNotNil(doubleValue)
        XCTAssertEqual(doubleValue!, 1.123, accuracy: 0.001)

        let stringValue = context!["string"] as? String
        XCTAssertNotNil(stringValue)
        XCTAssertEqual(stringValue!, "This is a string")

        let nestedDict = context!["dict"] as? [String: Any]
        XCTAssertNotNil(nestedDict)

        let nestedDictStringValue = nestedDict!["string"] as? String
        XCTAssertNotNil(nestedDictStringValue)
        XCTAssertEqual(nestedDictStringValue!, "This is another string")

        let nestedArray = context!["array"] as? [Any]
        XCTAssertNotNil(nestedArray)

        let nestedArrayBoolValue = nestedArray![0] as? Bool
        XCTAssertNotNil(nestedArrayBoolValue)
        XCTAssertFalse(nestedArrayBoolValue!)
        let nestedArrayIntValue = nestedArray![1] as? Int
        XCTAssertNotNil(nestedArrayIntValue)
        XCTAssertEqual(nestedArrayIntValue!, 321)
        let nestedArrayDoubleValue = nestedArray![2] as? Double
        XCTAssertNotNil(nestedArrayDoubleValue)
        XCTAssertEqual(nestedArrayDoubleValue!, 3.321, accuracy: 0.001)
        let nestedArrayStringValue = nestedArray![3] as? String
        XCTAssertNotNil(nestedArrayStringValue)
        XCTAssertEqual(nestedArrayStringValue!, "This is a string in an array")
    }

    func testDecodingEventContext() throws {
        let data = try JSONEncoder().encode(event)
        let event = try JSONDecoder().decode(Analytics.Event.self, from: data)

        let properties = event.properties as? MessageEventProperties
        XCTAssertNotNil(properties)

        let context = properties?.context
        XCTAssertNotNil(context)

        let boolValue = context!["bool"] as? Bool
        XCTAssertNotNil(boolValue)
        XCTAssertTrue(boolValue!)

        let intValue = context!["int"] as? Int
        XCTAssertNotNil(intValue)
        XCTAssertEqual(intValue!, 123)

        let doubleValue = context!["double"] as? Double
        XCTAssertNotNil(doubleValue)
        XCTAssertEqual(doubleValue!, 1.123, accuracy: 0.001)

        let stringValue = context!["string"] as? String
        XCTAssertNotNil(stringValue)
        XCTAssertEqual(stringValue!, "This is a string")

        let nestedDict = context!["dict"] as? [String: Any]
        XCTAssertNotNil(nestedDict)

        let nestedDictStringValue = nestedDict!["string"] as? String
        XCTAssertNotNil(nestedDictStringValue)
        XCTAssertEqual(nestedDictStringValue!, "This is another string")

        let nestedArray = context!["array"] as? [Any]
        XCTAssertNotNil(nestedArray)

        let nestedArrayBoolValue = nestedArray![0] as? Bool
        XCTAssertNotNil(nestedArrayBoolValue)
        XCTAssertFalse(nestedArrayBoolValue!)
        let nestedArrayIntValue = nestedArray![1] as? Int
        XCTAssertNotNil(nestedArrayIntValue)
        XCTAssertEqual(nestedArrayIntValue!, 321)
        let nestedArrayDoubleValue = nestedArray![2] as? Double
        XCTAssertNotNil(nestedArrayDoubleValue)
        XCTAssertEqual(nestedArrayDoubleValue!, 3.321, accuracy: 0.001)
        let nestedArrayStringValue = nestedArray![3] as? String
        XCTAssertNotNil(nestedArrayStringValue)
        XCTAssertEqual(nestedArrayStringValue!, "This is a string in an array")
    }

    func testEncodingEventWithoutContext() throws {
        let data = try JSONEncoder().encode(eventWithoutContext)
        XCTAssertNotNil(data)
    }
}
