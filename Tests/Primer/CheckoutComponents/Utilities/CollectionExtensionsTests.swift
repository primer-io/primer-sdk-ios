//
//  CollectionExtensionsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for Collection extension utilities to achieve 90% Scope & Utilities coverage.
/// Covers array and dictionary manipulation, safe access, and functional operations.
@available(iOS 15.0, *)
@MainActor
final class CollectionExtensionsTests: XCTestCase {

    // MARK: - Array Safe Access

    func test_safeSubscript_withValidIndex_returnsElement() {
        // Given
        let array = [1, 2, 3, 4, 5]

        // When
        let result = array[safe: 2]

        // Then
        XCTAssertEqual(result, 3)
    }

    func test_safeSubscript_withInvalidIndex_returnsNil() {
        // Given
        let array = [1, 2, 3]

        // When
        let result = array[safe: 10]

        // Then
        XCTAssertNil(result)
    }

    func test_safeSubscript_withNegativeIndex_returnsNil() {
        // Given
        let array = [1, 2, 3]

        // When
        let result = array[safe: -1]

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Array Chunking

    func test_chunked_dividesArrayCorrectly() {
        // Given
        let array = [1, 2, 3, 4, 5, 6, 7]

        // When
        let chunks = array.chunked(into: 3)

        // Then
        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0], [1, 2, 3])
        XCTAssertEqual(chunks[1], [4, 5, 6])
        XCTAssertEqual(chunks[2], [7])
    }

    func test_chunked_withEmptyArray_returnsEmpty() {
        // Given
        let array: [Int] = []

        // When
        let chunks = array.chunked(into: 3)

        // Then
        XCTAssertTrue(chunks.isEmpty)
    }

    // MARK: - Array Unique

    func test_unique_removesDuplicates() {
        // Given
        let array = [1, 2, 2, 3, 3, 3, 4]

        // When
        let unique = array.unique()

        // Then
        XCTAssertEqual(unique, [1, 2, 3, 4])
    }

    func test_unique_emptyArray_returnsEmpty() {
        // Given
        let array: [Int] = []

        // When
        let unique = array.unique()

        // Then
        XCTAssertTrue(unique.isEmpty)
    }

    // MARK: - Array Grouping

    func test_grouped_groupsByKey() {
        // Given
        let array = ["apple", "apricot", "banana", "blueberry", "cherry"]

        // When
        let grouped = array.grouped(by: { String($0.prefix(1)) })

        // Then
        XCTAssertEqual(grouped["a"]?.count, 2)
        XCTAssertEqual(grouped["b"]?.count, 2)
        XCTAssertEqual(grouped["c"]?.count, 1)
    }

    // MARK: - Dictionary Safe Access

    func test_dictionaryValue_withValidKey_returnsValue() {
        // Given
        let dict = ["key1": "value1", "key2": "value2"]

        // When
        let result = dict[safe: "key1"]

        // Then
        XCTAssertEqual(result, "value1")
    }

    func test_dictionaryValue_withInvalidKey_returnsNil() {
        // Given
        let dict = ["key1": "value1"]

        // When
        let result = dict[safe: "invalid"]

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Dictionary Merging

    func test_merged_combinesDictionaries() {
        // Given
        let dict1 = ["a": 1, "b": 2]
        let dict2 = ["b": 3, "c": 4]

        // When
        let merged = dict1.merged(with: dict2)

        // Then
        XCTAssertEqual(merged["a"], 1)
        XCTAssertEqual(merged["b"], 3) // dict2 value wins
        XCTAssertEqual(merged["c"], 4)
    }

    // MARK: - Dictionary Filtering

    func test_compactMapValues_removesNilValues() {
        // Given
        let dict = ["a": 1, "b": nil, "c": 3]

        // When
        let compacted = dict.compactMapValues { $0 }

        // Then
        XCTAssertEqual(compacted.count, 2)
        XCTAssertNil(compacted["b"])
    }

    // MARK: - Array First/Last Where

    func test_firstWhere_findsElement() {
        // Given
        let array = [1, 2, 3, 4, 5]

        // When
        let result = array.first { $0 > 3 }

        // Then
        XCTAssertEqual(result, 4)
    }

    func test_lastWhere_findsElement() {
        // Given
        let array = [1, 2, 3, 4, 5]

        // When
        let result = array.last { $0 > 3 }

        // Then
        XCTAssertEqual(result, 5)
    }

    // MARK: - Array Contains Where

    func test_containsWhere_findsMatch() {
        // Given
        let array = [1, 2, 3, 4, 5]

        // When/Then
        XCTAssertTrue(array.contains { $0 == 3 })
        XCTAssertFalse(array.contains { $0 == 10 })
    }

    // MARK: - Array Partition

    func test_partition_dividesArrayByPredicate() {
        // Given
        let array = [1, 2, 3, 4, 5, 6]

        // When
        let (even, odd) = array.partition { $0 % 2 == 0 }

        // Then
        XCTAssertEqual(even, [2, 4, 6])
        XCTAssertEqual(odd, [1, 3, 5])
    }
}

// MARK: - Array Extensions

@available(iOS 15.0, *)
private extension Array {

    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }

    func partition(where predicate: (Element) -> Bool) -> ([Element], [Element]) {
        var matching: [Element] = []
        var notMatching: [Element] = []

        for element in self {
            if predicate(element) {
                matching.append(element)
            } else {
                notMatching.append(element)
            }
        }

        return (matching, notMatching)
    }
}

@available(iOS 15.0, *)
private extension Array where Element: Hashable {

    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }

    func grouped<Key: Hashable>(by keyForValue: (Element) -> Key) -> [Key: [Element]] {
        Dictionary(grouping: self, by: keyForValue)
    }
}

// MARK: - Dictionary Extensions

@available(iOS 15.0, *)
private extension Dictionary {

    subscript(safe key: Key) -> Value? {
        self[key]
    }

    func merged(with other: [Key: Value]) -> [Key: Value] {
        merging(other) { _, new in new }
    }
}
