//
//  AppLinkConfigProviderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  AppLinkConfigProviderTests.swift
//  Debug App Tests
//
//  Created by Niall Quinn on 15/04/2025.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

@testable import Debug_App
import XCTest

final class AppLinkConfigProviderTests: XCTestCase {

    class MockPayloadProvider: AppLinkPayloadProviding {
        var clientToken: String?
        var settingsJwt: String?

        init(clientToken: String? = nil, settingsJwt: String? = nil) {
            self.clientToken = clientToken
            self.settingsJwt = settingsJwt
        }
    }

    func testFetchClientToken_WhenTokenExists_ReturnsToken() {
        let mockToken = "mock-client-token"
        let provider = AppLinkConfigProvider(payloadProvider: MockPayloadProvider(clientToken: mockToken))

        let result = provider.fetchClientToken()

        XCTAssertEqual(result, mockToken)
    }

    func testFetchClientToken_WhenTokenIsNil_ReturnsNil() {
        let provider = AppLinkConfigProvider(payloadProvider: MockPayloadProvider(clientToken: nil))

        let result = provider.fetchClientToken()

        XCTAssertNil(result)
    }

    func testFetchConfig_WhenSettingsJwtIsNil_ReturnsNil() {
        let provider = AppLinkConfigProvider(payloadProvider: MockPayloadProvider(settingsJwt: nil))

        let result = provider.fetchConfig()

        XCTAssertNil(result)
    }

    func testFetchConfig_WhenJwtIsInvalid_ReturnsNil() {
        let invalidJwt = "invalid.jwt.string"
        let provider = AppLinkConfigProvider(payloadProvider: MockPayloadProvider(settingsJwt: invalidJwt))

        let result = provider.fetchConfig()

        XCTAssertNil(result)
    }

    func testFetchConfig_WhenJwtIsValid_ReturnsSettings() throws {
        let rnSettings = RNPrimerSettings() // Fill with actual required values for valid settings
        let data = try JSONEncoder().encode(rnSettings)
        let jwt = data.base64EncodedString()
        let provider = AppLinkConfigProvider(payloadProvider: MockPayloadProvider(settingsJwt: jwt))

        let result = provider.fetchConfig()

        XCTAssertNotNil(result)
    }

    func testSettingsFailure_DescribesWhyConfigIsNil() throws {
        let validJwt = try JSONEncoder().encode(RNPrimerSettings()).base64EncodedString()

        XCTAssertEqual(AppLinkConfigProvider(payloadProvider: MockPayloadProvider()).settingsFailure, "settings missing")
        XCTAssertEqual(AppLinkConfigProvider(payloadProvider: MockPayloadProvider(settingsJwt: "not-base64!")).settingsFailure,
                       "settings decode failed")
        XCTAssertNil(AppLinkConfigProvider(payloadProvider: MockPayloadProvider(settingsJwt: validJwt)).settingsFailure)
    }

    func testDemo_DefaultsToNilForProvidersWithoutOne() {
        XCTAssertNil(AppLinkConfigProvider(payloadProvider: MockPayloadProvider(clientToken: "token")).demo)
    }

    // MARK: - SDKDemoUrlHandler

    override func tearDown() {
        _ = SDKDemoUrlHandler.consumePendingPayload()
        super.tearDown()
    }

    func testHandleUrl_IgnoresOtherHosts() {
        XCTAssertFalse(SDKDemoUrlHandler.handleUrl(URL(string: "primer://other.host/?clientToken=t&settings=s")!))
        XCTAssertFalse(SDKDemoUrlHandler.handleUrl(URL(string: "primer://ui-tests/dismiss?x=sdk-demo.primer.io")!))
        XCTAssertNil(SDKDemoUrlHandler.consumePendingPayload())
    }

    func testHandleUrl_KeepsEveryParameterAsPendingPayload() {
        let url = URL(string: "primer://sdk-demo.primer.io/latest/ios?clientToken=token&settings=blob&demo=inline_card_form")!

        XCTAssertTrue(SDKDemoUrlHandler.handleUrl(url))

        let payload = SDKDemoUrlHandler.consumePendingPayload()
        XCTAssertEqual(payload?.clientToken, "token")
        XCTAssertEqual(payload?.settingsJwt, "blob")
        XCTAssertEqual(payload?.demo, "inline_card_form")
        XCTAssertNil(SDKDemoUrlHandler.consumePendingPayload(), "the payload is consumed once")
    }

    func testHandleUrl_AcceptsPartialLinksSoTheReceiverCanReportThem() {
        XCTAssertTrue(SDKDemoUrlHandler.handleUrl(URL(string: "https://sdk-demo.primer.io/?demo=default_checkout")!))

        let payload = SDKDemoUrlHandler.consumePendingPayload()
        XCTAssertNil(payload?.clientToken)
        XCTAssertNil(payload?.settingsJwt)
        XCTAssertEqual(payload?.demo, "default_checkout")
    }

    func testHandleUrl_PostsTheNotification() {
        let expectation = expectation(forNotification: .appetizeURLHandled, object: nil)

        SDKDemoUrlHandler.handleUrl(URL(string: "primer://sdk-demo.primer.io/?clientToken=t&settings=s")!)

        wait(for: [expectation], timeout: 1)
    }
}
