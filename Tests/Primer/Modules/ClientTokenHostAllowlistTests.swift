//
//  ClientTokenHostAllowlistTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking
@_spi(PrimerInternal) @testable import PrimerSDK
import XCTest

final class ClientTokenHostAllowlistTests: XCTestCase {

    private let foreignUrls = [
        "https://evil.com",
        "https://primer.io.evil.com",
        "https://evilprimer.io",
        "http://api.primer.io",
        "https://primer.io@evil.com",
        "not a url"
    ]

    override func setUp() {
        super.setUp()
        resetGlobalState()
    }

    override func tearDown() {
        resetGlobalState()
        super.tearDown()
    }

    private func resetGlobalState() {
        ConfigurationCache.shared.clearCache()
        PrimerAPIConfigurationModule.resetSession()
        PrimerAPIConfigurationModule.apiClient = nil
    }

    // MARK: - isPrimerURL

    func test_isPrimerURL_acceptsPrimerHosts() {
        [
            "https://primer.io",
            "https://api.primer.io/client-sdk/configuration",
            "https://sdk.api.sandbox.primer.io",
            "https://analytics.production.data.primer.io/checkout/track",
            "HTTPS://API.PRIMER.IO"
        ].forEach { XCTAssertTrue($0.isPrimerURL, $0) }
    }

    func test_isPrimerURL_rejectsForeignHostsAndPlainHttp() {
        foreignUrls.forEach { XCTAssertFalse($0.isPrimerURL, $0) }
    }

    // MARK: - setupSession

    func test_setupSession_acceptsTokenWithPrimerUrls() async throws {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchConfigurationResult = (PrimerAPIConfiguration(
            coreUrl: "https://api.sandbox.primer.io",
            pciUrl: "https://sdk.api.sandbox.primer.io",
            binDataUrl: nil,
            assetsUrl: nil,
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        ), nil)
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        let token = try makeToken { _ in }

        try await PrimerAPIConfigurationModule().setupSession(forClientToken: token)

        XCTAssertEqual(PrimerAPIConfigurationModule.clientToken, token)
    }

    func test_setupSession_rejectsForeignUrlInEveryTokenField_beforeAnyRequest() async throws {
        let fields: [(String, WritableKeyPath<DecodedJWTToken, String?>)] = [
            ("configurationUrl", \.configurationUrl),
            ("coreUrl", \.coreUrl),
            ("pciUrl", \.pciUrl),
            ("analyticsUrl", \.analyticsUrl),
            ("analyticsUrlV2", \.analyticsUrlV2)
        ]

        for (name, keyPath) in fields {
            for url in foreignUrls {
                resetGlobalState()
                // No results are set, so any request fails the test inside the mock.
                PrimerAPIConfigurationModule.apiClient = MockPrimerAPIClient()
                let token = try makeToken { $0[keyPath: keyPath] = url }

                do {
                    try await PrimerAPIConfigurationModule().setupSession(forClientToken: token)
                    XCTFail("\(name) = \(url) should be rejected")
                } catch {
                    guard case .invalidClientToken = error as? PrimerError else {
                        return XCTFail("\(name) = \(url): unexpected error \(error)")
                    }
                }
                XCTAssertNil(PrimerAPIConfigurationModule.clientToken, "\(name) = \(url)")
            }
        }
    }

    // MARK: - Stored analytics events

    func test_flush_deletesStoredEventsWithForeignUrl_withoutSendingThem() async throws {
        let apiClient = MockPrimerAPIAnalyticsClient()
        let storage = MockAnalyticsStorage()
        let sut = Analytics.Service(
            sdkLogsUrl: URL(string: "https://analytics.production.data.primer.io/sdk-logs")!,
            batchSize: 5,
            storage: storage,
            apiClient: apiClient
        )

        PrimerAPIConfigurationModule.clientToken = try makeToken { $0.analyticsUrlV2 = "https://evil.com/track" }
        let foreignEvent = Analytics.Event.sdk(name: "foreign", params: nil)
        PrimerAPIConfigurationModule.clientToken = try makeToken { _ in }
        let primerEvent = Analytics.Event.sdk(name: "primer", params: nil)
        try storage.save([.sdk(foreignEvent), .sdk(primerEvent)])

        try await sut.flush()

        XCTAssertEqual(apiClient.batches.joined().map(\.localId), [primerEvent.localId])
        XCTAssertTrue(storage.events.isEmpty)
    }

    // MARK: - Helpers

    private func makeToken(_ modify: (inout DecodedJWTToken) -> Void) throws -> String {
        var token = try DecodedJWTToken.createMock(
            coreUrl: "https://api.sandbox.primer.io",
            configurationUrl: "https://api.sandbox.primer.io/client-sdk/configuration",
            pciUrl: "https://sdk.api.sandbox.primer.io"
        )
        token.analyticsUrl = "https://analytics.api.sandbox.core.primer.io/mixpanel"
        token.analyticsUrlV2 = "https://analytics.sandbox.data.primer.io/checkout/track"
        modify(&token)
        // DecodedJWTToken's encoder drops the analytics URLs, so write them into the payload directly.
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(token)) as? [String: Any])
        payload["analyticsUrl"] = token.analyticsUrl
        payload["analyticsUrlV2"] = token.analyticsUrlV2
        let segment = try JSONSerialization.data(withJSONObject: payload).base64EncodedString()
        return "header.\(segment).signature"
    }
}
