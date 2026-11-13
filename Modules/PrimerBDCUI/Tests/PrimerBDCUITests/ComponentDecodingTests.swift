//
//  ComponentDecodingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCUI
import XCTest

final class ComponentDecodingTests: XCTestCase {
    func testButtonDrawsTheNodesInItsChildren() throws {
        let definition = try decode("""
        {"type": "Button", "id": "confirm", "props": {"variant": "'primary'"},
         "children": [{"type": "Text", "props": {"text": "'Continue'"}}]}
        """)
        guard case let .button(content, _) = definition.component else { return XCTFail("expected a button") }
        XCTAssertEqual(content.children.count, 1)
        guard case .text = content.children.first?.component else { return XCTFail("expected the label") }
    }

    func testButtonStillAcceptsASingleContentNode() throws {
        let definition = try decode("""
        {"type": "Button", "props": {}, "content": {"type": "Text", "props": {"text": "'Pay'"}}}
        """)
        guard case let .button(content, _) = definition.component else { return XCTFail("expected a button") }
        XCTAssertEqual(content.children.count, 1)
    }

    func testButtonPrefersChildrenWhenBothArePresent() throws {
        let definition = try decode("""
        {"type": "Button", "props": {},
         "content": {"type": "Text", "props": {"text": "'template'"}},
         "children": [{"type": "Spacer"}, {"type": "Spacer"}]}
        """)
        guard case let .button(content, _) = definition.component else { return XCTFail("expected a button") }
        XCTAssertEqual(content.children.count, 2)
    }

    func testButtonWithNoLabelDecodesEmpty() throws {
        let definition = try decode("""
        {"type": "Button", "props": {}}
        """)
        guard case let .button(content, _) = definition.component else { return XCTFail("expected a button") }
        XCTAssertTrue(content.children.isEmpty)
    }

    func testListDrawsTheChildrenTheEngineExpandedFromItsDataSource() throws {
        let definition = try decode("""
        {"type": "List", "props": {"mode": "single", "dataSource": [{"id": "a"}, {"id": "b"}]},
         "children": [{"type": "Text", "props": {"text": "'a'"}}, {"type": "Text", "props": {"text": "'b'"}}]}
        """)
        guard case let .list(content, _) = definition.component else { return XCTFail("expected a list") }
        XCTAssertEqual(content.children.count, 2)
    }

    private func decode(_ json: String) throws -> UIDefinition {
        try JSONDecoder().decode(UIDefinition.self, from: Data(json.utf8))
    }
}
