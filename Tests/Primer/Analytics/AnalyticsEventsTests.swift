//
//  AnalyticsEventsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
@testable import PrimerSDK
import XCTest

final class AnalyticsEventsTests: XCTestCase {

    func testKnownEventTypeDecodesCorrectly() throws {
        let json = Data(#""UI_EVENT""#.utf8)
        let decoded = try JSONDecoder().decode(Analytics.Event.EventType.self, from: json)
        XCTAssertEqual(decoded, .ui)
    }

    func testUnknownEventTypeDecodesWithoutError() throws {
        let json = Data(#""SOME_NEW_EVENT""#.utf8)
        let decoded = try JSONDecoder().decode(Analytics.Event.EventType.self, from: json)
        XCTAssertEqual(decoded.rawValue, "SOME_NEW_EVENT")
    }

    func testEventTypeRoundTrip() throws {
        let original = Analytics.Event.EventType(rawValue: "CUSTOM_EVENT")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Analytics.Event.EventType.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testRawEventPropertiesRoundTrips() throws {
        let json = Data(#"{"foo":"bar","count":42}"#.utf8)
        let properties = try RawEventProperties(data: json)
        let encoded = try JSONEncoder().encode(properties)
        let decoded = try JSONDecoder().decode(RawEventProperties.self, from: encoded)
        let reEncoded = try JSONEncoder().encode(decoded)

        let original = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        let result = try JSONSerialization.jsonObject(with: reEncoded) as? [String: Any]
        XCTAssertEqual(original?["foo"] as? String, result?["foo"] as? String)
        XCTAssertEqual(original?["count"] as? Int, result?["count"] as? Int)
    }

    func testUDIDPersistsAcrossEvents() throws {
        let event1 = Analytics.Event.message(
            message: "",
            messageType: .other,
            severity: .debug
        )
        let event2 = Analytics.Event.sdk(
            name: "",
            params: nil
        )
        let event3 = Analytics.Event.ui(
            action: .click,
            context: nil,
            extra: nil,
            objectType: .button,
            objectId: nil,
            objectClass: nil,
            place: .cardForm
        )

        XCTAssertEqual(event1.device.uniqueDeviceIdentifier, event2.device.uniqueDeviceIdentifier)
        XCTAssertEqual(event2.device.uniqueDeviceIdentifier, event3.device.uniqueDeviceIdentifier)
    }
}
