//
//  CacheKeyTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CryptoKit
@testable import PrimerSDK
import XCTest

final class CacheKeyTests: XCTestCase {

    override func tearDown() {
        AppState.current.clientToken = nil
        super.tearDown()
    }

    func test_cacheKey_returnsNil_whenNoClientToken() {
        AppState.current.clientToken = nil
        XCTAssertNil(PrimerAPIConfigurationModule.cacheKey)
    }

    func test_cacheKey_returnsHashedValue_notRawToken() {
        let token = MockData.validClientToken
        AppState.current.clientToken = token

        let cacheKey = PrimerAPIConfigurationModule.cacheKey
        XCTAssertNotNil(cacheKey)
        XCTAssertNotEqual(cacheKey, token, "Cache key must not be the raw JWT token")
        XCTAssertTrue(cacheKey!.count <= 16, "Cache key should be a short hash prefix")
    }

    func test_cacheKey_isDeterministic() {
        let token = MockData.validClientToken
        AppState.current.clientToken = token

        let first = PrimerAPIConfigurationModule.cacheKey
        let second = PrimerAPIConfigurationModule.cacheKey
        XCTAssertEqual(first, second, "Same token must produce the same cache key")
    }

    func test_cacheKey_matchesExpectedSHA256Prefix() {
        let token = MockData.validClientToken
        AppState.current.clientToken = token

        let expected = SHA256.hash(data: Data(token.utf8))
            .prefix(8)
            .map { String(format: "%02x", $0) }
            .joined()

        XCTAssertEqual(PrimerAPIConfigurationModule.cacheKey, expected)
    }

    func test_sdkProperties_doesNotContainClientToken() throws {
        // Decode SDKProperties from JSON (fileprivate init not accessible from tests)
        let json = """
        {"sdkType":"IOS_NATIVE","sdkVersion":"1.0","integrationType":"SPM"}
        """
        let properties = try JSONDecoder().decode(SDKProperties.self, from: Data(json.utf8))
        let encoded = try JSONEncoder().encode(properties)
        let dict = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        XCTAssertNil(dict?["clientToken"], "SDKProperties must not include clientToken")
    }
}

private enum MockData {
    // A valid 3-segment JWT that decodes to a token with a future expiry
    // Header: {"alg":"HS256","typ":"JWT"}
    // Payload includes exp:4102444800 (year 2100)
    // swiftlint:disable:next line_length
    static let validClientToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2Nlc3NUb2tlbiI6InRlc3QiLCJlbnYiOiJTQU5EQk9YIiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuZXhhbXBsZS5jb20iLCJpbnRlbnQiOiJjaGVja291dCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2NvbmZpZy5leGFtcGxlLmNvbSIsImNvcmVVcmwiOiJodHRwczovL2NvcmUuZXhhbXBsZS5jb20iLCJwY2lVcmwiOiJodHRwczovL3BjaS5leGFtcGxlLmNvbSIsImV4cCI6NDEwMjQ0NDgwMH0.signature"
}
