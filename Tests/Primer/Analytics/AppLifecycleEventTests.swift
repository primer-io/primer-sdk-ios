//
//  AppLifecycleEventTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class AppLifecycleEventTests: XCTestCase {

    func testBackgroundEventProperties() {
        let event = Analytics.Event.appLifecycle(.backgrounded)
        XCTAssertEqual(event.eventType, .appLifecycle)
        let properties = event.properties as? AppLifecycleEventProperties
        XCTAssertNotNil(properties)
        XCTAssertEqual(properties?.lifecycleType, .backgrounded)
    }

    func testForegroundEventProperties() {
        let event = Analytics.Event.appLifecycle(.foregrounded)
        XCTAssertEqual(event.eventType, .appLifecycle)
        let properties = event.properties as? AppLifecycleEventProperties
        XCTAssertNotNil(properties)
        XCTAssertEqual(properties?.lifecycleType, .foregrounded)
    }

    func testEncodeDecode() throws {
        let event = Analytics.Event.appLifecycle(.backgrounded)
        let originalProperties = event.properties as? AppLifecycleEventProperties

        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(Analytics.Event.self, from: data)
        XCTAssertEqual(decoded.eventType, .appLifecycle)

        let decodedProperties = decoded.properties as? AppLifecycleEventProperties
        XCTAssertNotNil(decodedProperties)
        XCTAssertEqual(decodedProperties?.lifecycleType, originalProperties?.lifecycleType)
    }
}
