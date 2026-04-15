//
//  WorkflowModelTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerStepResolver
import XCTest

final class StepDomainConstantsTests: XCTestCase {
    func testHttpRequest() { XCTAssertEqual(StepDomain.httpRequest, "http.request") }
    func testUrlOpen() { XCTAssertEqual(StepDomain.urlOpen, "url.open") }
    func testPlatformLog() { XCTAssertEqual(StepDomain.platformLog, "platform.log") }
}
