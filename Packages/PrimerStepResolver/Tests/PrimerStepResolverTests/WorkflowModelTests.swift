//
//  WorkflowModelTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerStepResolver
import XCTest

final class StepDomainTests: XCTestCase {
    func testDecodeHttpRequest() throws { XCTAssertEqual(try decode("http.request"), .httpRequest) }
    func testDecodeUrlOpen() throws { XCTAssertEqual(try decode("url.open"), .urlOpen) }
    func testDecodePlatformLog() throws { XCTAssertEqual(try decode("platform.log"), .platformLog) }
    func testDecodeUnknownValueThrows() { XCTAssertThrowsError(try decode("unknown.value")) }
}

private extension StepDomainTests {
    func decode(_ value: String) throws -> StepDomain {
        let json = Data(#""\#(value)""#.utf8)
        let decoded = try JSONDecoder().decode(StepDomain.self, from: json)
        return decoded
    }
}
