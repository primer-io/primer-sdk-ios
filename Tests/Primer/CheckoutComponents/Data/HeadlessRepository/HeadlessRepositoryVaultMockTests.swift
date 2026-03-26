//
//  HeadlessRepositoryVaultMockTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - MockVaultManager

@available(iOS 15.0, *)
private final class MockVaultManager: VaultManagerProtocol {

    private(set) var configureCallCount = 0
    private(set) var fetchCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var startPaymentFlowCallCount = 0
    private(set) var lastDeletedId: String?

    var fetchResult: ([PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]?, Error?)
    var deleteError: Error?

    init(
        fetchResult: ([PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]?, Error?) = (nil, nil),
        deleteError: Error? = nil
    ) {
        self.fetchResult = fetchResult
        self.deleteError = deleteError
    }

    func configure() throws {
        configureCallCount += 1
    }

    func fetchVaultedPaymentMethods(
        completion: @escaping ([PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]?, Error?) -> Void
    ) {
        fetchCallCount += 1
        completion(fetchResult.0, fetchResult.1)
    }

    func startPaymentFlow(
        vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) {
        startPaymentFlowCallCount += 1
    }

    func deleteVaultedPaymentMethod(
        id: String,
        completion: @escaping (Error?) -> Void
    ) {
        deleteCallCount += 1
        lastDeletedId = id
        completion(deleteError)
    }
}

// MARK: - Tests

@available(iOS 15.0, *)
@MainActor
final class HeadlessRepositoryVaultMockTests: XCTestCase {

    private var mockVaultManager: MockVaultManager!
    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockVaultManager = MockVaultManager()
        sut = HeadlessRepositoryImpl(
            vaultManagerFactory: { [unowned self] in mockVaultManager }
        )
    }

    override func tearDown() {
        sut = nil
        mockVaultManager = nil
        super.tearDown()
    }

    // MARK: - fetchVaultedPaymentMethods — Returns Mock Data

    func test_fetchVaultedPaymentMethods_returnsMockData() async throws {
        // Given
        let expected = makeVaultedPaymentMethods(count: 2)
        mockVaultManager.fetchResult = (expected, nil)

        // When
        let result = try await sut.fetchVaultedPaymentMethods()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "vault_0")
        XCTAssertEqual(result[1].id, "vault_1")
        XCTAssertEqual(mockVaultManager.fetchCallCount, 1)
    }

    // MARK: - fetchVaultedPaymentMethods — Propagates Error

    func test_fetchVaultedPaymentMethods_error_propagates() async {
        // Given
        mockVaultManager.fetchResult = (nil, TestError.networkFailure)

        // When/Then
        do {
            _ = try await sut.fetchVaultedPaymentMethods()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
            XCTAssertEqual(mockVaultManager.fetchCallCount, 1)
        }
    }

    // MARK: - fetchVaultedPaymentMethods — Nil Returns Empty Array

    func test_fetchVaultedPaymentMethods_nilResult_returnsEmptyArray() async throws {
        // Given
        mockVaultManager.fetchResult = (nil, nil)

        // When
        let result = try await sut.fetchVaultedPaymentMethods()

        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(mockVaultManager.fetchCallCount, 1)
    }

    // MARK: - fetchVaultedPaymentMethods — Empty Array

    func test_fetchVaultedPaymentMethods_emptyArray_returnsEmptyArray() async throws {
        // Given
        mockVaultManager.fetchResult = ([], nil)

        // When
        let result = try await sut.fetchVaultedPaymentMethods()

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - deleteVaultedPaymentMethod — Success

    func test_deleteVaultedPaymentMethod_success_completesWithoutError() async throws {
        // Given
        mockVaultManager.fetchResult = (makeVaultedPaymentMethods(count: 1), nil)
        mockVaultManager.deleteError = nil

        // When/Then — should not throw
        try await sut.deleteVaultedPaymentMethod("vault_0")

        // Then
        XCTAssertEqual(mockVaultManager.deleteCallCount, 1)
        XCTAssertEqual(mockVaultManager.lastDeletedId, "vault_0")
    }

    // MARK: - deleteVaultedPaymentMethod — Failure

    func test_deleteVaultedPaymentMethod_failure_propagatesError() async {
        // Given
        mockVaultManager.fetchResult = (makeVaultedPaymentMethods(count: 1), nil)
        mockVaultManager.deleteError = TestError.networkFailure

        // When/Then
        do {
            try await sut.deleteVaultedPaymentMethod("vault_0")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
            XCTAssertEqual(mockVaultManager.deleteCallCount, 1)
        }
    }

    // MARK: - deleteVaultedPaymentMethod — Fetches Before Deleting

    func test_deleteVaultedPaymentMethod_fetchesBeforeDelete() async throws {
        // Given
        mockVaultManager.fetchResult = (makeVaultedPaymentMethods(count: 1), nil)
        mockVaultManager.deleteError = nil

        // When
        try await sut.deleteVaultedPaymentMethod("vault_0")

        // Then — fetch is called before delete (architecture requirement)
        XCTAssertEqual(mockVaultManager.fetchCallCount, 1)
        XCTAssertEqual(mockVaultManager.deleteCallCount, 1)
    }

    // MARK: - deleteVaultedPaymentMethod — Fetch Fails Before Delete

    func test_deleteVaultedPaymentMethod_fetchFails_propagatesFetchError() async {
        // Given
        mockVaultManager.fetchResult = (nil, TestError.networkFailure)

        // When/Then
        do {
            try await sut.deleteVaultedPaymentMethod("vault_0")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
            // Delete should not be called if fetch fails
            XCTAssertEqual(mockVaultManager.deleteCallCount, 0)
        }
    }

    // MARK: - Factory Injection

    func test_vaultManagerFactory_isUsed() async throws {
        // Given
        var factoryCalled = false
        let mockManager = MockVaultManager(fetchResult: ([], nil))
        sut = HeadlessRepositoryImpl(
            vaultManagerFactory: {
                factoryCalled = true
                return mockManager
            }
        )

        // When
        _ = try await sut.fetchVaultedPaymentMethods()

        // Then
        XCTAssertTrue(factoryCalled)
    }

    // MARK: - Helpers

    private static let emptyInstrumentData: Response.Body.Tokenization.PaymentInstrumentData = {
        let json = "{}".data(using: .utf8)!
        return try! JSONDecoder().decode(Response.Body.Tokenization.PaymentInstrumentData.self, from: json)
    }()

    private func makeVaultedPaymentMethods(
        count: Int
    ) -> [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
        (0 ..< count).map { index in
            PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
                id: "vault_\(index)",
                paymentMethodType: "PAYMENT_CARD",
                paymentInstrumentType: .paymentCard,
                paymentInstrumentData: Self.emptyInstrumentData,
                analyticsId: "analytics_\(index)"
            )
        }
    }
}
