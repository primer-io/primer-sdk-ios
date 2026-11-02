//
//  ProbeRequestTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class ProbeRequestTests: XCTestCase {
    func testDecodesTheStateProcessorsProbesToRun() throws {
        let json = #"[{"key":"klarna.sdk:{\"version\":\"^5.0.0\"}","probe":"klarna.sdk","params":{"version":"^5.0.0"}}]"#

        let requests = try JSONDecoder().decode([ProbeRequest].self, from: Data(json.utf8))

        XCTAssertEqual(requests, [ProbeRequest(
            key: #"klarna.sdk:{"version":"^5.0.0"}"#,
            probe: "klarna.sdk",
            params: .object(["version": .string("^5.0.0")])
        )])
    }
}
