//
//  ClientRequirementsSettlerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
import XCTest

@MainActor
final class ClientRequirementsSettlerTests: XCTestCase {

    func testGivesEachItemItsVerdictById() async throws {
        let engine = MockBDCEngine()
        engine.verdicts = [
            "pm_1": ClientRequirementsCheck(satisfied: true),
            "pm_2": ClientRequirementsCheck(satisfied: false)
        ]
        let items = [item("pm_1"), item("pm_2")]

        let verdicts = try await ClientRequirementsSettler(engine: engine).settle(items, client: client)

        XCTAssertEqual(verdicts, engine.verdicts)
        XCTAssertEqual(engine.checkedItems, items)
    }

    func testFailsWhenTheCheckFails() async {
        let engine = MockBDCEngine()
        engine.checkError = Failure.checkFailed

        do {
            _ = try await ClientRequirementsSettler(engine: engine).settle([item("pm_1")], client: client)
            XCTFail("Expected the check to fail")
        } catch {
            XCTAssertEqual(error as? Failure, .checkFailed)
        }
    }
}

private enum Failure: Error {
    case checkFailed
}

private func item(_ id: String) -> ClientRequirementsItem {
    ClientRequirementsItem(id: id, type: "KLARNA", clientRequirements: nil)
}

private let client = BDCClient(
    capabilities: SDKCapabilities(stepTypes: ["url.open": "1.0.0"]),
    context: SDKContext(
        sdk: SDK(type: "IOS_NATIVE", version: "1.0.0", integrationType: "DROP_IN", paymentHandling: "AUTO"),
        device: SDKDevice(
            platform: "IOS",
            type: nil,
            make: "Apple",
            model: "iPhone",
            modelIdentifier: nil,
            platformVersion: "18.0",
            uniqueDeviceIdentifier: "test",
            locale: "en"
        ),
        app: SDKApp(identifier: "com.test"),
        session: SDKSession(checkoutSessionId: nil, clientSessionId: nil, customerId: nil),
        payment: nil,
        merchant: SDKMerchant(primerAccountId: nil),
        analytics: SDKAnalytics(url: nil)
    )
)
