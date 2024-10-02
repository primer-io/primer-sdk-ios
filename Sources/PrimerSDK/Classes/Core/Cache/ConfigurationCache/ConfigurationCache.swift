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
        guard cachingEnabled else { return nil }
        return Self.queue.sync(flags: .barrier) { [weak self] in
            guard let self = self else {
                return nil
            }
            if let cachedData = cache.value(forKey: key) {
                if validateCachedConfig(key: key, cachedData: cachedData) == false {
                    cache.removeValue(forKey: key)
                    return nil
                }
                return cachedData
            }
            return nil
        }
    }

    func setData(_ data: ConfigurationCachedData, forKey key: String) {
        guard cachingEnabled else { return }
        return Self.queue.sync(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }
            // Cache includes at most one cached configuration
            clearCache()
            cache.insert(data, forKey: key)
        }
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

    private var cachingEnabled: Bool {
        PrimerSettings.current.clientSessionCachingEnabled
    }

    private static let queue: DispatchQueue = DispatchQueue(label: "primer.configurationCache", qos: .default)
}

class ConfigurationCachedData {

    let config: PrimerAPIConfiguration
    let timestamp: TimeInterval
    let ttl: TimeInterval

    init(config: PrimerAPIConfiguration, headers: [String: String]? = nil) {
        // Extract ttl from headers
        self.config = config
        self.timestamp = Date().timeIntervalSince1970
        self.ttl = Self.extractTtlFromHeaders(headers)
    }

    static let FallbackCacheExpiration: TimeInterval = 0
    static let CacheHeaderKey = "x-primer-session-cache-ttl"

    private static func extractTtlFromHeaders(_ headers: [String: String]?) -> TimeInterval {
        guard let headers,
              let ttlHeaderValue = headers[Self.CacheHeaderKey],
              let ttlInt = Int(ttlHeaderValue) else {
            return Self.FallbackCacheExpiration
        }
        return TimeInterval(ttlInt)
    }
}
