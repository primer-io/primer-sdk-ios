//
//  File.swift
//  
//
//  Created by Niall Quinn on 01/08/24.
//

import XCTest
@testable import PrimerSDK

final class ConfigurationCacheTests: XCTestCase {
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
