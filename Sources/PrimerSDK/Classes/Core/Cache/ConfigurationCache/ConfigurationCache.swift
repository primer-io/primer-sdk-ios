//
//  ConfigurationCache.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 31/07/24.
//

import Foundation

protocol ConfigurationCaching {
    func clearCache()
    func setData(_ data: ConfigurationCachedData, forKey key: String)
    func data(forKey key: String) -> ConfigurationCachedData?
}

class ConfigurationCache: ConfigurationCaching {
    static let shared = ConfigurationCache()
    private var cache = Cache<String, ConfigurationCachedData>()

    func clearCache() {
        cache = Cache<String, ConfigurationCachedData>()
    }

    func data(forKey key: String) -> ConfigurationCachedData? {
        if let cachedData = cache.value(forKey: key) {
            if validateCachedConfig(key: key, cachedData: cachedData) == false {
                cache.removeValue(forKey: key)
                return nil
            }
            return cachedData
        }
        return nil
    }

    func setData(_ data: ConfigurationCachedData, forKey key: String) {
        // Cache includes at most one cached configuration
        clearCache()
        cache.insert(data, forKey: key)
    }

    private func validateCachedConfig(key: String, cachedData: ConfigurationCachedData) -> Bool {
        let timestamp = cachedData.timestamp
        let now = Date().timeIntervalSince1970
        let timeInterval = now - timestamp

        if timeInterval > cachedData.ttl {
            return false
        }

        return true
    }
}

class ConfigurationCachedData {
    let config: PrimerAPIConfiguration
    let timestamp: TimeInterval
    let ttl: TimeInterval

    init(config: PrimerAPIConfiguration, ttl: TimeInterval) {
        self.config = config
        self.timestamp = Date().timeIntervalSince1970
        self.ttl = ttl
    }

    init(config: PrimerAPIConfiguration, headers: [String: String]? = nil) {
        //Extract ttl from headers
        self.config = config
        self.timestamp = Date().timeIntervalSince1970
        self.ttl = Self.FallbackCacheExpiration
    }

    static let FallbackCacheExpiration: TimeInterval = 60 * 60 * 1000
}
