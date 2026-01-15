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
            ["surcharge": ["amount": 100]],  // Missing type
            ["type": "VISA", "surcharge": ["amount": 50]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["VISA"], 50)
    }

    func testExtractFromNetworksArray_WithMissingSurcharge_SkipsEntry() {
        // Given - Network entry without surcharge
        let networksArray: [[String: Any]] = [
            ["type": "VISA"],  // Missing surcharge
            ["type": "MASTERCARD", "surcharge": ["amount": 75]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksArray_WithNegativeSurcharge_ExcludesEntry() {
        // Given - Negative surcharge should be excluded (not > 0)
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": -50]],
            ["type": "MASTERCARD", "surcharge": ["amount": 100]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 100)
        XCTAssertNil(result?["VISA"])
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
            ["type": "VISA", "surcharge": ["amount": 0]],
            ["type": "MASTERCARD", "surcharge": ["amount": 0]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksArray_WithMixedFormats_HandlesBoth() {
        // Given - Mix of nested and direct surcharge formats
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 100]],  // Nested format
            ["type": "MASTERCARD", "surcharge": 75]  // Direct integer format
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?["VISA"], 100)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksArray_WithInvalidSurchargeType_SkipsEntry() {
        // Given - Surcharge is a string instead of int/dict
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": "invalid"],
            ["type": "MASTERCARD", "surcharge": ["amount": 50]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 50)
    }

    // MARK: - extractFromNetworksDict Tests

    func testExtractFromNetworksDict_WithEmptyDict_ReturnsNil() {
        // Given
        let networksDict: [String: [String: Any]] = [:]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksDict_WithNestedSurcharge_ExtractsCorrectly() {
        // Given - Dictionary format with nested surcharge
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 150]],
            "AMEX": ["surcharge": ["amount": 200]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?["VISA"], 150)
        XCTAssertEqual(result?["AMEX"], 200)
    }

    func testExtractFromNetworksDict_WithDirectSurcharge_ExtractsCorrectly() {
        // Given - Dictionary format with direct integer surcharge
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": 100],
            "MASTERCARD": ["surcharge": 75]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?["VISA"], 100)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksDict_WithZeroSurcharge_ExcludesEntry() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 0]],
            "MASTERCARD": ["surcharge": ["amount": 100]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 100)
        XCTAssertNil(result?["VISA"])
    }

    func testExtractFromNetworksDict_WithMissingSurchargeKey_SkipsEntry() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["otherKey": "value"],  // No surcharge key
            "MASTERCARD": ["surcharge": ["amount": 50]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 50)
    }
}

// MARK: - Extract Networks Dict Additional Tests

@available(iOS 15.0, *)
final class ExtractNetworksDictAdditionalTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testExtractFromNetworksDict_WithNegativeSurcharge_ExcludesEntry() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": -100]],
            "MASTERCARD": ["surcharge": ["amount": 50]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 50)
        XCTAssertNil(result?["VISA"])
    }

    func testExtractFromNetworksDict_WithAllNegativeSurcharges_ReturnsNil() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": -100]],
            "MASTERCARD": ["surcharge": ["amount": -50]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksDict_WithMixedFormats_HandlesBoth() {
        // Given - Mix of nested and direct surcharge formats
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 100]],  // Nested format
            "MASTERCARD": ["surcharge": 75]  // Direct integer format
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?["VISA"], 100)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksDict_WithInvalidSurchargeType_SkipsEntry() {
        // Given - Surcharge is a string instead of int/dict
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": "invalid"],
            "MASTERCARD": ["surcharge": ["amount": 50]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 50)
    }

    func testExtractFromNetworksDict_WithMissingAmountKey_SkipsEntry() {
        // Given - Surcharge dict exists but no "amount" key
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["otherKey": 100]],
            "MASTERCARD": ["surcharge": ["amount": 75]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksDict_WithEmptyNestedDict_SkipsEntry() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": [:]],  // Empty surcharge dict
            "MASTERCARD": ["surcharge": ["amount": 100]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 100)
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

    func testExtractFromNetworksArray_WithEmptyNestedDict_SkipsEntry() {
        // Given
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": [:]],  // Empty surcharge dict
            ["type": "MASTERCARD", "surcharge": ["amount": 100]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 100)
    }

    func testExtractFromNetworksArray_WithMissingAmountKey_SkipsEntry() {
        // Given
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["currency": "EUR"]],  // No amount
            ["type": "MASTERCARD", "surcharge": ["amount": 75]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksArray_WithFloatAmount_SkipsEntry() {
        // Given - Float amounts should be skipped (only Int is valid)
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 99.99]],  // Float
            ["type": "MASTERCARD", "surcharge": ["amount": 100]]  // Int
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 100)
    }

    func testExtractFromNetworksArray_WithLargeAmount_IncludesEntry() {
        // Given - Large amounts should work
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 999999999]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?["VISA"], 999999999)
    }

    func testExtractFromNetworksArray_WithDuplicateNetworkTypes_KeepsLast() {
        // Given - Duplicate network types
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 50]],
            ["type": "VISA", "surcharge": ["amount": 100]]  // Duplicate
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then - Dictionary keeps last value for duplicate keys
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["VISA"], 100)
    }
}
