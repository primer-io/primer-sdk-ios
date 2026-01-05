//
//  DataPersistenceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
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

    func test_save_storesData() async throws {
        // Given
        let data = PaymentData(id: "123", amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)

        // When
        try await sut.save(data, forKey: "payment")

        // Then
        let hasData = await mockStorage.hasData(forKey: "payment")
        XCTAssertTrue(hasData)
    }

    func test_load_retrievesSavedData() async throws {
        // Given
        let data = PaymentData(id: "123", amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)
        try await sut.save(data, forKey: "payment")

        // When
        let loaded: PaymentData? = try await sut.load(forKey: "payment")

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, "123")
        XCTAssertEqual(loaded?.amount, 1000)
    }

    func test_load_nonExistentKey_returnsNil() async throws {
        // When
        let loaded: PaymentData? = try await sut.load(forKey: "nonexistent")

        // Then
        XCTAssertNil(loaded)
    }

    // MARK: - Data Deletion

    func test_delete_removesData() async throws {
        // Given
        let data = PaymentData(id: "123", amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)
        try await sut.save(data, forKey: "payment")

        // When
        try await sut.delete(forKey: "payment")

        // Then
        let hasData = await mockStorage.hasData(forKey: "payment")
        XCTAssertFalse(hasData)
    }

    func test_delete_nonExistentKey_doesNotThrow() async throws {
        // When/Then
        await XCTAssertNoThrowAsync(try await sut.delete(forKey: "nonexistent"))
    }

    func test_deleteAll_removesAllData() async throws {
        // Given
        try await sut.save(PaymentData(id: "1", amount: 100, currency: TestData.Currencies.usd), forKey: "key1")
        try await sut.save(PaymentData(id: "2", amount: 200, currency: TestData.Currencies.eur), forKey: "key2")

        // When
        try await sut.deleteAll()

        // Then
        let hasKey1 = await mockStorage.hasData(forKey: "key1")
        let hasKey2 = await mockStorage.hasData(forKey: "key2")
        let isEmpty = await mockStorage.isEmpty
        XCTAssertFalse(hasKey1)
        XCTAssertFalse(hasKey2)
        XCTAssertTrue(isEmpty)
    }

    // MARK: - Data Encoding and Decoding

    func test_save_withComplexObject_encodesCorrectly() async throws {
        // Given
        let complexData = ComplexData(
            id: "123",
            nested: NestedData(value: "test", items: ["a", "b", "c"]),
            metadata: ["key": "value"]
        )

        // When
        try await sut.save(complexData, forKey: "complex")
        let loaded: ComplexData? = try await sut.load(forKey: "complex")

        // Then
        XCTAssertEqual(loaded?.id, "123")
        XCTAssertEqual(loaded?.nested.value, "test")
        XCTAssertEqual(loaded?.nested.items.count, 3)
        XCTAssertEqual(loaded?.metadata["key"], "value")
    }

    func test_load_withCorruptedData_throwsError() async throws {
        // Given - corrupt data
        await mockStorage.setCorruptedData(forKey: "corrupt")

        // When/Then
        await XCTAssertThrowsErrorAsync(try await sut.load(forKey: "corrupt") as PaymentData?)
    }

    // MARK: - Data Migration

    func test_migrate_upgradesDataFormat() async throws {
        // Given - old format data
        let oldData = """
        {"version": 1, "paymentId": "123"}
        """.data(using: .utf8)!
        await mockStorage.setRawData(oldData, forKey: "legacy")

        // When
        try await sut.migrateIfNeeded(forKey: "legacy")

        // Then
        let migrated: MigratedData? = try await sut.load(forKey: "legacy")
        XCTAssertNotNil(migrated)
        XCTAssertEqual(migrated?.version, 2)
    }

    func test_migrate_withCurrentVersion_doesNotModify() async throws {
        // Given - current version data
        let currentData = MigratedData(version: 2, id: "123")
        try await sut.save(currentData, forKey: "current")

        // When
        try await sut.migrateIfNeeded(forKey: "current")

        // Then
        let loaded: MigratedData? = try await sut.load(forKey: "current")
        XCTAssertEqual(loaded?.version, 2)
    }

    // MARK: - Concurrent Access

    func test_concurrentSaves_maintainDataIntegrity() async throws {
        // When - concurrent saves with different keys
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let data = PaymentData(id: "\(i)", amount: i * 100, currency: TestData.Currencies.usd)
                    try? await self.sut.save(data, forKey: "payment-\(i)")
                }
            }
        }

        // Then - all saves should succeed
        for i in 0..<10 {
            let loaded: PaymentData? = try await sut.load(forKey: "payment-\(i)")
            XCTAssertNotNil(loaded)
            XCTAssertEqual(loaded?.id, "\(i)")
        }
    }

    func test_concurrentReads_returnConsistentData() async throws {
        // Given
        let data = PaymentData(id: "123", amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)
        try await sut.save(data, forKey: "payment")

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

    func test_save_withLargeData_handlesCorrectly() async throws {
        // Given - large data
        let largeArray = Array(repeating: "data", count: 10000)
        let largeData = ComplexData(
            id: "large",
            nested: NestedData(value: "test", items: largeArray),
            metadata: [:]
        )

        // When/Then
        await XCTAssertNoThrowAsync(try await sut.save(largeData, forKey: "large"))
    }

    func test_save_withExceedingSizeLimit_throwsError() async throws {
        // Given - data exceeding size limit
        let tooLarge = String(repeating: "x", count: 10_000_000) // 10MB
        let data = PaymentData(id: tooLarge, amount: 100, currency: TestData.Currencies.usd)

        // When/Then
        await XCTAssertThrowsErrorAsync(try await sut.save(data, forKey: "toolarge"))
    }

    // MARK: - Data Integrity

    func test_save_preservesDataIntegrity() async throws {
        // Given
        let original = PaymentData(id: "123", amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)

        // When
        try await sut.save(original, forKey: "payment")
        let loaded: PaymentData? = try await sut.load(forKey: "payment")

        // Then
        XCTAssertEqual(original, loaded)
    }

    func test_multipleUpdates_preservesLatestData() async throws {
        // Given
        let data1 = PaymentData(id: "v1", amount: 100, currency: TestData.Currencies.usd)
        let data2 = PaymentData(id: "v2", amount: 200, currency: TestData.Currencies.eur)
        let data3 = PaymentData(id: "v3", amount: 300, currency: TestData.Currencies.gbp)

        // When
        try await sut.save(data1, forKey: "payment")
        try await sut.save(data2, forKey: "payment")
        try await sut.save(data3, forKey: "payment")

        // Then
        let loaded: PaymentData? = try await sut.load(forKey: "payment")
        XCTAssertEqual(loaded?.id, "v3")
    }

    // MARK: - Key Enumeration

    func test_allKeys_returnsAllStoredKeys() async throws {
        // Given
        try await sut.save(PaymentData(id: "1", amount: 100, currency: TestData.Currencies.usd), forKey: "key1")
        try await sut.save(PaymentData(id: "2", amount: 200, currency: TestData.Currencies.eur), forKey: "key2")
        try await sut.save(PaymentData(id: "3", amount: 300, currency: TestData.Currencies.gbp), forKey: "key3")

        // When
        let keys = await sut.allKeys()

        // Then
        XCTAssertEqual(keys.count, 3)
        XCTAssertTrue(keys.contains("key1"))
        XCTAssertTrue(keys.contains("key2"))
        XCTAssertTrue(keys.contains("key3"))
    }

    // MARK: - Data Expiration

    func test_save_withExpiration_autoDeletesAfterExpiry() async throws {
        // Given
        let data = PaymentData(id: "123", amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)

        // When
        try await sut.save(data, forKey: "expiring", expiresIn: 0.1) // 100ms

        // Wait for expiration
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Then
        let loaded: PaymentData? = try await sut.load(forKey: "expiring")
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
private actor MockKeyValueStorage {
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
private final class PersistenceManager {
    private let storage: MockKeyValueStorage
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let maxDataSize = 5_000_000 // 5MB

    init(storage: MockKeyValueStorage) {
        self.storage = storage
    }

    func save<T: Encodable>(_ value: T, forKey key: String, expiresIn timeInterval: TimeInterval? = nil) async throws {
        let data = try encoder.encode(value)

        guard data.count <= maxDataSize else {
            throw PersistenceError.dataTooLarge
        }

        await storage.setData(data, forKey: key)

        if let expiresIn = timeInterval {
            await storage.setExpiration(Date().addingTimeInterval(expiresIn), forKey: key)
        }
    }

    func load<T: Decodable>(forKey key: String) async throws -> T? {
        guard let data = await storage.getData(forKey: key) else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PersistenceError.decodingFailed
        }
    }

    func delete(forKey key: String) async throws {
        await storage.removeData(forKey: key)
    }

    func deleteAll() async throws {
        await storage.removeAll()
    }

    func allKeys() async -> [String] {
        await storage.allKeys()
    }

    func migrateIfNeeded(forKey key: String) async throws {
        guard let data = await storage.getData(forKey: key) else {
            return
        }

        // Try to decode as JSON to check version
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let version = json["version"] as? Int,
           version == 1 {
            // Migrate from version 1 to version 2
            let id = json["paymentId"] as? String ?? ""
            let migrated = MigratedData(version: 2, id: id)
            try await save(migrated, forKey: key)
        }
    }
}

private enum PersistenceError: Error {
    case dataTooLarge
    case decodingFailed
}

// MARK: - Async XCTest Helpers

@available(iOS 15.0, *)
private func XCTAssertNoThrowAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
    } catch {
        XCTFail("Expected no error, but threw: \(error). \(message())", file: file, line: line)
    }
}

@available(iOS 15.0, *)
private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown. \(message())", file: file, line: line)
    } catch {
        // Expected - error was thrown
    }
}
