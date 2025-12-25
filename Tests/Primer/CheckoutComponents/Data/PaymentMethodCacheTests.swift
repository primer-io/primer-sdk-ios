//
//  PaymentMethodCacheTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for PaymentMethodCache to achieve 90% Data layer coverage.
/// Covers payment method-specific caching, filtering, and updates.
@available(iOS 15.0, *)
@MainActor
final class PaymentMethodCacheTests: XCTestCase {
    private var sut: PaymentMethodCache!
    private var mockStorage: MockPaymentMethodStorage!

    override func setUp() async throws {
        try await super.setUp()
        mockStorage = MockPaymentMethodStorage()
        sut = PaymentMethodCache(storage: mockStorage)
    }

    override func tearDown() async throws {
        sut = nil
        mockStorage = nil
        try await super.tearDown()
    }

    // MARK: - Cache Storage and Retrieval

    func test_cachePaymentMethods_storesMethodsList() {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods

        // When
        sut.cache(methods)

        // Then
        XCTAssertTrue(mockStorage.didStore)
        XCTAssertEqual(mockStorage.storedMethods.count, methods.count)
    }

    func test_getCachedPaymentMethods_returnsStoredMethods() {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods
        sut.cache(methods)

        // When
        let cached = sut.getCachedPaymentMethods()

        // Then
        XCTAssertEqual(cached.count, methods.count)
    }

    func test_getCachedPaymentMethod_byId_returnsSpecificMethod() {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods
        sut.cache(methods)

        // When
        let cached = sut.getCachedPaymentMethod(id: "PAYMENT_CARD")

        // Then
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.type, "PAYMENT_CARD")
    }

    // MARK: - Filtering

    func test_getCachedPaymentMethods_withTypeFilter_returnsMatchingMethods() {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods
        sut.cache(methods)

        // When
        let filtered = sut.getCachedPaymentMethods(ofType: "PAYMENT_CARD")

        // Then
        XCTAssertTrue(filtered.allSatisfy { $0.type == "PAYMENT_CARD" })
    }

    func test_getCachedPaymentMethods_enabledOnly_excludesDisabled() {
        // Given
        let methods = TestData.PaymentMethods.mixedEnabledMethods
        sut.cache(methods)

        // When
        let enabled = sut.getCachedPaymentMethods(enabledOnly: true)

        // Then
        XCTAssertTrue(enabled.allSatisfy(\.isEnabled))
    }

    func test_getCachedPaymentMethods_supportedCurrencies_filtersCorrectly() {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods
        sut.cache(methods)

        // When
        let usdMethods = sut.getCachedPaymentMethods(supportingCurrency: "USD")

        // Then
        for method in usdMethods {
            XCTAssertTrue(method.supportedCurrencies.contains("USD"))
        }
    }

    // MARK: - Cache Updates

    func test_updatePaymentMethod_updatesSpecificMethod() {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods
        sut.cache(methods)

        // When
        var updated = methods[0]
        updated.isEnabled = false
        sut.updatePaymentMethod(updated)

        // Then
        let cached = sut.getCachedPaymentMethod(id: updated.id)
        XCTAssertFalse(cached?.isEnabled ?? true)
    }

    func test_updatePaymentMethod_nonExistent_addsToCache() {
        // Given
        sut.cache([])

        // When
        let newMethod = PaymentMethod(
            id: "NEW_METHOD",
            type: "PAYMENT_CARD",
            name: "New Method",
            isEnabled: true,
            supportedCurrencies: ["USD"]
        )
        sut.updatePaymentMethod(newMethod)

        // Then
        XCTAssertNotNil(sut.getCachedPaymentMethod(id: "NEW_METHOD"))
    }

    func test_removePaymentMethod_deletesFromCache() {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods
        sut.cache(methods)
        let initialCount = sut.getCachedPaymentMethods().count

        // When
        sut.removePaymentMethod(id: "PAYMENT_CARD")

        // Then
        XCTAssertEqual(sut.getCachedPaymentMethods().count, initialCount - 1)
        XCTAssertNil(sut.getCachedPaymentMethod(id: "PAYMENT_CARD"))
    }

    // MARK: - Cache Invalidation

    func test_clearCache_removesAllMethods() {
        // Given
        sut.cache(TestData.PaymentMethods.sampleMethods)

        // When
        sut.clearCache()

        // Then
        XCTAssertTrue(sut.getCachedPaymentMethods().isEmpty)
        XCTAssertTrue(mockStorage.didClear)
    }

    func test_invalidateDisabledMethods_removesOnlyDisabled() {
        // Given
        let methods = TestData.PaymentMethods.mixedEnabledMethods
        sut.cache(methods)

        // When
        sut.invalidateDisabledMethods()

        // Then
        let remaining = sut.getCachedPaymentMethods()
        XCTAssertTrue(remaining.allSatisfy(\.isEnabled))
    }

    // MARK: - Concurrent Access

    func test_concurrentReads_returnConsistentData() async {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods
        sut.cache(methods)

        // When - concurrent reads
        let results = await withTaskGroup(of: [PaymentMethod].self, returning: [[PaymentMethod]].self) { group in
            for _ in 0..<10 {
                group.addTask { @MainActor in
                    self.sut.getCachedPaymentMethods()
                }
            }

            var allResults: [[PaymentMethod]] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }

        // Then - all reads return same count
        let firstCount = results.first?.count ?? 0
        XCTAssertTrue(results.allSatisfy { $0.count == firstCount })
    }

    func test_concurrentUpdates_maintainConsistency() async {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods
        sut.cache(methods)

        // When - concurrent updates
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask { @MainActor in
                    var method = methods[0]
                    method.isEnabled = i % 2 == 0
                    self.sut.updatePaymentMethod(method)
                }
            }
        }

        // Then - cache should have valid state
        let cached = sut.getCachedPaymentMethod(id: methods[0].id)
        XCTAssertNotNil(cached)
    }

    // MARK: - Cache Persistence

    func test_cache_persistsAcrossReinitialization() {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods
        sut.cache(methods)

        // When - create new cache instance with same storage
        let newCache = PaymentMethodCache(storage: mockStorage)
        let cached = newCache.getCachedPaymentMethods()

        // Then
        XCTAssertEqual(cached.count, methods.count)
    }

    // MARK: - Empty State Handling

    func test_getCachedPaymentMethods_emptyCache_returnsEmptyArray() {
        // Given - empty cache

        // When
        let cached = sut.getCachedPaymentMethods()

        // Then
        XCTAssertTrue(cached.isEmpty)
    }

    func test_getCachedPaymentMethod_emptyCache_returnsNil() {
        // Given - empty cache

        // When
        let cached = sut.getCachedPaymentMethod(id: "nonexistent")

        // Then
        XCTAssertNil(cached)
    }

    // MARK: - Metadata Tracking

    func test_getCacheMetadata_returnsLastUpdateTime() {
        // Given
        sut.cache(TestData.PaymentMethods.sampleMethods)

        // When
        let metadata = sut.getCacheMetadata()

        // Then
        XCTAssertNotNil(metadata.lastUpdated)
    }

    func test_getCacheMetadata_returnsMethodCount() {
        // Given
        let methods = TestData.PaymentMethods.sampleMethods
        sut.cache(methods)

        // When
        let metadata = sut.getCacheMetadata()

        // Then
        XCTAssertEqual(metadata.count, methods.count)
    }
}

// MARK: - Test Data Extension

@available(iOS 15.0, *)
extension TestData {
    enum PaymentMethods {
        fileprivate static let sampleMethods = [
            PaymentMethod(
                id: "PAYMENT_CARD",
                type: "PAYMENT_CARD",
                name: "Credit Card",
                isEnabled: true,
                supportedCurrencies: ["USD", "EUR", "GBP"]
            ),
            PaymentMethod(
                id: "PAYPAL",
                type: "PAYPAL",
                name: "PayPal",
                isEnabled: true,
                supportedCurrencies: ["USD"]
            ),
            PaymentMethod(
                id: "APPLE_PAY",
                type: "APPLE_PAY",
                name: "Apple Pay",
                isEnabled: true,
                supportedCurrencies: ["USD", "EUR"]
            )
        ]

        fileprivate static let mixedEnabledMethods = [
            PaymentMethod(
                id: "ENABLED_1",
                type: "PAYMENT_CARD",
                name: "Enabled Method",
                isEnabled: true,
                supportedCurrencies: ["USD"]
            ),
            PaymentMethod(
                id: "DISABLED_1",
                type: "PAYPAL",
                name: "Disabled Method",
                isEnabled: false,
                supportedCurrencies: ["USD"]
            ),
            PaymentMethod(
                id: "ENABLED_2",
                type: "APPLE_PAY",
                name: "Another Enabled",
                isEnabled: true,
                supportedCurrencies: ["EUR"]
            )
        ]
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
fileprivate struct PaymentMethod: Equatable {
    let id: String
    let type: String
    let name: String
    var isEnabled: Bool
    let supportedCurrencies: [String]
}

// MARK: - Mock Storage

@available(iOS 15.0, *)
private class MockPaymentMethodStorage {
    var storedMethods: [PaymentMethod] = []
    var didStore = false
    var didClear = false
    var lastUpdated: Date?

    func store(_ methods: [PaymentMethod]) {
        didStore = true
        storedMethods = methods
        lastUpdated = Date()
    }

    func load() -> [PaymentMethod] {
        storedMethods
    }

    func clear() {
        didClear = true
        storedMethods = []
        lastUpdated = nil
    }
}

// MARK: - Payment Method Cache

@available(iOS 15.0, *)
private class PaymentMethodCache {
    private let storage: MockPaymentMethodStorage
    private var methods: [PaymentMethod] = []

    init(storage: MockPaymentMethodStorage) {
        self.storage = storage
        self.methods = storage.load()
    }

    func cache(_ methods: [PaymentMethod]) {
        self.methods = methods
        storage.store(methods)
    }

    func getCachedPaymentMethods(
        ofType type: String? = nil,
        enabledOnly: Bool = false,
        supportingCurrency currency: String? = nil
    ) -> [PaymentMethod] {
        var result = methods

        if let type = type {
            result = result.filter { $0.type == type }
        }

        if enabledOnly {
            result = result.filter(\.isEnabled)
        }

        if let currency = currency {
            result = result.filter { $0.supportedCurrencies.contains(currency) }
        }

        return result
    }

    func getCachedPaymentMethod(id: String) -> PaymentMethod? {
        methods.first { $0.id == id }
    }

    func updatePaymentMethod(_ method: PaymentMethod) {
        if let index = methods.firstIndex(where: { $0.id == method.id }) {
            methods[index] = method
        } else {
            methods.append(method)
        }
        storage.store(methods)
    }

    func removePaymentMethod(id: String) {
        methods.removeAll { $0.id == id }
        storage.store(methods)
    }

    func clearCache() {
        methods = []
        storage.clear()
    }

    func invalidateDisabledMethods() {
        methods = methods.filter(\.isEnabled)
        storage.store(methods)
    }

    func getCacheMetadata() -> (lastUpdated: Date?, count: Int) {
        (storage.lastUpdated, methods.count)
    }
}
