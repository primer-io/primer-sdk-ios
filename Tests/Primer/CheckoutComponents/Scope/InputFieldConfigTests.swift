//
//  InputFieldConfigTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for InputFieldConfig struct initialization and properties.
@available(iOS 15.0, *)
final class InputFieldConfigTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_allNil_createsEmptyConfig() {
        // When
        let config = InputFieldConfig()

        // Then
        XCTAssertNil(config.label)
        XCTAssertNil(config.placeholder)
        XCTAssertNil(config.styling)
        XCTAssertNil(config.component)
    }

    func test_init_withLabel_setsLabel() {
        // When
        let config = InputFieldConfig(label: "Card Number")

        // Then
        XCTAssertEqual(config.label, "Card Number")
        XCTAssertNil(config.placeholder)
        XCTAssertNil(config.styling)
        XCTAssertNil(config.component)
    }

    func test_init_withPlaceholder_setsPlaceholder() {
        // When
        let config = InputFieldConfig(placeholder: "0000 0000 0000 0000")

        // Then
        XCTAssertNil(config.label)
        XCTAssertEqual(config.placeholder, "0000 0000 0000 0000")
        XCTAssertNil(config.styling)
        XCTAssertNil(config.component)
    }

    func test_init_withStyling_setsStyling() {
        // Given
        let styling = PrimerFieldStyling()

        // When
        let config = InputFieldConfig(styling: styling)

        // Then
        XCTAssertNil(config.label)
        XCTAssertNil(config.placeholder)
        XCTAssertNotNil(config.styling)
        XCTAssertNil(config.component)
    }

    func test_init_withAllProperties_setsAllProperties() {
        // Given
        let styling = PrimerFieldStyling()

        // When
        let config = InputFieldConfig(
            label: "CVV",
            placeholder: "123",
            styling: styling
        )

        // Then
        XCTAssertEqual(config.label, "CVV")
        XCTAssertEqual(config.placeholder, "123")
        XCTAssertNotNil(config.styling)
    }

    func test_init_withComponent_setsComponent() {
        // Given
        let component: Component = { AnyView(Text("Custom")) }

        // When
        let config = InputFieldConfig(component: component)

        // Then
        XCTAssertNotNil(config.component)
        XCTAssertNil(config.label)
        XCTAssertNil(config.placeholder)
        XCTAssertNil(config.styling)
    }
}
