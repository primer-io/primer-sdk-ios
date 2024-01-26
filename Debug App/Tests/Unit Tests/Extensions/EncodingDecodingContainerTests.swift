//
//  EncodingDecodingContainerTests.swift
//  Debug App
//
//  Created by Evangelos Pittas on 6/3/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class EncodingTests: XCTestCase {
    
    func test_encoding_event_context() throws {
        let event = Analytics.Event.message(
            message: "This is a test message",
            messageType: .error,
            severity: .error,
            context: [
                "bool": true,
                "int": 1,
                "double": 1.0001,
                "string": "This is a string"
            ]
        )
        
        do {
            let data = try JSONEncoder().encode(event)
            guard let dictionary = (try JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                XCTAssert(false, "Failed to find serialize data into Dictionary<String: Any>")
                return
            }
            
            guard let properties = dictionary["properties"] as? [String: Any] else {
                XCTAssert(false, "Failed to serialize 'properties' into Dictionary<String: Any>")
                return
            }
            
            guard let context = properties["context"] as? [String: Any] else {
                XCTAssert(false, "Failed to serialize 'context' into Dictionary<String: Any>")
                return
            }
            
            if let boolVal = context["bool"] as? Bool {
                if !boolVal {
                    XCTAssert(false, "Boolean value for key 'bool' has wrong value")
                }
            } else {
                XCTAssert(false, "Failed to find boolean value for key 'bool'")
            }
            
            if let intVal = context["int"] as? Int {
                if intVal != 1 {
                    XCTAssert(false, "Int value for key 'int' has wrong value")
                }
            } else {
                XCTAssert(false, "Failed to find int value for key 'int'")
            }
            
            if let doubleVal = context["double"] as? Double {
                if doubleVal != 1.0001 {
                    XCTAssert(false, "Double value for key 'double' has wrong value")
                }
            } else {
                XCTAssert(false, "Failed to find double value for key 'double'")
            }
            
            if let stringVal = context["string"] as? String {
                if stringVal != "This is a string" {
                    XCTAssert(false, "String value for key 'string' has wrong value")
                }
            } else {
                XCTAssert(false, "Failed to find string value for key 'string'")
            }
            
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
    }
}
