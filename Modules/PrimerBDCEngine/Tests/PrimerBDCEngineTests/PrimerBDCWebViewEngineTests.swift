//
//  PrimerBDCWebViewEngineTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver
import XCTest

@MainActor
@available(iOS 15.0, *)
final class PrimerBDCWebViewEngineTests: XCTestCase {

    func testStartRunsTheStateProcessorOnTheInstantiatedModule() async throws {
        let sut = try await PrimerBDCWebViewEngine(files: .stub())

        let result = try await sut.start(schema: "schema", context: .stub, state: .object(["step": .int(1)]))

        XCTAssertEqual(result["call"] as? String, "initialize")
        XCTAssertEqual(result["schema"] as? String, "schema")
        XCTAssertEqual(result["sdkType"] as? String, "IOS_NATIVE")
        XCTAssertEqual((result["state"] as? AnyDict)?["step"] as? Int, 1)
        XCTAssertEqual(result["instantiated"] as? Bool, true)
    }

    func testApplyEventPassesTheStateAndTheEvent() async throws {
        let sut = try await PrimerBDCWebViewEngine(files: .stub())

        let result = try await sut.applyEvent(.object(["type": .string("tap")]), context: .stub, schema: "schema", state: ["step": 2])

        XCTAssertEqual(result["call"] as? String, "applyEvent")
        XCTAssertEqual((result["state"] as? AnyDict)?["step"] as? Int, 2)
        XCTAssertEqual((result["event"] as? AnyDict)?["type"] as? String, "tap")
    }

    func testApplyResultPassesTheActionOutcomeAndData() async throws {
        let sut = try await PrimerBDCWebViewEngine(files: .stub())

        let result = try await sut.applyResult(
            schema: "schema",
            context: .stub,
            actionId: "action",
            state: [:],
            outcome: "success",
            data: Data(#"{"token":"abc"}"#.utf8)
        )

        XCTAssertEqual(result["call"] as? String, "applyResult")
        XCTAssertEqual(result["actionId"] as? String, "action")
        XCTAssertEqual(result["outcome"] as? String, "success")
        XCTAssertEqual((result["data"] as? AnyDict)?["token"] as? String, "abc")
    }

    func testAStateProcessorErrorIsReturnedAsTheResult() async throws {
        let sut = try await PrimerBDCWebViewEngine(files: .stub())

        let result = try await sut.start(schema: "throw", context: .stub, state: .null)

        XCTAssertEqual(result["error"] as? String, "Error: bad schema")
    }

    func testProbesToRunDecodesTheRequests() async throws {
        let sut = try await PrimerBDCWebViewEngine(files: .stub())
        let items = [PaymentMethodRequirements(id: "method", type: "KLARNA", clientRequirements: nil)]

        let probes = try await sut.probesToRun(items: items, client: .stub)

        XCTAssertEqual(probes, [ProbeRequest(key: "method", probe: "canOpenURL", params: .object([:]))])
    }

    func testCheckClientRequirementsReturnsAVerdictPerMethod() async throws {
        let sut = try await PrimerBDCWebViewEngine(files: .stub())
        let items = [PaymentMethodRequirements(id: "method", type: "KLARNA", clientRequirements: nil)]
        let results = ["method": ProbeResult(outcome: .success)]

        let verdicts = try await sut.checkClientRequirements(items: items, client: .stub, results: results)

        XCTAssertEqual(verdicts, ["method": ClientRequirementsVerdict(satisfied: true)])
    }

    func testLoadFailsWhenTheModuleCannotBeInstantiated() async {
        do {
            _ = try await PrimerBDCWebViewEngine(files: .stub(wasm: Data([1, 2, 3])))
            XCTFail("Expected the load to fail")
        } catch EngineError.loadFailed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReloadsAfterTheWebContentProcessIsTerminated() async throws {
        let sut = try await PrimerBDCWebViewEngine(files: .stub())
        _ = try await sut.webView.evaluateJavaScript("globalThis.__instantiated = false; true", in: nil, contentWorld: .page)

        sut.webViewWebContentProcessDidTerminate(sut.webView)
        let result = try await sut.start(schema: "schema", context: .stub, state: .null)

        XCTAssertEqual(result["instantiated"] as? Bool, true)
    }
}
