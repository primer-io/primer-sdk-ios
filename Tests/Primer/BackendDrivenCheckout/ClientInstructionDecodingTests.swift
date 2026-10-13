//
//  ClientInstructionDecodingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) @testable import PrimerFoundation
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

final class ClientInstructionSetupResponseDecodingTests: XCTestCase {

    func testDecodesExecuteInstructionEnvelope() throws {
        let json = #"{"paymentMethodSetupId": "setup-1", "instruction": {"type": "EXECUTE", "pollDelayMilliseconds": 1000, "nextPoll": "interval", "payload": {"schema": { "steps": [] }, "parameters": { "key": "value" } } } }"#
        let result = try decode(json)
        XCTAssertEqual(result.paymentMethodSetupId, "setup-1")
        XCTAssertEqual(result.instruction.nextPoll, .interval)
        XCTAssertEqual(result.instruction.payload.schema, .object(["steps": .array([])]))
        XCTAssertEqual(result.instruction.payload.parameters, .object(["key": .string("value")]))
    }

    func testDoesNotDecodeBareSchemaAndParameters() {
        let json = #"{"schema": { "steps": [] }, "parameters": { "key": "value" }, "paymentMethodSetupId": "setup-1", "nextPoll": "interval" }"#
        XCTAssertThrowsError(try decode(json))
    }

    func testThrowsWhenParametersMissing() {
        let json = #"{"paymentMethodSetupId": "setup-1", "instruction": {"type": "EXECUTE", "nextPoll": "suspend", "payload": {"schema": { "steps": [] } } } }"#
        XCTAssertThrowsError(try decode(json))
    }
}

final class ClientInstructionSetupStateResponseDecodingTests: XCTestCase {

    func testDecodesWait() throws {
        let result = try decode(#"{"paymentMethodSetupId": "setup-1", "instruction": {"type": "WAIT", "pollDelayMilliseconds": 1000, "nextPoll": "interval"} }"#)
        XCTAssertEqual(result.instruction.type, .wait)
        XCTAssertEqual(result.instruction.nextPoll, .interval)
        XCTAssertNil(result.instruction.payload)
    }

    func testDecodesExecute() throws {
        let result = try decode(#"{"paymentMethodSetupId": "setup-1", "instruction": {"type": "EXECUTE", "nextPoll": "suspend", "payload": {"schema": { "steps": [] }, "parameters": {} } } }"#)
        XCTAssertEqual(result.instruction.type, .execute)
        XCTAssertEqual(result.instruction.payload?.schema, .object(["steps": .array([])]))
    }

    func testDecodesSetupCompleteWithoutNextPoll() throws {
        let result = try decode(#"{"paymentMethodSetupId": "setup-1", "instruction": {"type": "SETUP_COMPLETE", "payload": {"paymentInstrumentToken": "tok_123"} } }"#)
        XCTAssertEqual(result.instruction.type, .setupComplete)
        XCTAssertNil(result.instruction.nextPoll)
        XCTAssertEqual(result.instruction.payload?.paymentInstrumentToken, "tok_123")
    }
}

private extension ClientInstructionSetupStateResponseDecodingTests {
    func decode(_ json: String) throws -> ClientInstructionSetupStateResponse {
        try JSONDecoder().decode(ClientInstructionSetupStateResponse.self, from: Data(json.utf8))
    }
}

private extension ClientInstructionSetupResponseDecodingTests {
    func decode(_ json: String) throws -> ClientInstructionSetupResponse {
        try JSONDecoder().decode(ClientInstructionSetupResponse.self, from: Data(json.utf8))
    }
}

private extension ClientInstructionDecodingTests {
    func decode(_ json: String, file: StaticString = #file, line: UInt = #line) throws -> ClientInstructionDataResponse {
        try JSONDecoder().decode(ClientInstructionDataResponse.self, from: Data(json.utf8))
    }
}
