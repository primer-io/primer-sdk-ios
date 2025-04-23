//
//  AppLinkConfigProviderTests.swift
//  Debug App Tests
//
//  Created by Niall Quinn on 15/04/2025.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

//
//  AppLinkConfigProviderTests.swift
//  Debug App Tests
//
//  Created by Niall Quinn on 15/04/2025.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import Debug_App

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

    func testFetchConfig_WhenJwtIsValid_ReturnsSettings() {
        let rnSettings = RNPrimerSettings() // Fill with actual required values for valid settings
        let data = try! JSONEncoder().encode(rnSettings)
        let jwt = data.base64EncodedString()
        let provider = AppLinkConfigProvider(payloadProvider: MockPayloadProvider(settingsJwt: jwt))

        let result = provider.fetchConfig()

        XCTAssertNotNil(result)
    }
}

