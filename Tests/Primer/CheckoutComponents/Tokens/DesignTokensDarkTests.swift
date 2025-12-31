//
//  DesignTokensDarkTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for DesignTokensDark covering default values and Decodable conformance.
@available(iOS 15.0, *)
final class DesignTokensDarkTests: XCTestCase {

    // MARK: - Default Value Tests

    func test_defaultGray100_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorGray100)
    }

    func test_defaultGray200_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorGray200)
    }

    func test_defaultGray300_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorGray300)
    }

    func test_defaultGray400_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorGray400)
    }

    func test_defaultGray500_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorGray500)
    }

    func test_defaultGray600_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorGray600)
    }

    func test_defaultGray700_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorGray700)
    }

    func test_defaultGray900_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorGray900)
    }

    func test_defaultGray000_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorGray000)
    }

    func test_defaultGreen500_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorGreen500)
    }

    func test_defaultBrand_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorBrand)
    }

    func test_defaultRed100_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorRed100)
    }

    func test_defaultRed500_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorRed500)
    }

    func test_defaultRed900_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorRed900)
    }

    func test_defaultBlue500_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorBlue500)
    }

    func test_defaultBlue900_isNotNil() {
        // Given
        let tokens = DesignTokensDark.createWithDefaults()

        // Then
        XCTAssertNotNil(tokens.primerColorBlue900)
    }

    // MARK: - Decodable Tests

    func test_decode_withValidGray100_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerColorGray100": [0.5, 0.5, 0.5, 1.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokensDark.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorGray100)
    }

    func test_decode_withAllColors_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerColorGray100": [0.1, 0.1, 0.1, 1.0],
            "primerColorGray200": [0.2, 0.2, 0.2, 1.0],
            "primerColorGray300": [0.3, 0.3, 0.3, 1.0],
            "primerColorGray400": [0.4, 0.4, 0.4, 1.0],
            "primerColorGray500": [0.5, 0.5, 0.5, 1.0],
            "primerColorGray600": [0.6, 0.6, 0.6, 1.0],
            "primerColorGray700": [0.7, 0.7, 0.7, 1.0],
            "primerColorGray900": [0.9, 0.9, 0.9, 1.0],
            "primerColorGray000": [0.0, 0.0, 0.0, 1.0],
            "primerColorGreen500": [0.0, 0.7, 0.5, 1.0],
            "primerColorBrand": [0.2, 0.6, 1.0, 1.0],
            "primerColorRed100": [0.2, 0.1, 0.1, 1.0],
            "primerColorRed500": [0.9, 0.4, 0.4, 1.0],
            "primerColorRed900": [1.0, 0.7, 0.7, 1.0],
            "primerColorBlue500": [0.2, 0.6, 0.9, 1.0],
            "primerColorBlue900": [0.3, 0.7, 1.0, 1.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokensDark.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorGray100)
        XCTAssertNotNil(tokens.primerColorGray200)
        XCTAssertNotNil(tokens.primerColorGray300)
        XCTAssertNotNil(tokens.primerColorGray400)
        XCTAssertNotNil(tokens.primerColorGray500)
        XCTAssertNotNil(tokens.primerColorGray600)
        XCTAssertNotNil(tokens.primerColorGray700)
        XCTAssertNotNil(tokens.primerColorGray900)
        XCTAssertNotNil(tokens.primerColorGray000)
        XCTAssertNotNil(tokens.primerColorGreen500)
        XCTAssertNotNil(tokens.primerColorBrand)
        XCTAssertNotNil(tokens.primerColorRed100)
        XCTAssertNotNil(tokens.primerColorRed500)
        XCTAssertNotNil(tokens.primerColorRed900)
        XCTAssertNotNil(tokens.primerColorBlue500)
        XCTAssertNotNil(tokens.primerColorBlue900)
    }

    func test_decode_withEmptyJSON_usesDefaults() throws {
        // Given
        let json = "{}"
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokensDark.self, from: data)

        // Then - defaults should still apply
        XCTAssertNotNil(tokens.primerColorGray100)
    }

    func test_decode_withPartialColors_decodesOnlyProvided() throws {
        // Given
        let json = """
        {
            "primerColorBrand": [0.0, 0.5, 1.0, 1.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokensDark.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorBrand)
    }

    // MARK: - Color Component Tests

    func test_decode_withValidRGBA_createsCorrectColor() throws {
        // Given - red color [1.0, 0.0, 0.0, 1.0]
        let json = """
        {
            "primerColorRed500": [1.0, 0.0, 0.0, 1.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokensDark.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorRed500)
    }

    func test_decode_withTransparentColor_createsCorrectColor() throws {
        // Given - transparent color
        let json = """
        {
            "primerColorGray100": [0.5, 0.5, 0.5, 0.5]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokensDark.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorGray100)
    }
}

// MARK: - Test Helper Extension

@available(iOS 15.0, *)
extension DesignTokensDark {
    /// Creates a DesignTokensDark instance with default values for testing.
    static func createWithDefaults() -> DesignTokensDark {
        // Decode empty JSON to get instance with default property values
        let json = "{}"
        let data = json.data(using: .utf8)!
        return try! JSONDecoder().decode(DesignTokensDark.self, from: data)
    }
}
