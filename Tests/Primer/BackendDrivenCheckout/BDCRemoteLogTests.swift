//
//  BDCRemoteLogTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerBDCEngine
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerSDK
import XCTest

actor MockRemoteLoggingService: ComponentsLoggingServiceProtocol {
    struct Entry {
        let status: String
        let message: String
        let event: String?
        let errorMessage: String?
        let userInfo: [String: Any]?
    }

    private(set) var entries: [Entry] = []

    func logInfo(message: String, event: String, userInfo: [String: Any]?) async {
        entries.append(Entry(status: "info", message: message, event: event, errorMessage: nil, userInfo: userInfo))
    }

    func logWarning(message: String, event: String, userInfo: [String: Any]?) async {
        entries.append(Entry(status: "warn", message: message, event: event, errorMessage: nil, userInfo: userInfo))
    }

    func logError(message: String, event: String?, errorMessage: String?, stack: String?, userInfo: [String: Any]?) async {
        entries.append(Entry(status: "error", message: message, event: event, errorMessage: errorMessage, userInfo: userInfo))
    }

    func entries(count: Int, timeout: TimeInterval = 2) async -> [Entry] {
        let deadline = Date().addingTimeInterval(timeout)
        while entries.count < count, Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        return entries
    }
}

final class BDCRemoteLogTests: XCTestCase {
    private var service: MockRemoteLoggingService!
    private var sut: BDCRemoteLog!

    private let method = PrimerPaymentMethod(
        id: "bdc_id", implementationType: .nativeSdk,
        type: "MOCK_BDC", name: "Mock BDC",
        processorConfigId: "pid", surcharge: nil, options: nil, displayMetadata: nil
    )

    override func setUp() {
        super.setUp()
        service = MockRemoteLoggingService()
        sut = BDCRemoteLog(service: service, clientToken: { "client-token" })
    }

    override func tearDown() {
        sut = nil
        service = nil
        super.tearDown()
    }

    func testFlowStartedCarriesTheMethodEntryAndFingerprints() async {
        await sut.flowStarted(method, trustedKeyFingerprints: ["abc"])

        let entry = await service.entries.first
        XCTAssertEqual(entry?.status, "info")
        XCTAssertEqual(entry?.event, "bdc-flow-started")
        XCTAssertEqual(entry?.userInfo?["payment_method_type"] as? String, "MOCK_BDC")
        XCTAssertEqual(entry?.userInfo?["entry"] as? String, method.entry.rawValue)
        XCTAssertEqual(entry?.userInfo?["trusted_key_fingerprints"] as? [String], ["abc"])
    }

    func testASuccessfulEndIsInfoWithoutErrorFields() async {
        await sut.flowEnded(method, outcome: BDCRemoteLog.Outcome.success, error: nil)

        let entry = await service.entries.first
        XCTAssertEqual(entry?.status, "info")
        XCTAssertEqual(entry?.event, "bdc-flow-ended")
        XCTAssertEqual(entry?.userInfo?["outcome"] as? String, "success")
        XCTAssertNil(entry?.userInfo?["error_id"])
    }

    func testAFailedEndIsAWarningWithTheErrorId() async {
        let error = PrimerError.paymentFailed(
            paymentMethodType: "MOCK_BDC", paymentId: "pay_1", orderId: "ord_1", status: "FAILED", diagnosticsId: "diag_1"
        )
        await sut.flowEnded(method, outcome: BDCRemoteLog.Outcome.error, error: error)

        let entry = await service.entries.first
        XCTAssertEqual(entry?.status, "warn")
        XCTAssertEqual(entry?.userInfo?["outcome"] as? String, "error")
        XCTAssertEqual(entry?.userInfo?["error_id"] as? String, error.errorId)
        XCTAssertEqual(entry?.userInfo?["diagnostics_id"] as? String, "diag_1")
        XCTAssertEqual(entry?.userInfo?["error_message"] as? String, error.errorDescription)
    }

    func testRequirementsNotMetListsEachUnmetRequirement() async {
        let unmet = [
            UnmetClientRequirement(kind: "capability", name: "klarna.widget", required: "1.0.0", reason: "missing"),
            UnmetClientRequirement(kind: "probe", type: "app", name: "installed", available: "false", reason: "unavailable")
        ]
        await sut.requirementsNotMet(method, unmet: unmet)

        let entry = await service.entries.first
        XCTAssertEqual(entry?.status, "warn")
        XCTAssertEqual(entry?.event, "bdc-requirements-not-met")
        XCTAssertEqual(entry?.userInfo?["payment_method_type"] as? String, "MOCK_BDC")
        let fields = entry?.userInfo?["unmet"] as? [[String: String]]
        XCTAssertEqual(fields?.count, 2)
        XCTAssertEqual(fields?.first?["name"], "klarna.widget")
        XCTAssertEqual(fields?.first?["required"], "1.0.0")
        XCTAssertNil(fields?.first?["type"])
        XCTAssertEqual(fields?.last?["available"], "false")
    }

    func testEngineLoadFailedIsAnErrorWithTheCause() async {
        struct LoadError: Error {}
        await sut.engineLoadFailed(LoadError())

        let entry = await service.entries.first
        XCTAssertEqual(entry?.status, "error")
        XCTAssertEqual(entry?.event, "bdc-engine-load-failed")
        XCTAssertEqual(entry?.errorMessage, "LoadError()")
    }

    func testEveryLogInitialisesTheSessionWithTheClientToken() async {
        await LoggingSessionContext.shared.initialize(
            environment: .sandbox, sdkVersion: "0", clientSessionToken: nil, integrationType: .swiftUI
        )

        await sut.flowStarted(method, trustedKeyFingerprints: [])

        let session = await LoggingSessionContext.shared.getSessionData()
        XCTAssertEqual(session.clientSessionToken, "client-token")
        XCTAssertEqual(session.integrationType, .swiftUI)
    }

    func testNoClientTokenLeavesTheSessionAlone() async {
        await LoggingSessionContext.shared.initialize(
            environment: .sandbox, sdkVersion: "0", clientSessionToken: "existing", integrationType: nil
        )
        sut = BDCRemoteLog(service: service, clientToken: { nil })

        await sut.flowStarted(method, trustedKeyFingerprints: [])

        let session = await LoggingSessionContext.shared.getSessionData()
        XCTAssertEqual(session.clientSessionToken, "existing")
        let count = await service.entries.count
        XCTAssertEqual(count, 1)
    }
}
