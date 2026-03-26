//
//  TypeKeyTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class TypeKeyTests: XCTestCase {

    // MARK: - Test Types

    private protocol TestProtocol {}
    private final class TestClass: TestProtocol {}
    private struct TestStruct {}

    // MARK: - Equality Tests

    func test_equality_sameType_noName_areEqual() {
        // Given
        let key1 = TypeKey(TestProtocol.self)
        let key2 = TypeKey(TestProtocol.self)

        // When/Then
        XCTAssertEqual(key1, key2)
    }

    func test_equality_sameType_sameName_areEqual() {
        // Given
        let key1 = TypeKey(TestProtocol.self, name: "default")
        let key2 = TypeKey(TestProtocol.self, name: "default")

        // When/Then
        XCTAssertEqual(key1, key2)
    }

    func test_equality_sameType_differentNames_areNotEqual() {
        // Given
        let key1 = TypeKey(TestProtocol.self, name: "default")
        let key2 = TypeKey(TestProtocol.self, name: "custom")

        // When/Then
        XCTAssertNotEqual(key1, key2)
    }

    func test_equality_sameType_oneNamed_oneUnnamed_areNotEqual() {
        // Given
        let key1 = TypeKey(TestProtocol.self)
        let key2 = TypeKey(TestProtocol.self, name: "default")

        // When/Then
        XCTAssertNotEqual(key1, key2)
    }

    func test_equality_differentTypes_areNotEqual() {
        // Given
        let key1 = TypeKey(TestProtocol.self)
        let key2 = TypeKey(TestClass.self)

        // When/Then
        XCTAssertNotEqual(key1, key2)
    }

    // MARK: - Hashing Tests

    func test_hash_sameKeys_produceSameHash() {
        // Given
        let key1 = TypeKey(TestProtocol.self, name: "test")
        let key2 = TypeKey(TestProtocol.self, name: "test")

        // When
        var set = Set<TypeKey>()
        set.insert(key1)
        set.insert(key2)

        // Then
        XCTAssertEqual(set.count, 1)
    }

    func test_hash_differentKeys_canBeUsedInDictionary() {
        // Given
        let key1 = TypeKey(TestProtocol.self)
        let key2 = TypeKey(TestClass.self)
        let key3 = TypeKey(TestStruct.self)

        // When
        var dict: [TypeKey: String] = [:]
        dict[key1] = "protocol"
        dict[key2] = "class"
        dict[key3] = "struct"

        // Then
        XCTAssertEqual(dict.count, 3)
        XCTAssertEqual(dict[key1], "protocol")
        XCTAssertEqual(dict[key2], "class")
        XCTAssertEqual(dict[key3], "struct")
    }

    // MARK: - represents Tests

    func test_represents_matchingType_returnsTrue() {
        // Given
        let key = TypeKey(TestProtocol.self)

        // Then
        XCTAssertTrue(key.represents(TestProtocol.self))
    }

    func test_represents_differentType_returnsFalse() {
        // Given
        let key = TypeKey(TestProtocol.self)

        // Then
        XCTAssertFalse(key.represents(TestClass.self))
    }

    // MARK: - description Tests

    func test_description_withoutName_returnsTypeName() {
        // Given
        let key = TypeKey(String.self)

        // Then
        XCTAssertTrue(key.description.contains("String"))
        XCTAssertFalse(key.description.contains("name:"))
    }

    func test_description_withName_includesName() {
        // Given
        let key = TypeKey(String.self, name: "primary")

        // Then
        XCTAssertTrue(key.description.contains("String"))
        XCTAssertTrue(key.description.contains("name: primary"))
    }

    // MARK: - debugDescription Tests

    func test_debugDescription_withoutName_containsTypeId() {
        // Given
        let key = TypeKey(String.self)

        // Then
        XCTAssertTrue(key.debugDescription.contains("TypeKey"))
        XCTAssertTrue(key.debugDescription.contains("String"))
    }

    func test_debugDescription_withName_containsNameAndTypeId() {
        // Given
        let key = TypeKey(String.self, name: "debug")

        // Then
        XCTAssertTrue(key.debugDescription.contains("TypeKey"))
        XCTAssertTrue(key.debugDescription.contains("debug"))
    }

    // MARK: - Codable Tests

    func test_codable_encodeDecode_preservesTypeName() throws {
        // Given
        let key = TypeKey(String.self, name: "codable")

        // When
        let data = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(TypeKey.self, from: data)

        // Then
        XCTAssertTrue(decoded.description.contains("String"))
        XCTAssertTrue(decoded.description.contains("codable"))
    }

    func test_codable_withoutName_encodesAndDecodes() throws {
        // Given
        let key = TypeKey(Int.self)

        // When
        let data = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(TypeKey.self, from: data)

        // Then
        XCTAssertTrue(decoded.description.contains("Int"))
    }
}
