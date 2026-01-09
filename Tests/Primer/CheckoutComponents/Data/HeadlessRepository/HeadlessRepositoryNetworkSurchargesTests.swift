//
//  HeadlessRepositoryNetworkSurchargesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Extract Network Surcharges Edge Cases Tests

@available(iOS 15.0, *)
final class ExtractNetworkSurchargesEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - extractFromNetworksArray Tests

    func testExtractFromNetworksArray_WithMissingType_SkipsEntry() {
        // Given - Network entry without type
        let networksArray: [[String: Any]] = [
            ["surcharge": ["amount": TestData.Surcharges.amount100]],  // Missing type
            ["type": TestData.NetworkTypes.visa, "surcharge": ["amount": TestData.Surcharges.amount50]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?[TestData.NetworkTypes.visa], TestData.Surcharges.amount50)
    }

    func testExtractFromNetworksArray_WithMissingSurcharge_SkipsEntry() {
        // Given - Network entry without surcharge
        let networksArray: [[String: Any]] = [
            ["type": TestData.NetworkTypes.visa],  // Missing surcharge
            ["type": TestData.NetworkTypes.mastercard, "surcharge": ["amount": TestData.Surcharges.amount75]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?[TestData.NetworkTypes.mastercard], TestData.Surcharges.amount75)
    }

    func testExtractFromNetworksArray_WithNegativeSurcharge_ExcludesEntry() {
        // Given - Negative surcharge should be excluded (not > 0)
        let networksArray: [[String: Any]] = [
            ["type": TestData.NetworkTypes.visa, "surcharge": ["amount": -TestData.Surcharges.amount50]],
            ["type": TestData.NetworkTypes.mastercard, "surcharge": ["amount": TestData.Surcharges.amount100]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?[TestData.NetworkTypes.mastercard], TestData.Surcharges.amount100)
        XCTAssertNil(result?[TestData.NetworkTypes.visa])
    }

    func testExtractFromNetworksArray_WithEmptyArray_ReturnsNil() {
        // Given
        let networksArray: [[String: Any]] = []

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksArray_WithAllZeroSurcharges_ReturnsNil() {
        // Given - All zero surcharges should result in nil
        let networksArray: [[String: Any]] = [
            ["type": TestData.NetworkTypes.visa, "surcharge": ["amount": 0]],
            ["type": TestData.NetworkTypes.mastercard, "surcharge": ["amount": 0]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksArray_WithMixedFormats_HandlesBoth() {
        // Given - Mix of nested and direct surcharge formats
        let networksArray: [[String: Any]] = [
            ["type": TestData.NetworkTypes.visa, "surcharge": ["amount": TestData.Surcharges.amount100]],  // Nested format
            ["type": TestData.NetworkTypes.mastercard, "surcharge": TestData.Surcharges.amount75]  // Direct integer format
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[TestData.NetworkTypes.visa], TestData.Surcharges.amount100)
        XCTAssertEqual(result?[TestData.NetworkTypes.mastercard], TestData.Surcharges.amount75)
    }

    func testExtractFromNetworksArray_WithInvalidSurchargeType_SkipsEntry() {
        // Given - Surcharge is a string instead of int/dict
        let networksArray: [[String: Any]] = [
            ["type": TestData.NetworkTypes.visa, "surcharge": "invalid"],
            ["type": TestData.NetworkTypes.mastercard, "surcharge": ["amount": TestData.Surcharges.amount50]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?[TestData.NetworkTypes.mastercard], TestData.Surcharges.amount50)
    }

    // MARK: - extractFromNetworksDict Tests (Basic Happy Path Only)

    func testExtractFromNetworksDict_WithNestedSurcharge_ExtractsCorrectly() {
        // Given - Dictionary format with nested surcharge
        let networksDict: [String: [String: Any]] = [
            TestData.NetworkTypes.visa: ["surcharge": ["amount": TestData.Surcharges.amount150]],
            TestData.NetworkTypes.amex: ["surcharge": ["amount": TestData.Surcharges.amount200]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[TestData.NetworkTypes.visa], TestData.Surcharges.amount150)
        XCTAssertEqual(result?[TestData.NetworkTypes.amex], TestData.Surcharges.amount200)
    }

    func testExtractFromNetworksDict_WithDirectSurcharge_ExtractsCorrectly() {
        // Given - Dictionary format with direct integer surcharge
        let networksDict: [String: [String: Any]] = [
            TestData.NetworkTypes.visa: ["surcharge": TestData.Surcharges.amount100],
            TestData.NetworkTypes.mastercard: ["surcharge": TestData.Surcharges.amount75]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[TestData.NetworkTypes.visa], TestData.Surcharges.amount100)
        XCTAssertEqual(result?[TestData.NetworkTypes.mastercard], TestData.Surcharges.amount75)
    }
}

// MARK: - Extract Networks Array Additional Edge Cases

@available(iOS 15.0, *)
final class ExtractNetworksArrayAdditionalTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testExtractFromNetworksArray_WithFloatAmount_SkipsEntry() {
        // Given - Float amounts should be skipped (only Int is valid)
        let networksArray: [[String: Any]] = [
            ["type": TestData.NetworkTypes.visa, "surcharge": ["amount": 99.99]],  // Float
            ["type": TestData.NetworkTypes.mastercard, "surcharge": ["amount": TestData.Surcharges.amount100]]  // Int
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?[TestData.NetworkTypes.mastercard], TestData.Surcharges.amount100)
    }

    func testExtractFromNetworksArray_WithLargeAmount_IncludesEntry() {
        // Given - Large amounts should work
        let networksArray: [[String: Any]] = [
            ["type": TestData.NetworkTypes.visa, "surcharge": ["amount": TestData.Surcharges.amountLarge]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?[TestData.NetworkTypes.visa], TestData.Surcharges.amountLarge)
    }

    func testExtractFromNetworksArray_WithDuplicateNetworkTypes_KeepsLast() {
        // Given - Duplicate network types
        let networksArray: [[String: Any]] = [
            ["type": TestData.NetworkTypes.visa, "surcharge": ["amount": TestData.Surcharges.amount50]],
            ["type": TestData.NetworkTypes.visa, "surcharge": ["amount": TestData.Surcharges.amount100]]  // Duplicate
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then - Dictionary keeps last value for duplicate keys
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?[TestData.NetworkTypes.visa], TestData.Surcharges.amount100)
    }
}
