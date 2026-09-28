//
//  ClientRequirementsScriptTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import JavaScriptCore
@testable @_spi(PrimerInternal) import PrimerBDCEngine
import XCTest

@MainActor
final class ClientRequirementsScriptTests: XCTestCase {

    private let context = JSContext()!

    override func setUp() {
        super.setUp()
        context.evaluateScript("""
        globalThis.StateProcessor = {
            checkClientRequirements: async (requirements, client) => ({
                satisfied: requirements == null && client.context.sdk.type === 'IOS_NATIVE',
                unmet: []
            })
        };
        """)
        set("__items", #"[{"id":"p1","type":"KLARNA"},{"id":"p2","type":"TWINT","clientRequirements":{"stepTypes":{}}}]"#)
        set("__client", #"{"capabilities":{},"context":{"sdk":{"type":"IOS_NATIVE"}}}"#)
    }

    func testCheckAnswersWithEachItemsVerdictById() throws {
        let reply = try run(PrimerBDCEngine.checkClientRequirementsSource, callback: "onCheckClientRequirementsResult")

        XCTAssertEqual(reply, #"{"result":{"p1":{"satisfied":true,"unmet":[]},"p2":{"satisfied":false,"unmet":[]}}}"#)
    }

    func testAnswersWithTheErrorWhenTheProcessorThrows() throws {
        context.evaluateScript("StateProcessor.checkClientRequirements = async () => { throw new Error('boom'); };")

        let reply = try run(PrimerBDCEngine.checkClientRequirementsSource, callback: "onCheckClientRequirementsResult")

        XCTAssertEqual(reply, #"{"error":"Error: boom"}"#)
    }

    private func set(_ key: String, _ json: String) {
        context.setObject(json, forKeyedSubscript: key as NSString)
    }

    private func run(_ script: String, callback: String) throws -> String {
        var reply: String?
        let received = expectation(description: callback)
        let block: @convention(block) (String) -> Void = { json in
            reply = json
            received.fulfill()
        }
        context.setObject(block, forKeyedSubscript: callback as NSString)
        context.evaluateScript(script)
        wait(for: [received], timeout: 1)
        return try XCTUnwrap(reply)
    }
}
