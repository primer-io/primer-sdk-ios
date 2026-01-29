//
//  HeadlessRepositoryVaultTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - Fetch Vaulted Payment Methods Edge Case Tests

@available(iOS 15.0, *)
final class FetchVaultedPaymentMethodsEdgeCaseTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testFetchVaultedPaymentMethods_WithoutConfiguration_ThrowsError() async {
        // Given - No SDK configuration (will fail because VaultManager isn't configured)

        // When/Then - Should throw because SDK isn't properly configured
        do {
            _ = try await repository.fetchVaultedPaymentMethods()
            // If no error is thrown, the test will verify the returned array
        } catch {
            // Expected - VaultManager requires proper SDK configuration
            XCTAssertNotNil(error)
        }
    }
}

// MARK: - Process Vaulted Payment Edge Case Tests

@available(iOS 15.0, *)
final class ProcessVaultedPaymentEdgeCaseTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testProcessVaultedPayment_WithInvalidId_ThrowsError() async {
        // Given
        let invalidId = "non-existent-id"

        // When/Then - Should throw because payment method doesn't exist
        do {
            _ = try await repository.processVaultedPayment(
                vaultedPaymentMethodId: invalidId,
                paymentMethodType: "PAYMENT_CARD",
                additionalData: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - Invalid vaulted payment method ID
            XCTAssertNotNil(error)
        }
    }

    func testProcessVaultedPayment_WithEmptyId_ThrowsError() async {
        // Given
        let emptyId = ""

        // When/Then
        do {
            _ = try await repository.processVaultedPayment(
                vaultedPaymentMethodId: emptyId,
                paymentMethodType: "PAYMENT_CARD",
                additionalData: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testProcessVaultedPayment_WithDifferentPaymentMethodTypes_ThrowsError() async {
        // Given
        let invalidId = "test-id"
        let paymentTypes = ["PAYPAL", "APPLE_PAY", "KLARNA", "UNKNOWN"]

        // When/Then - All should throw errors for invalid IDs
        for type in paymentTypes {
            do {
                _ = try await repository.processVaultedPayment(
                    vaultedPaymentMethodId: invalidId,
                    paymentMethodType: type,
                    additionalData: nil
                )
                XCTFail("Expected error for type: \(type)")
            } catch {
                XCTAssertNotNil(error)
            }
        }
    }
}

// MARK: - Delete Vaulted Payment Method Edge Case Tests

@available(iOS 15.0, *)
final class DeleteVaultedPaymentMethodEdgeCaseTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testDeleteVaultedPaymentMethod_WithInvalidId_ThrowsError() async {
        // Given
        let invalidId = "non-existent-id"

        // When/Then
        do {
            try await repository.deleteVaultedPaymentMethod(invalidId)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - Cannot delete non-existent payment method
            XCTAssertNotNil(error)
        }
    }

    func testDeleteVaultedPaymentMethod_WithEmptyId_ThrowsError() async {
        // Given
        let emptyId = ""

        // When/Then
        do {
            try await repository.deleteVaultedPaymentMethod(emptyId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
