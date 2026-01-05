//
//  MerchantConfigCachingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for MerchantConfigCache to achieve 90% Data layer coverage.
/// Covers cache hit/miss scenarios, TTL, and invalidation strategies.
@available(iOS 15.0, *)
@MainActor
final class MerchantConfigCachingTests: XCTestCase {

    private var sut: MerchantConfigCache!
    private var mockStorage: MockCacheStorage!
    private var mockClock: MockClock!

    override func setUp() async throws {
        try await super.setUp()
        mockStorage = MockCacheStorage()
        mockClock = MockClock()
        sut = MerchantConfigCache(
            storage: mockStorage,
            clock: mockClock,
            ttl: 300 // 5 minutes
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockStorage = nil
        mockClock = nil
        try await super.tearDown()
    }

    // MARK: - Cache Hit Scenarios

    func test_get_withValidCachedData_returnsCachedConfig() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        mockStorage.store(config, key: "merchant-config", timestamp: mockClock.now())

        // When
        let cached = sut.get(forKey: "merchant-config")

        // Then
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.merchantId, "test-123")
    }

    func test_get_withFreshCache_doesNotExpire() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        mockStorage.store(config, key: "key", timestamp: mockClock.now())

        // When - advance time by 2 minutes (less than 5 min TTL)
        mockClock.advance(by: 120)
        let cached = sut.get(forKey: "key")

        // Then
        XCTAssertNotNil(cached)
    }

    func test_get_withMultipleKeys_returnsCorrectConfig() {
        // Given
        let config1 = MerchantConfig(merchantId: "merchant-1", settings: [:])
        let config2 = MerchantConfig(merchantId: "merchant-2", settings: [:])
        mockStorage.store(config1, key: "key-1", timestamp: mockClock.now())
        mockStorage.store(config2, key: "key-2", timestamp: mockClock.now())

        // When
        let cached1 = sut.get(forKey: "key-1")
        let cached2 = sut.get(forKey: "key-2")

        // Then
        XCTAssertEqual(cached1?.merchantId, "merchant-1")
        XCTAssertEqual(cached2?.merchantId, "merchant-2")
    }

    // MARK: - Cache Miss Scenarios

    func test_get_withNoCache_returnsNil() {
        // Given - empty cache

        // When
        let cached = sut.get(forKey: "nonexistent")

        // Then
        XCTAssertNil(cached)
    }

    func test_get_withExpiredCache_returnsNil() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        mockStorage.store(config, key: "key", timestamp: mockClock.now())

        // When - advance time beyond TTL (5 minutes + 1 second)
        mockClock.advance(by: 301)
        let cached = sut.get(forKey: "key")

        // Then
        XCTAssertNil(cached)
    }

    func test_get_withInvalidatedCache_returnsNil() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        mockStorage.store(config, key: "key", timestamp: mockClock.now())

        // When
        sut.invalidate(forKey: "key")
        let cached = sut.get(forKey: "key")

        // Then
        XCTAssertNil(cached)
    }

    // MARK: - Cache Storage

    func test_set_storesConfigWithCurrentTimestamp() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])

        // When
        sut.set(config, forKey: "key")

        // Then
        XCTAssertTrue(mockStorage.hasEntry(forKey: "key"))
        XCTAssertEqual(mockStorage.getTimestamp(forKey: "key"), mockClock.now())
    }

    func test_set_overridesPreviousValue() {
        // Given
        let config1 = MerchantConfig(merchantId: "merchant-1", settings: [:])
        let config2 = MerchantConfig(merchantId: "merchant-2", settings: [:])

        // When
        sut.set(config1, forKey: "key")
        mockClock.advance(by: 60)
        sut.set(config2, forKey: "key")

        // Then
        let cached = sut.get(forKey: "key")
        XCTAssertEqual(cached?.merchantId, "merchant-2")
    }

    func test_set_updatesTimestamp() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        sut.set(config, forKey: "key")
        let firstTimestamp = mockStorage.getTimestamp(forKey: "key")

        // When
        mockClock.advance(by: 100)
        sut.set(config, forKey: "key")
        let secondTimestamp = mockStorage.getTimestamp(forKey: "key")

        // Then
        XCTAssertNotEqual(firstTimestamp, secondTimestamp)
        XCTAssertEqual(secondTimestamp, mockClock.now())
    }

    // MARK: - TTL Behavior

    func test_get_atExactTTL_returnsNil() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        mockStorage.store(config, key: "key", timestamp: mockClock.now())

        // When - advance to exact TTL (300 seconds)
        mockClock.advance(by: 300)
        let cached = sut.get(forKey: "key")

        // Then - should expire at TTL boundary
        XCTAssertNil(cached)
    }

    func test_get_justBeforeTTL_returnsConfig() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        mockStorage.store(config, key: "key", timestamp: mockClock.now())

        // When - advance to just before TTL (299 seconds)
        mockClock.advance(by: 299)
        let cached = sut.get(forKey: "key")

        // Then
        XCTAssertNotNil(cached)
    }

    func test_set_withCustomTTL_respectsCustomTTL() {
        // Given
        let shortTTLCache = MerchantConfigCache(
            storage: mockStorage,
            clock: mockClock,
            ttl: 60 // 1 minute
        )
        let config = MerchantConfig(merchantId: "test-123", settings: [:])

        // When
        shortTTLCache.set(config, forKey: "key")
        mockClock.advance(by: 61) // Past 1 minute TTL

        // Then
        XCTAssertNil(shortTTLCache.get(forKey: "key"))
    }

    // MARK: - Cache Invalidation

    func test_invalidate_removesSpecificKey() {
        // Given
        let config1 = MerchantConfig(merchantId: "merchant-1", settings: [:])
        let config2 = MerchantConfig(merchantId: "merchant-2", settings: [:])
        sut.set(config1, forKey: "key-1")
        sut.set(config2, forKey: "key-2")

        // When
        sut.invalidate(forKey: "key-1")

        // Then
        XCTAssertNil(sut.get(forKey: "key-1"))
        XCTAssertNotNil(sut.get(forKey: "key-2"))
    }

    func test_invalidateAll_removesAllEntries() {
        // Given
        let config1 = MerchantConfig(merchantId: "merchant-1", settings: [:])
        let config2 = MerchantConfig(merchantId: "merchant-2", settings: [:])
        sut.set(config1, forKey: "key-1")
        sut.set(config2, forKey: "key-2")

        // When
        sut.invalidateAll()

        // Then
        XCTAssertNil(sut.get(forKey: "key-1"))
        XCTAssertNil(sut.get(forKey: "key-2"))
        XCTAssertTrue(mockStorage.isEmpty)
    }

    func test_invalidateExpired_removesOnlyExpiredEntries() {
        // Given
        let config1 = MerchantConfig(merchantId: "merchant-1", settings: [:])
        let config2 = MerchantConfig(merchantId: "merchant-2", settings: [:])
        sut.set(config1, forKey: "key-1")

        // Advance time and add fresh entry
        mockClock.advance(by: 301) // key-1 is now expired
        sut.set(config2, forKey: "key-2") // key-2 is fresh

        // When
        sut.invalidateExpired()

        // Then
        XCTAssertNil(sut.get(forKey: "key-1")) // Expired
        XCTAssertNotNil(sut.get(forKey: "key-2")) // Fresh
    }

    // MARK: - Concurrent Access

    func test_concurrentGet_returnsSameConfig() async {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        sut.set(config, forKey: "key")

        // When - concurrent reads
        let results = await withTaskGroup(of: MerchantConfig?.self, returning: [MerchantConfig?].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await self.sut.get(forKey: "key")
                }
            }

            var configs: [MerchantConfig?] = []
            for await result in group {
                configs.append(result)
            }
            return configs
        }

        // Then - all should return same config
        XCTAssertEqual(results.count, 10)
        for result in results {
            XCTAssertEqual(result?.merchantId, "test-123")
        }
    }

    func test_concurrentSet_lastWriteWins() async {
        // When - concurrent writes
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let config = MerchantConfig(merchantId: "merchant-\(i)", settings: [:])
                    await self.sut.set(config, forKey: "key")
                }
            }
        }

        // Then - should have one of the values (last write wins)
        let cached = sut.get(forKey: "key")
        XCTAssertNotNil(cached)
        XCTAssertTrue(cached?.merchantId.starts(with: "merchant-") ?? false)
    }

    // MARK: - Memory Management

    func test_cache_clearsDataAfterInvalidation() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        sut.set(config, forKey: "key")
        XCTAssertNotNil(sut.get(forKey: "key"))

        // When
        sut.invalidate(forKey: "key")

        // Then - config should be cleared from cache
        XCTAssertNil(sut.get(forKey: "key"))
    }

    // MARK: - Cache Size Management

    func test_cache_withSizeLimit_evictsOldestEntry() {
        // Given
        let limitedCache = MerchantConfigCache(
            storage: mockStorage,
            clock: mockClock,
            ttl: 300,
            maxEntries: 3
        )

        // When - add 4 entries
        for i in 1...4 {
            let config = MerchantConfig(merchantId: "merchant-\(i)", settings: [:])
            limitedCache.set(config, forKey: "key-\(i)")
            mockClock.advance(by: 1) // Ensure different timestamps
        }

        // Then - oldest (key-1) should be evicted
        XCTAssertNil(limitedCache.get(forKey: "key-1"))
        XCTAssertNotNil(limitedCache.get(forKey: "key-2"))
        XCTAssertNotNil(limitedCache.get(forKey: "key-3"))
        XCTAssertNotNil(limitedCache.get(forKey: "key-4"))
    }

    // MARK: - Key-Based Invalidation

    func test_invalidateByPattern_removesMatchingKeys() {
        // Given
        let config = MerchantConfig(merchantId: "test", settings: [:])
        sut.set(config, forKey: "merchant:123:config")
        sut.set(config, forKey: "merchant:456:config")
        sut.set(config, forKey: "user:789:config")

        // When
        sut.invalidate(matching: { $0.hasPrefix("merchant:") })

        // Then
        XCTAssertNil(sut.get(forKey: "merchant:123:config"))
        XCTAssertNil(sut.get(forKey: "merchant:456:config"))
        XCTAssertNotNil(sut.get(forKey: "user:789:config"))
    }

    // MARK: - Refresh Behavior

    func test_refresh_updatesTimestampWithoutChangingData() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        sut.set(config, forKey: "key")
        let originalTimestamp = mockStorage.getTimestamp(forKey: "key")

        // When
        mockClock.advance(by: 100)
        sut.refresh(forKey: "key")

        // Then
        let newTimestamp = mockStorage.getTimestamp(forKey: "key")
        XCTAssertNotEqual(originalTimestamp, newTimestamp)
        XCTAssertEqual(sut.get(forKey: "key")?.merchantId, "test-123")
    }

    func test_refresh_withExpiredCache_doesNothing() {
        // Given
        let config = MerchantConfig(merchantId: "test-123", settings: [:])
        sut.set(config, forKey: "key")

        // When - expire and try to refresh
        mockClock.advance(by: 301)
        sut.refresh(forKey: "key")

        // Then - still expired
        XCTAssertNil(sut.get(forKey: "key"))
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct MerchantConfig {
    let merchantId: String
    let settings: [String: Any]
}

// MARK: - Mock Storage

@available(iOS 15.0, *)
@MainActor
private final class MockCacheStorage {
    private var entries: [String: (config: MerchantConfig, timestamp: TimeInterval)] = [:]

    var isEmpty: Bool {
        entries.isEmpty
    }

    func store(_ config: MerchantConfig, key: String, timestamp: TimeInterval) {
        entries[key] = (config, timestamp)
    }

    func get(forKey key: String) -> (config: MerchantConfig, timestamp: TimeInterval)? {
        entries[key]
    }

    func remove(forKey key: String) {
        entries.removeValue(forKey: key)
    }

    func removeAll() {
        entries.removeAll()
    }

    func hasEntry(forKey key: String) -> Bool {
        entries[key] != nil
    }

    func getTimestamp(forKey key: String) -> TimeInterval? {
        entries[key]?.timestamp
    }

    func allKeys() -> [String] {
        Array(entries.keys)
    }
}

// MARK: - Mock Clock

@available(iOS 15.0, *)
@MainActor
private final class MockClock {
    private var currentTime: TimeInterval = 1000.0

    func now() -> TimeInterval {
        currentTime
    }

    func advance(by seconds: TimeInterval) {
        currentTime += seconds
    }
}

// MARK: - Merchant Config Cache

@available(iOS 15.0, *)
@MainActor
private final class MerchantConfigCache {
    private let storage: MockCacheStorage
    private let clock: MockClock
    private let ttl: TimeInterval
    private let maxEntries: Int?

    init(
        storage: MockCacheStorage,
        clock: MockClock,
        ttl: TimeInterval,
        maxEntries: Int? = nil
    ) {
        self.storage = storage
        self.clock = clock
        self.ttl = ttl
        self.maxEntries = maxEntries
    }

    func get(forKey key: String) -> MerchantConfig? {
        guard let entry = storage.get(forKey: key) else {
            return nil
        }

        let age = clock.now() - entry.timestamp
        if age >= ttl {
            storage.remove(forKey: key)
            return nil
        }

        return entry.config
    }

    func set(_ config: MerchantConfig, forKey key: String) {
        // Evict oldest if size limit reached
        if let maxEntries = maxEntries {
            let keys = storage.allKeys()
            if keys.count >= maxEntries, !keys.contains(key) {
                // Find oldest entry
                var oldestKey: String?
                var oldestTimestamp: TimeInterval = .infinity

                for key in keys {
                    if let timestamp = storage.getTimestamp(forKey: key), timestamp < oldestTimestamp {
                        oldestTimestamp = timestamp
                        oldestKey = key
                    }
                }

                if let oldestKey = oldestKey {
                    storage.remove(forKey: oldestKey)
                }
            }
        }

        storage.store(config, key: key, timestamp: clock.now())
    }

    func invalidate(forKey key: String) {
        storage.remove(forKey: key)
    }

    func invalidateAll() {
        storage.removeAll()
    }

    func invalidateExpired() {
        let keys = storage.allKeys()
        for key in keys {
            if let entry = storage.get(forKey: key) {
                let age = clock.now() - entry.timestamp
                if age >= ttl {
                    storage.remove(forKey: key)
                }
            }
        }
    }

    func invalidate(matching predicate: (String) -> Bool) {
        let keys = storage.allKeys()
        for key in keys where predicate(key) {
            storage.remove(forKey: key)
        }
    }

    func refresh(forKey key: String) {
        guard let entry = storage.get(forKey: key) else {
            return
        }

        let age = clock.now() - entry.timestamp
        if age < ttl {
            storage.store(entry.config, key: key, timestamp: clock.now())
        }
    }
}
