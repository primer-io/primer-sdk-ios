//
//  ConfigurationCacheTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class ConfigurationCacheTests: XCTestCase {

    override func tearDown() {
        ConfigurationCache.shared.clearCache()
    }

    func test_useHeadersTTL() throws {
        let headers = [ConfigurationCachedData.CacheHeaderKey: "2000"]
        let cacheData = ConfigurationCachedData(config: PrimerAPIConfiguration.mock, headers: headers)

        XCTAssert(cacheData.ttl == 2000)
    }

    func test_useFallbackTTL() throws {
        let headers = ["content-type": "application/json"]
        let cacheData = ConfigurationCachedData(config: PrimerAPIConfiguration.mock, headers: headers)

        XCTAssert(cacheData.ttl == ConfigurationCachedData.FallbackCacheExpiration)
    }

    func test_clearCache() throws {
        let settings = PrimerSettings(clientSessionCachingEnabled: true)
        let exp = self.expectation(description: "Wait for headless start")
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: "", settings: settings) { _, _ in
            exp.fulfill()
        }

        wait(for: [exp])

        let cache = ConfigurationCache()

        let headers = [ConfigurationCachedData.CacheHeaderKey: "2000"]
        let cacheData = ConfigurationCachedData(config: PrimerAPIConfiguration.mock, headers: headers)
        let cacheKey = "cache-key"
        cache.setData(cacheData, forKey: cacheKey)

        XCTAssertNotNil(cache.data(forKey: cacheKey))

        cache.clearCache()
        XCTAssertNil(cache.data(forKey: cacheKey))
    }

    func test_expiredTTL() throws {
        let cache = ConfigurationCache()

        let headers = [ConfigurationCachedData.CacheHeaderKey: "0"]
        let cacheData = ConfigurationCachedData(config: PrimerAPIConfiguration.mock, headers: headers)
        let cacheKey = "cache-key"

        cache.setData(cacheData, forKey: cacheKey)

        XCTAssertNil(cache.data(forKey: cacheKey))
    }

    func test_respectsPrimerSettingsFlag() {
        let settings = PrimerSettings(clientSessionCachingEnabled: false)
        let exp = self.expectation(description: "Wait for headless start")
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: "", settings: settings) { _, _ in
            exp.fulfill()
        }

        wait(for: [exp])

        let cache = ConfigurationCache()

        let headers = [ConfigurationCachedData.CacheHeaderKey: "2000"]
        let cacheData = ConfigurationCachedData(config: PrimerAPIConfiguration.mock, headers: headers)
        let cacheKey = "cache-key"
        cache.setData(cacheData, forKey: cacheKey)

        XCTAssertNil(cache.data(forKey: cacheKey))
    }

}

private extension PrimerAPIConfiguration {
    static var mock: PrimerAPIConfiguration {
        .init(coreUrl: "",
              pciUrl: "",
              binDataUrl: "",
              assetsUrl: "",
              clientSession: nil,
              paymentMethods: nil,
              primerAccountId: "",
              keys: nil,
              checkoutModules: nil)
    }
}
