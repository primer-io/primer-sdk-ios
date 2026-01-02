//
//  TypeKeyTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for TypeKey struct covering initialization, equality, hashing, and Codable conformance.
@available(iOS 15.0, *)
final class TypeKeyTests: XCTestCase {

    // MARK: - Test Types

    private protocol TestProtocol {}
    private final class TestClass: TestProtocol {}
    private struct TestStruct {}

    // MARK: - Initialization Tests

    func test_init_withType_createsKey() {
        // When
        let key = TypeKey(TestProtocol.self)

        // Then
        XCTAssertTrue(key.represents(TestProtocol.self))
    }

    func test_init_withTypeAndName_createsNamedKey() {
        // When
        let key = TypeKey(TestProtocol.self, name: "default")

        // Then
        XCTAssertTrue(key.represents(TestProtocol.self))
        XCTAssertTrue(key.description.contains("default"))
    }

    // MARK: - Represents Tests

    func test_represents_returnsTrue_forMatchingType() {
        // Given
        let key = TypeKey(TestProtocol.self)

        // When/Then
        XCTAssertTrue(key.represents(TestProtocol.self))
    }

    func test_represents_returnsFalse_forDifferentType() {
        // Given
        let key = TypeKey(TestProtocol.self)

        // When/Then
        XCTAssertFalse(key.represents(TestClass.self))
        XCTAssertFalse(key.represents(TestStruct.self))
    }

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

    // MARK: - Hashable Tests

    func test_hashable_equalKeys_haveSameHash() {
        // Given
        let key1 = TypeKey(TestProtocol.self, name: "default")
        let key2 = TypeKey(TestProtocol.self, name: "default")

        // When/Then
        XCTAssertEqual(key1.hashValue, key2.hashValue)
    }

    func test_hashable_canBeUsedInSet() {
        // Given
        let key1 = TypeKey(TestProtocol.self)
        let key2 = TypeKey(TestClass.self)
        let key3 = TypeKey(TestProtocol.self) // Duplicate

        // When
        var set = Set<TypeKey>()
        set.insert(key1)
        set.insert(key2)
        set.insert(key3)

        // Then
        XCTAssertEqual(set.count, 2)
    }

    func test_hashable_canBeUsedAsDictionaryKey() {
        // Given
        let key1 = TypeKey(TestProtocol.self)
        let key2 = TypeKey(TestClass.self)

        // When
        var dict = [TypeKey: String]()
        dict[key1] = "protocol"
        dict[key2] = "class"

        // Then
        XCTAssertEqual(dict[key1], "protocol")
        XCTAssertEqual(dict[key2], "class")
    }

    // MARK: - Description Tests

    func test_description_withoutName_containsTypeName() {
        // Given
        let key = TypeKey(TestProtocol.self)

        // When
        let description = key.description

        // Then
        XCTAssertTrue(description.contains("TestProtocol"))
        XCTAssertFalse(description.contains("name:"))
    }

    func test_description_withName_containsTypeNameAndName() {
        // Given
        let key = TypeKey(TestProtocol.self, name: "custom")

        // When
        let description = key.description

        // Then
        XCTAssertTrue(description.contains("TestProtocol"))
        XCTAssertTrue(description.contains("name: custom"))
    }

    func test_debugDescription_containsMoreDetails() {
        // Given
        let key = TypeKey(TestProtocol.self, name: "custom")

        // When
        let debugDesc = key.debugDescription

        // Then
        XCTAssertTrue(debugDesc.contains("TypeKey"))
        XCTAssertTrue(debugDesc.contains("type:"))
        XCTAssertTrue(debugDesc.contains("id:"))
        XCTAssertTrue(debugDesc.contains("name: custom"))
    }

    func test_debugDescription_withoutName_omitsNameField() {
        // Given
        let key = TypeKey(TestProtocol.self)

        // When
        let debugDesc = key.debugDescription

        // Then
        XCTAssertTrue(debugDesc.contains("TypeKey"))
        XCTAssertTrue(debugDesc.contains("type:"))
        XCTAssertFalse(debugDesc.contains("name:"))
    }

    // MARK: - Codable Tests

    func test_encodeDecode_withoutName_preservesTypeName() throws {
        // Given
        let key = TypeKey(TestProtocol.self)

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(key)
        let decoder = JSONDecoder()
        let decodedKey = try decoder.decode(TypeKey.self, from: data)

        // Then - Note: ObjectIdentifier cannot be preserved through coding
        XCTAssertTrue(decodedKey.description.contains("TestProtocol"))
    }

    func test_encodeDecode_withName_preservesTypeNameAndName() throws {
        // Given
        let key = TypeKey(TestProtocol.self, name: "custom")

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(key)
        let decoder = JSONDecoder()
        let decodedKey = try decoder.decode(TypeKey.self, from: data)

        // Then
        XCTAssertTrue(decodedKey.description.contains("TestProtocol"))
        XCTAssertTrue(decodedKey.description.contains("custom"))
    }

    func test_encode_producesValidJSON() throws {
        // Given
        let key = TypeKey(TestProtocol.self, name: "test")

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(key)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["typeName"])
        XCTAssertEqual(json?["name"] as? String, "test")
    }

    func test_decode_fromValidJSON_succeeds() throws {
        // Given
        let json: [String: Any] = [
            "typeName": "SomeType",
            "name": "instance"
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        // When
        let decoder = JSONDecoder()
        let key = try decoder.decode(TypeKey.self, from: data)

        // Then
        XCTAssertTrue(key.description.contains("SomeType"))
        XCTAssertTrue(key.description.contains("instance"))
    }

    func test_decode_withoutName_succeeds() throws {
        // Given
        let json: [String: Any] = [
            "typeName": "SomeType"
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        // When
        let decoder = JSONDecoder()
        let key = try decoder.decode(TypeKey.self, from: data)

        // Then
        XCTAssertTrue(key.description.contains("SomeType"))
        XCTAssertFalse(key.description.contains("name:"))
    }

    // MARK: - Sendable Conformance Tests

    func test_canBeSentAcrossConcurrencyBoundaries() async {
        // Given
        let key = TypeKey(TestProtocol.self, name: "concurrent")

        // When - send across concurrency boundary
        let result = await Task.detached { () -> TypeKey in
            return key
        }.value

        // Then
        XCTAssertEqual(key, result)
    }

    // MARK: - Edge Cases

    func test_emptyName_treatedAsNamed() {
        // Given
        let keyWithEmpty = TypeKey(TestProtocol.self, name: "")
        let keyWithoutName = TypeKey(TestProtocol.self)

        // When/Then - empty string is still a name
        XCTAssertNotEqual(keyWithEmpty, keyWithoutName)
    }

    func test_whitespaceOnlyName_treatedAsNamed() {
        // Given
        let keyWithWhitespace = TypeKey(TestProtocol.self, name: "   ")
        let keyWithoutName = TypeKey(TestProtocol.self)

        // When/Then
        XCTAssertNotEqual(keyWithWhitespace, keyWithoutName)
    }
}
