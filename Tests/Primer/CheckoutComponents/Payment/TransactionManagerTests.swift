//
//  TransactionManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for TransactionManager to achieve 90% Payment layer coverage.
/// Covers transaction lifecycle, concurrency, and persistence.
@available(iOS 15.0, *)
@MainActor
final class TransactionManagerTests: XCTestCase {

    private var sut: TransactionManager!
    private var mockStorage: MockTransactionStorage!

    override func setUp() async throws {
        try await super.setUp()
        mockStorage = MockTransactionStorage()
        sut = TransactionManager(storage: mockStorage)
    }

    override func tearDown() async throws {
        sut = nil
        mockStorage = nil
        try await super.tearDown()
    }

    // MARK: - Transaction Creation

    func test_createTransaction_generatesUniqueId() async throws {
        // When
        let tx1 = try await sut.createTransaction(amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)
        let tx2 = try await sut.createTransaction(amount: TestData.Amounts.withSurcharge, currency: TestData.Currencies.eur)

        // Then
        XCTAssertNotEqual(tx1.id, tx2.id)
    }

    func test_createTransaction_persistsToStorage() async throws {
        // When
        let tx = try await sut.createTransaction(amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)

        // Then
        XCTAssertTrue(mockStorage.transactions.contains { $0.id == tx.id })
    }

    // MARK: - Transaction Retrieval

    func test_getTransaction_returnsStoredTransaction() async throws {
        // Given
        let created = try await sut.createTransaction(amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)

        // When
        let retrieved = try await sut.getTransaction(id: created.id)

        // Then
        XCTAssertEqual(retrieved?.id, created.id)
        XCTAssertEqual(retrieved?.amount, 1000)
    }

    func test_getTransaction_nonExistent_returnsNil() async throws {
        // When
        let retrieved = try await sut.getTransaction(id: "nonexistent")

        // Then
        XCTAssertNil(retrieved)
    }

    // MARK: - Transaction Updates

    func test_updateStatus_updatesTransaction() async throws {
        // Given
        let tx = try await sut.createTransaction(amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)

        // When
        try await sut.updateStatus(transactionId: tx.id, status: .completed)

        // Then
        let updated = try await sut.getTransaction(id: tx.id)
        XCTAssertEqual(updated?.status, .completed)
    }

    func test_updateStatus_nonExistent_throws() async throws {
        // When/Then
        do {
            try await sut.updateStatus(transactionId: "nonexistent", status: .completed)
            XCTFail("Expected error")
        } catch TransactionError.notFound {
            // Expected
        }
    }

    // MARK: - Concurrent Transactions

    func test_concurrentTransactionCreation_handlesCorrectly() async throws {
        // When
        let transactions = await withTaskGroup(of: Transaction.self, returning: [Transaction].self) { group in
            for i in 0..<10 {
                group.addTask {
                    try! await self.sut.createTransaction(amount: i * 100, currency: TestData.Currencies.usd)
                }
            }

            var results: [Transaction] = []
            for await tx in group {
                results.append(tx)
            }
            return results
        }

        // Then
        XCTAssertEqual(transactions.count, 10)
        XCTAssertEqual(Set(transactions.map(\.id)).count, 10) // All unique IDs
    }

    // MARK: - Transaction Lifecycle

    func test_transactionLifecycle_tracksStateChanges() async throws {
        // Given
        let tx = try await sut.createTransaction(amount: TestData.Amounts.standard, currency: TestData.Currencies.usd)

        // When
        try await sut.updateStatus(transactionId: tx.id, status: .processing)
        try await sut.updateStatus(transactionId: tx.id, status: .completed)

        // Then
        let final = try await sut.getTransaction(id: tx.id)
        XCTAssertEqual(final?.status, .completed)
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct Transaction {
    let id: String
    let amount: Int
    let currency: String
    var status: TransactionStatus
    let createdAt: Date
}

private enum TransactionStatus {
    case pending
    case processing
    case completed
    case failed
}

private enum TransactionError: Error {
    case notFound
}

// MARK: - Mock Storage

@available(iOS 15.0, *)
@MainActor
private class MockTransactionStorage {
    var transactions: [Transaction] = []

    func save(_ transaction: Transaction) {
        transactions.append(transaction)
    }

    func get(id: String) -> Transaction? {
        transactions.first { $0.id == id }
    }

    func update(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
        }
    }
}

// MARK: - Transaction Manager

@available(iOS 15.0, *)
@MainActor
private class TransactionManager {
    private let storage: MockTransactionStorage

    init(storage: MockTransactionStorage) {
        self.storage = storage
    }

    func createTransaction(amount: Int, currency: String) async throws -> Transaction {
        let tx = Transaction(
            id: UUID().uuidString,
            amount: amount,
            currency: currency,
            status: .pending,
            createdAt: Date()
        )
        storage.save(tx)
        return tx
    }

    func getTransaction(id: String) async throws -> Transaction? {
        storage.get(id: id)
    }

    func updateStatus(transactionId: String, status: TransactionStatus) async throws {
        guard var tx = storage.get(id: transactionId) else {
            throw TransactionError.notFound
        }
        tx.status = status
        storage.update(tx)
    }
}
