//
//  StateProcessorResponseTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCEngine
import PrimerFoundation
import PrimerStepResolver
import XCTest

final class StateProcessorResponseTests: XCTestCase {

    func testDecodeSuccess() throws { try assertDecode(.success, from: #"{"newState": {}, "terminal": {"outcome": "success"} }"#) }
    func testDecodeCancelled() throws { try assertDecode(.cancelled, from: #"{"newState": {}, "terminal": {"outcome": "cancelled"}}"#) }
    func testDecodeError() throws { try assertDecode(.error, from: #"{"newState": {}, "terminal": {"outcome": "error"}}"#) }
    func testDecodeNilTerminal() throws { try assertDecode(nil, from: #"{"newState": {"token": "abc"}}"#) }

    func testDecodeWithAction() throws {
        let action = #"{ "id": "action-1", "type": "http.request", "params": {"url": "https://api.example.com"} }"#
        try assertDecode(actionId: "action-1", from: generateJSON(withAction: action))
    }

    func testDecodeWithLogAction() throws {
        let action = #"{"id": "log-1", "type": "platform.log", "params": {"message": "checkout started"} }"#
        try assertDecode(actionId: "log-1", from: generateJSON(withAction: action))
    }

    func testDecodeWithUrlOpenAction() throws {
        let action = #"{"id": "open-1", "type": "url.open", "params": {"url": "https://example.com"} }"#
        try assertDecode(actionId: "open-1", from: generateJSON(withAction: action))
    }

    func testDecodeEmptyState() throws {
        let response = try decode(#"{ "newState": {} }"#)
        XCTAssertTrue(response.newState.isEmpty)
        XCTAssertNil(response.action)
        XCTAssertNil(response.terminal)
    }

    func testDecodeMissingNewStateThrows() {
        XCTAssertThrowsError(try decode(#"{"terminal": {"outcome": "success"} }"#))
    }
    func testDecodeInvalidOutcomeThrows() {
        XCTAssertThrowsError(try decode(#"{"newState":{}, "terminal": {"outcome": "foo"} }"#))
    }
}

private extension StateProcessorResponseTests {
    func assertDecode(
        _ terminalOutcome: TerminalOutcome?,
        from json: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let response = try decode(json)
        XCTAssertEqual(
            response.terminal?.outcome,
            terminalOutcome,
            file: file,
            line: line
        )
    }
    
    func assertDecode(actionId: String?, from json: String, file: StaticString = #file, line: UInt = #line) throws {
        let response = try decode(json)
        XCTAssertEqual(
            response.action?.id,
            actionId,
            file: file,
            line: line
        )
    }
    
    func decode(_ json: String) throws -> StateProcessorResponse {
        try JSONDecoder().decode(StateProcessorResponse.self, from: Data(json.utf8))
    }
    
    func generateJSON(withAction action: String) -> String {
        #"{ "newState": {}, "action": \#(action) }"#
    }
    
}
