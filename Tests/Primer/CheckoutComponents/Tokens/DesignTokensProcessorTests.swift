//
//  DesignTokensProcessorTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for DesignTokensProcessor utility methods.
@available(iOS 15.0, *)
final class DesignTokensProcessorTests: XCTestCase {

    // MARK: - mergeDictionaries Tests

    func test_mergeDictionaries_withSimpleValues_overridesBase() {
        // Given
        let base = ["key1": "value1", "key2": "value2"] as [String: Any]
        let override = ["key2": "newValue2"] as [String: Any]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        XCTAssertEqual(result["key1"] as? String, "value1")
        XCTAssertEqual(result["key2"] as? String, "newValue2")
    }

    func test_mergeDictionaries_withNestedDictionaries_mergesRecursively() {
        // Given
        let base = [
            "colors": [
                "primary": "#FF0000",
                "secondary": "#00FF00"
            ] as [String: Any]
        ] as [String: Any]
        let override = [
            "colors": [
                "secondary": "#0000FF"
            ] as [String: Any]
        ] as [String: Any]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        let colors = result["colors"] as? [String: Any]
        XCTAssertEqual(colors?["primary"] as? String, "#FF0000")
        XCTAssertEqual(colors?["secondary"] as? String, "#0000FF")
    }

    func test_mergeDictionaries_withEmptyOverride_returnsBase() {
        // Given
        let base = ["key": "value"] as [String: Any]
        let override: [String: Any] = [:]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        XCTAssertEqual(result["key"] as? String, "value")
    }

    func test_mergeDictionaries_withNewKeys_addsToResult() {
        // Given
        let base = ["existing": "value"] as [String: Any]
        let override = ["new": "newValue"] as [String: Any]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        XCTAssertEqual(result["existing"] as? String, "value")
        XCTAssertEqual(result["new"] as? String, "newValue")
    }

    // MARK: - resolveReferences Tests

    func test_resolveReferences_withNoReferences_returnsOriginal() {
        // Given
        let dict = ["key": "value"] as [String: Any]

        // When
        let result = DesignTokensProcessor.resolveReferences(in: dict)

        // Then
        XCTAssertEqual(result["key"] as? String, "value")
    }

    func test_resolveReferences_withNestedStructure_preservesNonReferences() {
        // Given
        let dict = [
            "colors": [
                "primary": "#FF0000"
            ] as [String: Any],
            "spacing": [
                "base": 8
            ] as [String: Any]
        ] as [String: Any]

        // When
        let result = DesignTokensProcessor.resolveReferences(in: dict)

        // Then - Non-reference values should be preserved
        let colors = result["colors"] as? [String: Any]
        let spacing = result["spacing"] as? [String: Any]
        XCTAssertEqual(colors?["primary"] as? String, "#FF0000")
        XCTAssertEqual(spacing?["base"] as? Int, 8)
    }

    func test_resolveReferences_withUnresolvableReference_preservesOriginal() {
        // Given - A reference to a non-existent path
        let dict = [
            "button": [
                "color": "{nonexistent.path}"
            ] as [String: Any]
        ] as [String: Any]

        // When
        let result = DesignTokensProcessor.resolveReferences(in: dict)

        // Then - Unresolvable references are preserved
        let button = result["button"] as? [String: Any]
        XCTAssertEqual(button?["color"] as? String, "{nonexistent.path}")
    }

    func test_resolveReferences_withEmptyDictionary_returnsEmpty() {
        // Given
        let dict: [String: Any] = [:]

        // When
        let result = DesignTokensProcessor.resolveReferences(in: dict)

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - convertHexColors Tests

    func test_convertHexColors_withSixDigitHex_convertsToRGBA() {
        // Given
        let dict = ["color": "#FF0000"] as [String: Any]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        guard let color = result["color"] as? [CGFloat], color.count == 4 else {
            XCTFail("Color should be a 4-element CGFloat array")
            return
        }
        XCTAssertEqual(color[0], 1.0, accuracy: 0.01) // Red
        XCTAssertEqual(color[1], 0.0, accuracy: 0.01) // Green
        XCTAssertEqual(color[2], 0.0, accuracy: 0.01) // Blue
        XCTAssertEqual(color[3], 1.0, accuracy: 0.01) // Alpha
    }

    func test_convertHexColors_withEightDigitHex_convertsToRGBAWithAlpha() {
        // Given - #FF0000 with 80 alpha (50%)
        let dict = ["color": "#FF000080"] as [String: Any]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        guard let color = result["color"] as? [CGFloat], color.count == 4 else {
            XCTFail("Color should be a 4-element CGFloat array")
            return
        }
        XCTAssertEqual(color[0], 1.0, accuracy: 0.01) // Red
        XCTAssertEqual(color[1], 0.0, accuracy: 0.01) // Green
        XCTAssertEqual(color[2], 0.0, accuracy: 0.01) // Blue
        XCTAssertEqual(color[3], 128.0 / 255.0, accuracy: 0.01) // Alpha ~0.5
    }

    func test_convertHexColors_withNestedDictionary_convertsRecursively() {
        // Given
        let dict = [
            "colors": [
                "primary": "#00FF00"
            ] as [String: Any]
        ] as [String: Any]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        guard let colors = result["colors"] as? [String: Any],
              let primary = colors["primary"] as? [CGFloat],
              primary.count >= 2 else {
            XCTFail("Color should be converted")
            return
        }
        XCTAssertEqual(primary[1], 1.0, accuracy: 0.01) // Green is max
    }

    func test_convertHexColors_withNonHexValue_preservesOriginal() {
        // Given
        let dict = ["size": "16px", "count": 5] as [String: Any]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        XCTAssertEqual(result["size"] as? String, "16px")
        XCTAssertEqual(result["count"] as? Int, 5)
    }

    func test_convertHexColors_withWhiteColor_convertsCorrectly() {
        // Given
        let dict = ["color": "#FFFFFF"] as [String: Any]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        guard let color = result["color"] as? [CGFloat], color.count >= 3 else {
            XCTFail("Color should be converted")
            return
        }
        XCTAssertEqual(color[0], 1.0, accuracy: 0.01) // Red
        XCTAssertEqual(color[1], 1.0, accuracy: 0.01) // Green
        XCTAssertEqual(color[2], 1.0, accuracy: 0.01) // Blue
    }

    func test_convertHexColors_withBlackColor_convertsCorrectly() {
        // Given
        let dict = ["color": "#000000"] as [String: Any]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        guard let color = result["color"] as? [CGFloat], color.count >= 3 else {
            XCTFail("Color should be converted")
            return
        }
        XCTAssertEqual(color[0], 0.0, accuracy: 0.01) // Red
        XCTAssertEqual(color[1], 0.0, accuracy: 0.01) // Green
        XCTAssertEqual(color[2], 0.0, accuracy: 0.01) // Blue
    }

    // MARK: - flattenTokenDictionary Tests

    func test_flattenTokenDictionary_withNestedStructure_flattens() {
        // Given
        let dict = [
            "primer": [
                "color": [
                    "brand": ["value": "#FF0000"] as [String: Any]
                ] as [String: Any]
            ] as [String: Any]
        ] as [String: Any]

        // When
        let result = DesignTokensProcessor.flattenTokenDictionary(dict)

        // Then
        XCTAssertEqual(result["primerColorBrand"] as? String, "#FF0000")
    }

    func test_flattenTokenDictionary_withMultipleTokens_flattensToCamelCase() {
        // Given
        let dict = [
            "space": [
                "small": ["value": 8] as [String: Any],
                "medium": ["value": 16] as [String: Any]
            ] as [String: Any]
        ] as [String: Any]

        // When
        let result = DesignTokensProcessor.flattenTokenDictionary(dict)

        // Then
        XCTAssertEqual(result["spaceSmall"] as? Int, 8)
        XCTAssertEqual(result["spaceMedium"] as? Int, 16)
    }

    func test_flattenTokenDictionary_preservesNonValueNodes() {
        // Given - when there's no "value" key, it flattens further
        let dict = [
            "primer": [
                "radius": [
                    "base": 4
                ] as [String: Any]
            ] as [String: Any]
        ] as [String: Any]

        // When
        let result = DesignTokensProcessor.flattenTokenDictionary(dict)

        // Then
        XCTAssertEqual(result["primerRadiusBase"] as? Int, 4)
    }

    // MARK: - resolveFlattenedReferences Tests

    func test_resolveFlattenedReferences_withReference_resolves() {
        // Given
        let flatDict = [
            "baseColor": "#FF0000",
            "buttonColor": "{base.color}"
        ] as [String: Any]
        let source = [
            "base": [
                "color": ["value": "#FF0000"] as [String: Any]
            ] as [String: Any]
        ] as [String: Any]

        // When
        let result = DesignTokensProcessor.resolveFlattenedReferences(in: flatDict, source: source)

        // Then
        XCTAssertEqual(result["baseColor"] as? String, "#FF0000")
        XCTAssertEqual(result["buttonColor"] as? String, "#FF0000")
    }

    func test_resolveFlattenedReferences_withNoReferences_preservesValues() {
        // Given
        let flatDict = [
            "spacing": 16,
            "color": "#00FF00"
        ] as [String: Any]
        let source: [String: Any] = [:]

        // When
        let result = DesignTokensProcessor.resolveFlattenedReferences(in: flatDict, source: source)

        // Then
        XCTAssertEqual(result["spacing"] as? Int, 16)
        XCTAssertEqual(result["color"] as? String, "#00FF00")
    }

    // MARK: - evaluateMath Tests

    func test_evaluateMath_withMultiplication_evaluates() {
        // Given
        let dict = ["result": "4 * 4"] as [String: Any]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        guard let value = result["result"] as? Double else {
            XCTFail("Result should be a Double")
            return
        }
        XCTAssertEqual(value, 16.0, accuracy: 0.01)
    }

    func test_evaluateMath_withDivision_evaluates() {
        // Given
        let dict = ["result": "20 / 4"] as [String: Any]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        guard let value = result["result"] as? Double else {
            XCTFail("Result should be a Double")
            return
        }
        XCTAssertEqual(value, 5.0, accuracy: 0.01)
    }

    func test_evaluateMath_withAddition_evaluates() {
        // Given
        let dict = ["result": "10 + 5"] as [String: Any]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        guard let value = result["result"] as? Double else {
            XCTFail("Result should be a Double")
            return
        }
        XCTAssertEqual(value, 15.0, accuracy: 0.01)
    }

    func test_evaluateMath_withSubtraction_evaluates() {
        // Given
        let dict = ["result": "20 - 8"] as [String: Any]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        guard let value = result["result"] as? Double else {
            XCTFail("Result should be a Double")
            return
        }
        XCTAssertEqual(value, 12.0, accuracy: 0.01)
    }

    func test_evaluateMath_withDivisionByZero_returnsNil() {
        // Given
        let dict = ["result": "10 / 0"] as [String: Any]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then - should preserve original string when division by zero
        XCTAssertEqual(result["result"] as? String, "10 / 0")
    }

    func test_evaluateMath_withNonMathString_preservesOriginal() {
        // Given
        let dict = ["text": "hello world", "color": "#FF0000"] as [String: Any]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["text"] as? String, "hello world")
        XCTAssertEqual(result["color"] as? String, "#FF0000")
    }

    func test_evaluateMath_withDecimalNumbers_evaluates() {
        // Given
        let dict = ["result": "2.5 * 4"] as [String: Any]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        guard let value = result["result"] as? Double else {
            XCTFail("Result should be a Double")
            return
        }
        XCTAssertEqual(value, 10.0, accuracy: 0.01)
    }

    func test_evaluateMath_withNonNumericValue_preservesOriginal() {
        // Given
        let dict = ["count": 42] as [String: Any]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["count"] as? Int, 42)
    }

    // MARK: - Integration Tests

    func test_fullProcessingPipeline_processesTokensCorrectly() {
        // Given - a realistic token structure
        let baseTokens = [
            "primer": [
                "color": [
                    "brand": ["value": "#3366FF"] as [String: Any]
                ] as [String: Any],
                "space": [
                    "base": ["value": 8] as [String: Any],
                    "medium": ["value": "8 * 2"] as [String: Any]
                ] as [String: Any]
            ] as [String: Any]
        ] as [String: Any]

        // When - run through the full pipeline
        var processed = DesignTokensProcessor.resolveReferences(in: baseTokens)
        processed = DesignTokensProcessor.convertHexColors(in: processed)
        var flat = DesignTokensProcessor.flattenTokenDictionary(processed)
        flat = DesignTokensProcessor.evaluateMath(in: flat)

        // Then
        let brand = flat["primerColorBrand"] as? [CGFloat]
        XCTAssertNotNil(brand)
        XCTAssertEqual(flat["primerSpaceBase"] as? Int, 8)
        if let mediumValue = flat["primerSpaceMedium"] as? Double {
            XCTAssertEqual(mediumValue, 16.0, accuracy: 0.01)
        } else {
            XCTFail("primerSpaceMedium should be a Double")
        }
    }
}
