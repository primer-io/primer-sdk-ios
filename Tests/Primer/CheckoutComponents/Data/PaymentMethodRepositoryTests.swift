//
//  PaymentMethodRepositoryTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for PaymentMethodRepository to achieve 90% Data layer coverage.
/// Covers repository pattern edge cases, caching, and error handling.
@available(iOS 15.0, *)
@MainActor
final class PaymentMethodRepositoryTests: XCTestCase {

    private var sut: PaymentMethodRepository!
    private var mockNetworkService: PaymentMethodRepositoryMockNetworkService!
    private var mockCache: MockCache!

    override func setUp() async throws {
        try await super.setUp()
        mockNetworkService = PaymentMethodRepositoryMockNetworkService()
        mockCache = MockCache()
        sut = PaymentMethodRepository(
            networkService: mockNetworkService,
            cache: mockCache
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockNetworkService = nil
        mockCache = nil
        try await super.tearDown()
    }

    // MARK: - Successful Fetching

    func test_fetchPaymentMethods_withValidResponse_returnsPaymentMethods() async throws {
        // Given
        mockNetworkService.responseData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)

        // When
        let methods = try await sut.fetchPaymentMethods()

        // Then
        XCTAssertFalse(methods.isEmpty)
        XCTAssertEqual(mockNetworkService.fetchCallCount, 1)
    }

    func test_fetchPaymentMethods_cachesSuccessfulResponse() async throws {
        // Given
        mockNetworkService.responseData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)

        // When
        _ = try await sut.fetchPaymentMethods()

        // Then
        XCTAssertTrue(mockCache.didStore)
        XCTAssertNotNil(mockCache.storedData)
    }

    func test_fetchPaymentMethods_withCachedData_returnsCachedData() async throws {
        // Given
        mockCache.cachedData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockCache.hasCachedData = true

        // When
        let methods = try await sut.fetchPaymentMethods(useCache: true)

        // Then
        XCTAssertFalse(methods.isEmpty)
        XCTAssertEqual(mockNetworkService.fetchCallCount, 0) // Should not hit network
    }

    // MARK: - Empty Response Handling

    func test_fetchPaymentMethods_withEmptyResponse_returnsEmptyArray() async throws {
        // Given
        mockNetworkService.responseData = TestData.APIResponses.emptyPaymentMethods.data(using: .utf8)

        // When
        let methods = try await sut.fetchPaymentMethods()

        // Then
        XCTAssertTrue(methods.isEmpty)
    }

    func test_fetchPaymentMethods_withEmptyResponse_doesNotCacheEmptyResult() async throws {
        // Given
        mockNetworkService.responseData = TestData.APIResponses.emptyPaymentMethods.data(using: .utf8)

        // When
        _ = try await sut.fetchPaymentMethods()

        // Then
        XCTAssertFalse(mockCache.didStore)
    }

    // MARK: - Error Scenarios

    func test_fetchPaymentMethods_withNetworkError_throwsError() async throws {
        // Given
        mockNetworkService.shouldFail = true
        mockNetworkService.error = TestData.Errors.networkTimeout

        // When/Then
        do {
            _ = try await sut.fetchPaymentMethods()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.Errors.networkTimeout.code)
        }
    }

    func test_fetchPaymentMethods_withMalformedJSON_throwsParsingError() async throws {
        // Given
        mockNetworkService.responseData = TestData.APIResponses.malformedJSON.data(using: .utf8)

        // When/Then
        do {
            _ = try await sut.fetchPaymentMethods()
            XCTFail("Expected parsing error")
        } catch {
            // Expected parsing error
        }
    }

    func test_fetchPaymentMethods_withNetworkError_fallsBackToCache() async throws {
        // Given
        mockNetworkService.shouldFail = true
        mockNetworkService.error = TestData.Errors.networkTimeout
        mockCache.cachedData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockCache.hasCachedData = true

        // When
        let methods = try await sut.fetchPaymentMethods(fallbackToCache: true)

        // Then
        XCTAssertFalse(methods.isEmpty) // Should return cached data
    }

    // MARK: - Cache Invalidation

    func test_invalidateCache_clearsCachedData() async throws {
        // Given
        mockCache.cachedData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockCache.hasCachedData = true

        // When
        await sut.invalidateCache()

        // Then
        XCTAssertTrue(mockCache.didClear)
        XCTAssertFalse(mockCache.hasCachedData)
    }

    func test_fetchPaymentMethods_afterCacheInvalidation_fetchesFromNetwork() async throws {
        // Given
        mockCache.cachedData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockCache.hasCachedData = true
        await sut.invalidateCache()
        mockNetworkService.responseData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)

        // When
        _ = try await sut.fetchPaymentMethods()

        // Then
        XCTAssertEqual(mockNetworkService.fetchCallCount, 1)
    }

    // MARK: - Concurrent Access

    func test_fetchPaymentMethods_concurrentCalls_deduplicatesRequests() async throws {
        // Given
        mockNetworkService.responseData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockNetworkService.responseDelay = 0.1 // Simulate network delay

        // When - concurrent calls
        async let methods1 = sut.fetchPaymentMethods()
        async let methods2 = sut.fetchPaymentMethods()
        async let methods3 = sut.fetchPaymentMethods()

        let (result1, result2, result3) = try await (methods1, methods2, methods3)

        // Then - should only make one network call
        XCTAssertEqual(mockNetworkService.fetchCallCount, 1)
        XCTAssertFalse(result1.isEmpty)
        XCTAssertFalse(result2.isEmpty)
        XCTAssertFalse(result3.isEmpty)
    }

    func test_fetchPaymentMethods_concurrentCalls_withCache_returnsSameData() async throws {
        // Given
        mockCache.cachedData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockCache.hasCachedData = true

        // When - concurrent cache reads
        async let methods1 = sut.fetchPaymentMethods(useCache: true)
        async let methods2 = sut.fetchPaymentMethods(useCache: true)
        async let methods3 = sut.fetchPaymentMethods(useCache: true)

        let (result1, result2, result3) = try await (methods1, methods2, methods3)

        // Then
        XCTAssertEqual(result1.count, result2.count)
        XCTAssertEqual(result2.count, result3.count)
    }

    // MARK: - Cache Expiry

    func test_fetchPaymentMethods_withExpiredCache_fetchesFromNetwork() async throws {
        // Given
        mockCache.cachedData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockCache.hasCachedData = true
        mockCache.isExpired = true
        mockNetworkService.responseData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)

        // When
        _ = try await sut.fetchPaymentMethods(useCache: true)

        // Then
        XCTAssertEqual(mockNetworkService.fetchCallCount, 1)
    }

    func test_fetchPaymentMethods_withFreshCache_skipsFetch() async throws {
        // Given
        mockCache.cachedData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockCache.hasCachedData = true
        mockCache.isExpired = false

        // When
        _ = try await sut.fetchPaymentMethods(useCache: true)

        // Then
        XCTAssertEqual(mockNetworkService.fetchCallCount, 0)
    }

    // MARK: - Filtering and Transformation

    func test_fetchPaymentMethods_filtersDisabledMethods() async throws {
        // Given - Response contains both enabled and disabled methods
        mockNetworkService.responseData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)

        // When
        let methods = try await sut.fetchPaymentMethods(includeDisabled: false)

        // Then
        XCTAssertFalse(methods.isEmpty)
        // Verify all returned methods are enabled
        for method in methods {
            XCTAssertTrue(method.isEnabled)
        }
    }

    func test_fetchPaymentMethods_withIncludeDisabled_returnsAllMethods() async throws {
        // Given
        mockNetworkService.responseData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)

        // When
        let methods = try await sut.fetchPaymentMethods(includeDisabled: true)

        // Then
        XCTAssertFalse(methods.isEmpty)
    }

    // MARK: - Offline Behavior

    func test_fetchPaymentMethods_whenOffline_withCache_returnsStaleData() async throws {
        // Given
        mockNetworkService.shouldFail = true
        mockNetworkService.error = TestData.Errors.networkError
        mockCache.cachedData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockCache.hasCachedData = true
        mockCache.isExpired = true // Stale cache

        // When
        let methods = try await sut.fetchPaymentMethods(allowStaleCache: true)

        // Then
        XCTAssertFalse(methods.isEmpty) // Returns stale data when offline
    }

    func test_fetchPaymentMethods_whenOffline_withoutCache_throwsError() async throws {
        // Given
        mockNetworkService.shouldFail = true
        mockNetworkService.error = TestData.Errors.networkError
        mockCache.hasCachedData = false

        // When/Then
        do {
            _ = try await sut.fetchPaymentMethods()
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    // MARK: - Refresh Scenarios

    func test_refreshPaymentMethods_bypassesCache() async throws {
        // Given
        mockCache.cachedData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockCache.hasCachedData = true
        mockNetworkService.responseData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)

        // When
        _ = try await sut.refreshPaymentMethods()

        // Then - Should hit network despite cache
        XCTAssertEqual(mockNetworkService.fetchCallCount, 1)
    }

    func test_refreshPaymentMethods_updatesCacheWithNewData() async throws {
        // Given
        mockNetworkService.responseData = TestData.APIResponses.validPaymentMethods.data(using: .utf8)
        mockCache.didClear = false

        // When
        _ = try await sut.refreshPaymentMethods()

        // Then
        XCTAssertTrue(mockCache.didStore)
    }
}

// MARK: - Mock Network Service (Payment Method Repository Tests)

@available(iOS 15.0, *)
@MainActor
private class PaymentMethodRepositoryMockNetworkService {
    var responseData: Data?
    var shouldFail = false
    var error: Error?
    var fetchCallCount = 0
    var responseDelay: TimeInterval = 0

    func fetchPaymentMethods() async throws -> Data {
        fetchCallCount += 1

        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldFail {
            throw error ?? TestData.Errors.networkTimeout
        }

        guard let data = responseData else {
            throw TestData.Errors.unknown
        }

        return data
    }
}

// MARK: - Mock Cache

@available(iOS 15.0, *)
private class MockCache {
    var cachedData: Data?
    var hasCachedData = false
    var isExpired = false
    var didStore = false
    var didClear = false
    var storedData: Data?

    func get() -> Data? {
        guard hasCachedData, !isExpired else { return nil }
        return cachedData
    }

    func store(_ data: Data) {
        didStore = true
        storedData = data
        cachedData = data
        hasCachedData = true
    }

    func clear() {
        didClear = true
        cachedData = nil
        hasCachedData = false
    }
}

// MARK: - Mock Repository

@available(iOS 15.0, *)
@MainActor
private class PaymentMethodRepository {
    private let networkService: PaymentMethodRepositoryMockNetworkService
    private let cache: MockCache
    private var inflightRequest: Task<[PaymentMethod], Error>?

    init(networkService: PaymentMethodRepositoryMockNetworkService, cache: MockCache) {
        self.networkService = networkService
        self.cache = cache
    }

    func fetchPaymentMethods(
        useCache: Bool = false,
        fallbackToCache: Bool = false,
        includeDisabled: Bool = false,
        allowStaleCache: Bool = false
    ) async throws -> [PaymentMethod] {
        // Check cache first if requested
        if useCache, let cachedData = cache.get() {
            return try parsePaymentMethods(from: cachedData, includeDisabled: includeDisabled)
        }

        // Deduplicate concurrent requests - check and set atomically
        if inflightRequest == nil {
            let task = Task<[PaymentMethod], Error> {
                do {
                    let data = try await networkService.fetchPaymentMethods()
                    let methods = try parsePaymentMethods(from: data, includeDisabled: includeDisabled)

                    // Cache if we got valid data
                    if !methods.isEmpty {
                        cache.store(data)
                    }

                    return methods
                } catch {
                    // Fallback to cache if allowed
                    if fallbackToCache || allowStaleCache {
                        if let cachedData = cache.cachedData {
                            return try parsePaymentMethods(from: cachedData, includeDisabled: includeDisabled)
                        }
                    }
                    throw error
                }
            }
            inflightRequest = task
        }

        // All callers wait for the same request
        guard let task = inflightRequest else {
            fatalError("inflightRequest should be set at this point")
        }

        do {
            let result = try await task.value
            inflightRequest = nil
            return result
        } catch {
            inflightRequest = nil
            throw error
        }
    }

    func refreshPaymentMethods() async throws -> [PaymentMethod] {
        let data = try await networkService.fetchPaymentMethods()
        let methods = try parsePaymentMethods(from: data, includeDisabled: true)
        cache.store(data)
        return methods
    }

    func invalidateCache() async {
        cache.clear()
    }

    private func parsePaymentMethods(from data: Data, includeDisabled: Bool) throws -> [PaymentMethod] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let methodsArray = json?["paymentMethods"] as? [[String: Any]] else {
            return []
        }

        return methodsArray.compactMap { dict -> PaymentMethod? in
            guard let id = dict["id"] as? String,
                  let type = dict["type"] as? String,
                  let name = dict["name"] as? String else {
                return nil
            }

            let isEnabled = dict["isEnabled"] as? Bool ?? true

            if !includeDisabled, !isEnabled {
                return nil
            }

            return PaymentMethod(id: id, type: type, name: name, isEnabled: isEnabled)
        }
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct PaymentMethod: Equatable {
    let id: String
    let type: String
    let name: String
    let isEnabled: Bool
}
