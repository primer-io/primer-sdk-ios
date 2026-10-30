//
//  BackendDrivenCheckoutLoggerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerStepResolver
import XCTest

final class BackendDrivenCheckoutLoggerTests: XCTestCase {

    private var resolver: CapturingStepResolver!

    override func setUp() async throws {
        try await super.setUp()
        resolver = CapturingStepResolver()
        PrimerStepResolverRegistry.shared.register(resolver, for: .platformLog)
    }

    override func tearDown() async throws {
        await DIContainer.clearContainer()
        PrimerStepResolverRegistry.shared.register(Analytics.Service.shared, for: .platformLog)
        try await super.tearDown()
    }

    func testLogRunsNoPlatformLogStepWithoutCheckoutComponents() async throws {
        await DIContainer.clearContainer()

        BackendDrivenCheckoutLogger.log("BDC flow started.", type: .backendDrivenCheckoutStarted, severity: .info)

        try await Task.sleep(nanoseconds: 200_000_000)
        let steps = await resolver.steps
        XCTAssertTrue(steps.isEmpty)
    }

    func testLogRunsAPlatformLogStepWithCheckoutComponents() async throws {
        await DIContainer.setContainer(Container())

        BackendDrivenCheckoutLogger.log(
            "BDC Failed",
            type: .backendDrivenCheckoutFailed,
            severity: .error,
            diagnosticsId: "diag-1",
            context: ["paymentMethodType": "KLARNA"]
        )

        let step = try await waitForStep()
        let properties = try XCTUnwrap(step.object?["properties"]?.object)
        XCTAssertEqual(properties["messageType"], .string("BDC_FLOW_FAILED"))
        XCTAssertEqual(properties["message"], .string("BDC Failed"))
        XCTAssertEqual(properties["severity"], .string("error"))
        XCTAssertEqual(properties["context"]?.object?["paymentMethodType"], .string("KLARNA"))
        XCTAssertEqual(properties["context"]?.object?["diagnosticsId"], .string("diag-1"))
    }

    func testWarningRunsAsAWarnPlatformLog() async throws {
        await DIContainer.setContainer(Container())

        BackendDrivenCheckoutLogger.log(
            "Client requirements not met",
            type: .backendDrivenClientRequirementsNotMet,
            severity: .warning
        )

        let step = try await waitForStep()
        XCTAssertEqual(step.object?["properties"]?.object?["severity"], .string("warn"))
    }
}

private extension BackendDrivenCheckoutLoggerTests {
    func waitForStep() async throws -> CodableValue {
        for _ in 0..<50 {
            if let step = await resolver.steps.first { return step }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let steps = await resolver.steps
        return try XCTUnwrap(steps.first)
    }
}

private extension CodableValue {
    var object: [String: CodableValue]? {
        if case let .object(object) = self { return object }
        return nil
    }
}

private final actor CapturingStepResolver: StepResolver {
    private(set) var steps: [CodableValue] = []

    func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
        steps.append(data)
        return StepResolutionResult(outcome: .success)
    }
}
