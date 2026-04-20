//
//  AnalyticsServiceBDCTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import PrimerStepResolver
import XCTest

final class AnalyticsServiceBDCTests: XCTestCase {
    private var sut: Analytics.Service!
    private var apiClient: MockPrimerAPIAnalyticsClient!
    private var storage: MockAnalyticsStorage!

    override func setUp() {
        apiClient = MockPrimerAPIAnalyticsClient()
        storage = MockAnalyticsStorage()
        let url = URL(string: "http://localhost/")!
        sut = Analytics.Service(sdkLogsUrl: url, batchSize: 1, storage: storage, apiClient: apiClient)
    }

    override func tearDown() async throws {
        sut = nil
        storage = nil
        apiClient = nil
    }

    func testResolveFiresEventWithDecodedTypeAndProperties() async throws {
        let sent = expectation(description: "Event sent")
        let dict: CodableValue = .object(
            [
                "eventType": .string("SDK_FUNCTION_EVENT"),
                "properties": .object(["name": .string("test")])
            ]
        )
        apiClient.onSendRawAnalyticsEvent = { data in
            let decoded = try? JSONDecoder().decode([CodableValue].self, from: data)
            XCTAssertEqual(decoded?.first, dict)
            sent.fulfill()
        }
        _ = try await sut.resolve(dict)
        await fulfillment(of: [sent], timeout: 5)
    }

    func testRegistersAsPlatformLogResolver() async throws {
        let result = try await PrimerStepResolverRegistry.shared.resolve("platform.log", params: .null)
        XCTAssertEqual(result.outcome, .success)
    }
}
