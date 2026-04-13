//
//  ClientInstructionDecodingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class ClientInstructionDecodingTests: XCTestCase {

    func testDecodesWaitInstruction() throws {
        let result = try decode(#"{"type": "WAIT", "pollDelayMilliseconds": 1000}"#)
        guard case let .wait(wait) = result.type else { return XCTFail("Expected .wait") }
        XCTAssertEqual(wait.pollDelayMilliseconds, 1000)
    }

    func testDecodesExecuteAndFlattensPayload() throws {
        let payload = #"{"schema": { "steps": [] }, "parameters": { "key": "value" } }"#
        let result = try decode(#"{"type": "EXECUTE", "pollDelayMilliseconds": 500, "payload": \#(payload) }"#)
        guard case let .execute(exec) = result.type else { return XCTFail("Expected .execute") }
        XCTAssertEqual(exec.pollDelayMilliseconds, 500)
        XCTAssertEqual(exec.schema, .object(["steps": .array([])]))
        XCTAssertEqual(exec.parameters, .object(["key": .string("value")]))
    }

    func testDecodesEndInstruction() throws {
        let payload = #"{ "payment": { "id": "pay_123", "orderId": "ord_456", "status": "SUCCESS" } }"#
        let result = try decode(#"{"type": "END", "payload": \#(payload) }"#)
        guard case let .end(end) = result.type else { return XCTFail("Expected .end") }
        XCTAssertEqual(end.payload.payment?.id, "pay_123")
        XCTAssertEqual(end.payload.payment?.orderId, "ord_456")
    }

    func testThrowsOnUnknownType() {
        XCTAssertThrowsError(try decode(#"{"type": "UNKNOWN"}"#))
    }
}

private extension ClientInstructionDecodingTests {
    func decode(_ json: String, file: StaticString = #file, line: UInt = #line) throws -> ClientInstructionDataResponse {
        try JSONDecoder().decode(ClientInstructionDataResponse.self, from: Data(json.utf8))
    }
}
