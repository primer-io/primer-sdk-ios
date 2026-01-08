//
//  TypeKeyTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

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
}
