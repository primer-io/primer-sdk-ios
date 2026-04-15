//
//  WorkflowStepTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerStepResolver
import XCTest

final class WorkflowStepTests: XCTestCase {

    func testDecodeHttpRequestStep() throws {
        let step = try decode(#"{"id": "step-1", "type": "http.request", "params": {"url": "https://example.com"} }"#)
        XCTAssertEqual(step.type, "http.request")
        XCTAssertEqual(step.params, .object(["url": .string("https://example.com")]))
    }

    func testDecodePlatformLogStep() throws {
        let step = try decode(#"{"id": "step-2", "type": "platform.log", "params": {"message": "hello"} }"#)
        XCTAssertEqual(step.type, "platform.log")
        XCTAssertEqual(step.params, .object(["message": .string("hello")]))
    }

    func testDecodeUrlOpenStep() throws {
        let step = try decode(#"{"id": "step-3", "type": "url.open", "params": {"url": "https://redirect.example.com"} }"#)
        XCTAssertEqual(step.type, "url.open")
        XCTAssertEqual(step.params, .object(["url": .string("https://redirect.example.com")]))
    }

    func testDecodeUnknownStepTypeDecodesSuccessfully() throws {
        let step = try decode(#"{"id": "step-x", "type": "future.step", "params": {}}"#)
        XCTAssertEqual(step.type, "future.step")
    }

    func testDecodeMissingIdThrows() {
        XCTAssertThrowsError(try decode(#"{"type": "http.request", "params": {}}"#))
    }

    func testDecodeMissingParamsThrows() {
        XCTAssertThrowsError(try decode(#"{"id": "step-x", "type": "http.request"}"#))
    }
}

private extension WorkflowStepTests {
    func decode(_ json: String) throws -> WorkflowStep {
        try JSONDecoder().decode(WorkflowStep.self, from: Data(json.utf8))
    }
}
