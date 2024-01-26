//
//  AnalyticsEventsTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 23/10/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class AnalyticsEventsTests: XCTestCase {
    
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
