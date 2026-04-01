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
        let json = #"{"id": "step-1", "type": "http.request", "params": {"url": "https://example.com"} }"#
        try assertParams(json, expected: .object(["url": .string("https://example.com")]))
    }

    func testDecodePlatformLogStep() throws {
        let json = #"{"id": "step-2", "type": "platform.log", "params": {"message": "hello"} }"#
        try assertParams(json, expected: .object(["message": .string("hello")]))
    }

    func testDecodeUrlOpenStep() throws {
        let json = #"{"id": "step-3", "type": "url.open", "params": {"url": "https://redirect.example.com"} }"#
        try assertParams(json, expected: .object(["url": .string("https://redirect.example.com")]))
    }

    func testDecodeMissingIdThrows() {
        let json = #"{"type": "http.request", "params": {}}"#
        XCTAssertThrowsError(try JSONDecoder().decode(WorkflowStep.self, from: Data(json.utf8)))
    }

    func testDecodeMissingParamsThrows() {
        let json = #"{"id": "step-x", "type": "http.request"}"#
        XCTAssertThrowsError(try JSONDecoder().decode(WorkflowStep.self, from: Data(json.utf8)))
    }

    func testDecodeUnknownStepTypeThrows() {
        let json = #"{"id": "step-x", "type": "unknown.type", "params": {}}"#
        XCTAssertThrowsError(try JSONDecoder().decode(WorkflowStep.self, from: Data(json.utf8)))
    }
}

private extension WorkflowStepTests {
    func assertParams(
        _ json: String,
        expected: CodableValue,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let step = try JSONDecoder().decode(WorkflowStep.self, from: Data(json.utf8))
        XCTAssertEqual(step.type.params, expected)
    }
}

private extension WorkflowType {
    var params: CodableValue {
        switch self {
        case let .log(params): params
        case let .httpCall(params): params
        case let .urlOpen(params): params
        }
    }
}
