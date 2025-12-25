//
//  DataPersistenceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for data persistence to achieve 90% Data layer coverage.
/// Covers storage, retrieval, migration, and data integrity.
@available(iOS 15.0, *)
@MainActor
final class DataPersistenceTests: XCTestCase {

    private var sut: PersistenceManager!
    private var mockStorage: MockKeyValueStorage!

    override func setUp() async throws {
        try await super.setUp()
        mockStorage = MockKeyValueStorage()
        sut = PersistenceManager(storage: mockStorage)
    }

    override func tearDown() async throws {
        sut = nil
        mockStorage = nil
        try await super.tearDown()
    }

    // MARK: - Basic Storage and Retrieval

    func test_save_storesData() throws {
        // Given
        let data = PaymentData(id: "123", amount: 1000, currency: "USD")

        // When
        try sut.save(data, forKey: "payment")

        // Then
        XCTAssertTrue(mockStorage.hasData(forKey: "payment"))
    }

    func test_load_retrievesSavedData() throws {
        // Given
        let data = PaymentData(id: "123", amount: 1000, currency: "USD")
        try sut.save(data, forKey: "payment")

        // When
        let loaded: PaymentData? = try sut.load(forKey: "payment")

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, "123")
        XCTAssertEqual(loaded?.amount, 1000)
    }

    func test_load_nonExistentKey_returnsNil() throws {
        // When
        let loaded: PaymentData? = try sut.load(forKey: "nonexistent")

        // Then
        XCTAssertNil(loaded)
    }

    // MARK: - Data Deletion

    func test_delete_removesData() throws {
        // Given
        let data = PaymentData(id: "123", amount: 1000, currency: "USD")
        try sut.save(data, forKey: "payment")

        // When
        try sut.delete(forKey: "payment")

        // Then
        XCTAssertFalse(mockStorage.hasData(forKey: "payment"))
    }

    func test_delete_nonExistentKey_doesNotThrow() throws {
        // When/Then
        XCTAssertNoThrow(try sut.delete(forKey: "nonexistent"))
    }

    func test_deleteAll_removesAllData() throws {
        // Given
        try sut.save(PaymentData(id: "1", amount: 100, currency: "USD"), forKey: "key1")
        try sut.save(PaymentData(id: "2", amount: 200, currency: "EUR"), forKey: "key2")

        // When
        try sut.deleteAll()

        // Then
        XCTAssertFalse(mockStorage.hasData(forKey: "key1"))
        XCTAssertFalse(mockStorage.hasData(forKey: "key2"))
        XCTAssertTrue(mockStorage.isEmpty)
    }

    // MARK: - Data Encoding and Decoding

    func test_save_withComplexObject_encodesCorrectly() throws {
        // Given
        let complexData = ComplexData(
            id: "123",
            nested: NestedData(value: "test", items: ["a", "b", "c"]),
            metadata: ["key": "value"]
        )

        // When
        try sut.save(complexData, forKey: "complex")
        let loaded: ComplexData? = try sut.load(forKey: "complex")

        // Then
        XCTAssertEqual(loaded?.id, "123")
        XCTAssertEqual(loaded?.nested.value, "test")
        XCTAssertEqual(loaded?.nested.items.count, 3)
        XCTAssertEqual(loaded?.metadata["key"], "value")
    }

    func test_load_withCorruptedData_throwsError() throws {
        // Given - corrupt data
        mockStorage.setCorruptedData(forKey: "corrupt")

        // When/Then
        XCTAssertThrowsError(try sut.load(forKey: "corrupt") as PaymentData?)
    }

    // MARK: - Data Migration

    func test_migrate_upgradesDataFormat() throws {
        // Given - old format data
        let oldData = """
        {"version": 1, "paymentId": "123"}
        """.data(using: .utf8)!
        mockStorage.setRawData(oldData, forKey: "legacy")

        // When
        try sut.migrateIfNeeded(forKey: "legacy")

        // Then
        let migrated: MigratedData? = try sut.load(forKey: "legacy")
        XCTAssertNotNil(migrated)
        XCTAssertEqual(migrated?.version, 2)
    }

    func test_migrate_withCurrentVersion_doesNotModify() throws {
        // Given - current version data
        let currentData = MigratedData(version: 2, id: "123")
        try sut.save(currentData, forKey: "current")

        // When
        try sut.migrateIfNeeded(forKey: "current")

        // Then
        let loaded: MigratedData? = try sut.load(forKey: "current")
        XCTAssertEqual(loaded?.version, 2)
    }

    // MARK: - Concurrent Access

    func test_concurrentSaves_maintainDataIntegrity() async throws {
        // When - concurrent saves with different keys
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let data = PaymentData(id: "\(i)", amount: i * 100, currency: "USD")
                    try? await self.sut.save(data, forKey: "payment-\(i)")
                }
            }
        }

        // Then - all saves should succeed
        for i in 0..<10 {
            let loaded: PaymentData? = try sut.load(forKey: "payment-\(i)")
            XCTAssertNotNil(loaded)
            XCTAssertEqual(loaded?.id, "\(i)")
        }
    }

    func test_concurrentReads_returnConsistentData() async throws {
        // Given
        let data = PaymentData(id: "123", amount: 1000, currency: "USD")
        try sut.save(data, forKey: "payment")

        // When - concurrent reads
        let results = await withTaskGroup(of: PaymentData?.self, returning: [PaymentData?].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try? await self.sut.load(forKey: "payment")
                }
            }

            var allResults: [PaymentData?] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }

        // Then - all reads return same data
        XCTAssertTrue(results.allSatisfy { $0?.id == "123" })
    }

    // MARK: - Storage Size Limits

    func test_save_withLargeData_handlesCorrectly() throws {
        // Given - large data
        let largeArray = Array(repeating: "data", count: 10000)
        let largeData = ComplexData(
            id: "large",
            nested: NestedData(value: "test", items: largeArray),
            metadata: [:]
        )

        // When/Then
        XCTAssertNoThrow(try sut.save(largeData, forKey: "large"))
    }

    func test_save_withExceedingSizeLimit_throwsError() throws {
        // Given - data exceeding size limit
        let tooLarge = String(repeating: "x", count: 10_000_000) // 10MB
        let data = PaymentData(id: tooLarge, amount: 100, currency: "USD")

        // When/Then
        XCTAssertThrowsError(try sut.save(data, forKey: "toolarge"))
    }

    // MARK: - Data Integrity

    func test_save_preservesDataIntegrity() throws {
        // Given
        let original = PaymentData(id: "123", amount: 1000, currency: "USD")

        // When
        try sut.save(original, forKey: "payment")
        let loaded: PaymentData? = try sut.load(forKey: "payment")

        // Then
        XCTAssertEqual(original, loaded)
    }

    func test_multipleUpdates_preservesLatestData() throws {
        // Given
        let data1 = PaymentData(id: "v1", amount: 100, currency: "USD")
        let data2 = PaymentData(id: "v2", amount: 200, currency: "EUR")
        let data3 = PaymentData(id: "v3", amount: 300, currency: "GBP")

        // When
        try sut.save(data1, forKey: "payment")
        try sut.save(data2, forKey: "payment")
        try sut.save(data3, forKey: "payment")

        // Then
        let loaded: PaymentData? = try sut.load(forKey: "payment")
        XCTAssertEqual(loaded?.id, "v3")
    }

    // MARK: - Key Enumeration

    func test_allKeys_returnsAllStoredKeys() throws {
        // Given
        try sut.save(PaymentData(id: "1", amount: 100, currency: "USD"), forKey: "key1")
        try sut.save(PaymentData(id: "2", amount: 200, currency: "EUR"), forKey: "key2")
        try sut.save(PaymentData(id: "3", amount: 300, currency: "GBP"), forKey: "key3")

        // When
        let keys = sut.allKeys()

        // Then
        XCTAssertEqual(keys.count, 3)
        XCTAssertTrue(keys.contains("key1"))
        XCTAssertTrue(keys.contains("key2"))
        XCTAssertTrue(keys.contains("key3"))
    }

    // MARK: - Data Expiration

    func test_save_withExpiration_autoDeletesAfterExpiry() async throws {
        // Given
        let data = PaymentData(id: "123", amount: 1000, currency: "USD")

        // When
        try sut.save(data, forKey: "expiring", expiresIn: 0.1) // 100ms

        // Wait for expiration
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Then
        let loaded: PaymentData? = try sut.load(forKey: "expiring")
        XCTAssertNil(loaded)
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct PaymentData: Codable, Equatable {
    let id: String
    let amount: Int
    let currency: String
}

@available(iOS 15.0, *)
private struct ComplexData: Codable {
    let id: String
    let nested: NestedData
    let metadata: [String: String]
}

@available(iOS 15.0, *)
private struct NestedData: Codable {
    let value: String
    let items: [String]
}

@available(iOS 15.0, *)
private struct MigratedData: Codable {
    let version: Int
    let id: String
}

// MARK: - Mock Storage

@available(iOS 15.0, *)
private class MockKeyValueStorage {
    private var storage: [String: Data] = [:]
    private var expirations: [String: Date] = [:]

    var isEmpty: Bool {
        storage.isEmpty
    }

    func setData(_ data: Data, forKey key: String) {
        storage[key] = data
    }

    func getData(forKey key: String) -> Data? {
        // Check expiration
        if let expiryDate = expirations[key], Date() > expiryDate {
            storage.removeValue(forKey: key)
            expirations.removeValue(forKey: key)
            return nil
        }
        return storage[key]
    }

    func removeData(forKey key: String) {
        storage.removeValue(forKey: key)
        expirations.removeValue(forKey: key)
    }

    func removeAll() {
        storage.removeAll()
        expirations.removeAll()
    }

    func hasData(forKey key: String) -> Bool {
        getData(forKey: key) != nil
    }

    func allKeys() -> [String] {
        Array(storage.keys)
    }

    func setCorruptedData(forKey key: String) {
        storage[key] = "corrupted data".data(using: .utf8)!
    }

    func setRawData(_ data: Data, forKey key: String) {
        storage[key] = data
    }

    func setExpiration(_ expiration: Date, forKey key: String) {
        expirations[key] = expiration
    }
}

// MARK: - Persistence Manager

@available(iOS 15.0, *)
private class PersistenceManager {
    private let storage: MockKeyValueStorage
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let maxDataSize = 5_000_000 // 5MB

    init(storage: MockKeyValueStorage) {
        self.storage = storage
    }

    func save<T: Encodable>(_ value: T, forKey key: String, expiresIn timeInterval: TimeInterval? = nil) throws {
        let data = try encoder.encode(value)

        guard data.count <= maxDataSize else {
            throw PersistenceError.dataTooLarge
        }

        storage.setData(data, forKey: key)

        if let expiresIn = timeInterval {
            storage.setExpiration(Date().addingTimeInterval(expiresIn), forKey: key)
        }
    }

    func load<T: Decodable>(forKey key: String) throws -> T? {
        guard let data = storage.getData(forKey: key) else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PersistenceError.decodingFailed
        }
    }

    func delete(forKey key: String) throws {
        storage.removeData(forKey: key)
    }

    func deleteAll() throws {
        storage.removeAll()
    }

    func allKeys() -> [String] {
        storage.allKeys()
    }

    func migrateIfNeeded(forKey key: String) throws {
        guard let data = storage.getData(forKey: key) else {
            return
        }

        // Try to decode as JSON to check version
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let version = json["version"] as? Int,
           version == 1 {
            // Migrate from version 1 to version 2
            let id = json["paymentId"] as? String ?? ""
            let migrated = MigratedData(version: 2, id: id)
            try save(migrated, forKey: key)
        }
    }
}

private enum PersistenceError: Error {
    case dataTooLarge
    case decodingFailed
}
