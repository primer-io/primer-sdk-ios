//
//  DateExtensionTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) import PrimerFoundation

final class DateExtensionTests: XCTestCase {
    func testDateToString() {
        let date = Date(timeIntervalSince1970: 946684800) // 2000-01-01 00:00:00
        XCTAssertEqual(date.toString(timeZone: .init(identifier: "GMT")!), "2000-01-01T00:00:00.000+0000")
    }

    func testMillisecondsSince1970() {
        let milleniumEpochMillis: TimeInterval = 946684800
        let date = Date(timeIntervalSince1970: milleniumEpochMillis)

        let expectedMillis: TimeInterval = (milleniumEpochMillis * 1000.0)

        XCTAssertEqual(date.millisecondsSince1970, Int(expectedMillis))
    }
}
