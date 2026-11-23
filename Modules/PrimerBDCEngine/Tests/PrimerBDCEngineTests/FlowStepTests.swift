//
//  FlowStepTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver
import XCTest

final class FlowStepTests: XCTestCase {
    func testARunActionStepCarriesTheStateLayersAndAction() throws {
        let step = try decode(#"""
        {"kind": "runAction", "state": {"order": "o-1"},
         "layers": [{"stepId": "pay", "processedUI": {"type": "Text"}}],
         "action": {"id": "a-1", "type": "http.request", "params": {"url": "https://x"}, "delayMs": 20}}
        """#)
        guard case let .runAction(state, layers, action, reply) = step else { return XCTFail("expected runAction") }
        XCTAssertEqual(state, ["order": .string("o-1")])
        XCTAssertEqual(layers.map(\.stepId), ["pay"])
        XCTAssertEqual(action.id, "a-1")
        XCTAssertEqual(action.delayMs, 20)
        XCTAssertNil(reply)
    }

    func testAnAwaitInputStepMayCarryNoLayers() throws {
        guard case let .awaitInput(state, layers, _) = try decode(#"{"kind": "awaitInput", "state": {}}"#) else {
            return XCTFail("expected awaitInput")
        }
        XCTAssertTrue(state.isEmpty)
        XCTAssertTrue(layers.isEmpty)
    }

    func testAFinishedStepNamesTheOutcome() throws {
        for outcome in ["success", "cancelled", "error"] {
            guard case let .finished(decoded, _) = try decode(#"{"kind": "finished", "outcome": "\#(outcome)"}"#) else {
                return XCTFail("expected finished")
            }
            XCTAssertEqual(decoded.rawValue, outcome)
        }
        XCTAssertThrowsError(try decode(#"{"kind": "finished", "outcome": "maybe"}"#))
    }

    func testAFailedStepCarriesTheEnginesError() throws {
        let step = try decode(#"{"kind": "failed", "error": {"code": "STEP_NOT_FOUND", "message": "no 'pay'", "diagnosticsId": "d-1"}}"#)
        guard case let .failed(error, _) = step else { return XCTFail("expected failed") }
        XCTAssertEqual(error.code, "STEP_NOT_FOUND")
        XCTAssertEqual(error.errorDescription, "State processor error [STEP_NOT_FOUND] (diagnosticsId=d-1): no 'pay'")
    }

    func testTheReplyAnswersTheEvent() throws {
        XCTAssertEqual(try decode(#"{"kind": "awaitInput", "state": {}, "reply": {"kind": "unhandled"}}"#).reply, .unhandled)
        XCTAssertEqual(
            try decode(#"{"kind": "awaitInput", "state": {}, "reply": {"kind": "handled", "value": {"orderId": "o-1"}}}"#).reply,
            .handled(value: .object(["orderId": .string("o-1")]))
        )
        XCTAssertEqual(try decode(#"{"kind": "finished", "outcome": "success", "reply": {"kind": "handled"}}"#).reply, .handled(value: nil))
        XCTAssertEqual(
            try decode(#"{"kind": "awaitInput", "state": {}, "reply": {"kind": "failed", "error": {"message": "boom"}}}"#).reply,
            .failed(message: "boom")
        )
    }

    func testAnUnknownKindOrAMissingStateFails() {
        XCTAssertThrowsError(try decode(#"{"kind": "someday"}"#))
        XCTAssertThrowsError(try decode(#"{"kind": "awaitInput"}"#))
        XCTAssertThrowsError(try decode(#"{"kind": "runAction", "state": {}}"#))
    }

    private func decode(_ json: String) throws -> FlowStep {
        try JSONDecoder().decode(FlowStep.self, from: Data(json.utf8))
    }
}
