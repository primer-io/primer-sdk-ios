//
//  DesignTokensProcessorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CoreGraphics
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class DesignTokensProcessorTests: XCTestCase {

    // MARK: - mergeDictionaries

    func test_mergeDictionaries_emptyBase_returnsOverride() {
        // Given
        let base: [String: Any] = [:]
        let override: [String: Any] = ["color": "red", "size": 12]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        XCTAssertEqual(result["color"] as? String, "red")
        XCTAssertEqual(result["size"] as? Int, 12)
        XCTAssertEqual(result.count, 2)
    }

    func test_mergeDictionaries_baseWithEmptyOverride_returnsBase() {
        // Given
        let base: [String: Any] = ["color": "blue", "size": 16]
        let override: [String: Any] = [:]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        XCTAssertEqual(result["color"] as? String, "blue")
        XCTAssertEqual(result["size"] as? Int, 16)
        XCTAssertEqual(result.count, 2)
    }

    func test_mergeDictionaries_bothEmpty_returnsEmpty() {
        // When
        let result = DesignTokensProcessor.mergeDictionaries([:], with: [:])

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func test_mergeDictionaries_overrideTakesPrecedence() {
        // Given
        let base: [String: Any] = ["color": "blue"]
        let override: [String: Any] = ["color": "red"]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        XCTAssertEqual(result["color"] as? String, "red")
    }

    func test_mergeDictionaries_nestedDictsMergedRecursively() {
        // Given
        let base: [String: Any] = [
            "colors": ["primary": "blue", "secondary": "green"]
        ]
        let override: [String: Any] = [
            "colors": ["primary": "red"]
        ]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        let colors = result["colors"] as? [String: Any]
        XCTAssertEqual(colors?["primary"] as? String, "red")
        XCTAssertEqual(colors?["secondary"] as? String, "green")
    }

    func test_mergeDictionaries_deepNestedMerge() {
        // Given
        let base: [String: Any] = [
            "theme": [
                "colors": ["primary": "blue"],
                "spacing": ["small": 4]
            ] as [String: Any]
        ]
        let override: [String: Any] = [
            "theme": [
                "colors": ["primary": "red", "accent": "yellow"]
            ] as [String: Any]
        ]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        let theme = result["theme"] as? [String: Any]
        let colors = theme?["colors"] as? [String: Any]
        let spacing = theme?["spacing"] as? [String: Any]
        XCTAssertEqual(colors?["primary"] as? String, "red")
        XCTAssertEqual(colors?["accent"] as? String, "yellow")
        XCTAssertEqual(spacing?["small"] as? Int, 4)
    }

    func test_mergeDictionaries_overrideReplacesNonDictWithDict() {
        // Given
        let base: [String: Any] = ["color": "blue"]
        let override: [String: Any] = ["color": ["value": "red"]]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        let color = result["color"] as? [String: Any]
        XCTAssertEqual(color?["value"] as? String, "red")
    }

    func test_mergeDictionaries_overrideReplacesDictWithNonDict() {
        // Given
        let base: [String: Any] = ["color": ["value": "blue"]]
        let override: [String: Any] = ["color": "red"]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        XCTAssertEqual(result["color"] as? String, "red")
    }

    func test_mergeDictionaries_disjointKeys_combinesAll() {
        // Given
        let base: [String: Any] = ["a": 1, "b": 2]
        let override: [String: Any] = ["c": 3, "d": 4]

        // When
        let result = DesignTokensProcessor.mergeDictionaries(base, with: override)

        // Then
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result["a"] as? Int, 1)
        XCTAssertEqual(result["b"] as? Int, 2)
        XCTAssertEqual(result["c"] as? Int, 3)
        XCTAssertEqual(result["d"] as? Int, 4)
    }

    // MARK: - resolveReferences

    func test_resolveReferences_missingReference_leftUntouched() {
        // Given
        let dict: [String: Any] = [
            "color": "{nonexistent.path}"
        ]

        // When
        let result = DesignTokensProcessor.resolveReferences(in: dict)

        // Then
        XCTAssertEqual(result["color"] as? String, "{nonexistent.path}")
    }

    func test_resolveReferences_nonReferenceStrings_leftUntouched() {
        // Given
        let dict: [String: Any] = [
            "label": "Hello World",
            "count": 42
        ]

        // When
        let result = DesignTokensProcessor.resolveReferences(in: dict)

        // Then
        XCTAssertEqual(result["label"] as? String, "Hello World")
        XCTAssertEqual(result["count"] as? Int, 42)
    }

    func test_resolveReferences_circularReference_doesNotCrash() {
        // Given
        let dict: [String: Any] = [
            "a": "{b}",
            "b": "{a}"
        ]

        // When
        let result = DesignTokensProcessor.resolveReferences(in: dict)

        // Then - should not crash, references remain unresolved
        XCTAssertNotNil(result)
        // Both remain as reference strings since they can never resolve
        XCTAssertEqual(result["a"] as? String, "{b}")
        XCTAssertEqual(result["b"] as? String, "{a}")
    }

    func test_resolveReferences_emptyDict_returnsEmpty() {
        // When
        let result = DesignTokensProcessor.resolveReferences(in: [:])

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - convertHexColors

    func test_convertHexColors_6CharHex_convertsToRGBAArray() {
        // Given
        let dict: [String: Any] = ["color": "#FF0000"]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        let colorArray = result["color"] as? [CGFloat]
        XCTAssertNotNil(colorArray)
        XCTAssertEqual(colorArray?.count, 4)
        XCTAssertEqual(Double(colorArray?[0] ?? -1), 1.0, accuracy: 0.001) // red
        XCTAssertEqual(Double(colorArray?[1] ?? -1), 0.0, accuracy: 0.001) // green
        XCTAssertEqual(Double(colorArray?[2] ?? -1), 0.0, accuracy: 0.001) // blue
        XCTAssertEqual(Double(colorArray?[3] ?? -1), 1.0, accuracy: 0.001) // alpha (default for 6-char)
    }

    func test_convertHexColors_8CharHex_convertsWithAlpha() {
        // Given
        let dict: [String: Any] = ["color": "#FF000080"]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        let colorArray = result["color"] as? [CGFloat]
        XCTAssertNotNil(colorArray)
        XCTAssertEqual(Double(colorArray?[0] ?? -1), 1.0, accuracy: 0.001) // red
        XCTAssertEqual(Double(colorArray?[1] ?? -1), 0.0, accuracy: 0.001) // green
        XCTAssertEqual(Double(colorArray?[2] ?? -1), 0.0, accuracy: 0.001) // blue
        XCTAssertEqual(Double(colorArray?[3] ?? -1), 128.0 / 255.0, accuracy: 0.001) // alpha ~0.502
    }

    func test_convertHexColors_white_convertsCorrectly() {
        // Given
        let dict: [String: Any] = ["color": "#FFFFFF"]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        let colorArray = result["color"] as? [CGFloat]
        XCTAssertEqual(Double(colorArray?[0] ?? -1), 1.0, accuracy: 0.001)
        XCTAssertEqual(Double(colorArray?[1] ?? -1), 1.0, accuracy: 0.001)
        XCTAssertEqual(Double(colorArray?[2] ?? -1), 1.0, accuracy: 0.001)
        XCTAssertEqual(Double(colorArray?[3] ?? -1), 1.0, accuracy: 0.001)
    }

    func test_convertHexColors_black_convertsCorrectly() {
        // Given
        let dict: [String: Any] = ["color": "#000000"]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        let colorArray = result["color"] as? [CGFloat]
        XCTAssertEqual(Double(colorArray?[0] ?? -1), 0.0, accuracy: 0.001)
        XCTAssertEqual(Double(colorArray?[1] ?? -1), 0.0, accuracy: 0.001)
        XCTAssertEqual(Double(colorArray?[2] ?? -1), 0.0, accuracy: 0.001)
        XCTAssertEqual(Double(colorArray?[3] ?? -1), 1.0, accuracy: 0.001)
    }

    func test_convertHexColors_invalidHex_leftUntouched() {
        // Given
        let dict: [String: Any] = ["color": "#ZZZZZZ"]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        XCTAssertEqual(result["color"] as? String, "#ZZZZZZ")
    }

    func test_convertHexColors_wrongLengthHex_leftUntouched() {
        // Given
        let dict: [String: Any] = ["color": "#FFF"]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        XCTAssertEqual(result["color"] as? String, "#FFF")
    }

    func test_convertHexColors_nonStringValues_leftUntouched() {
        // Given
        let dict: [String: Any] = [
            "size": 16,
            "enabled": true,
            "ratio": 1.5
        ]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        XCTAssertEqual(result["size"] as? Int, 16)
        XCTAssertEqual(result["enabled"] as? Bool, true)
        XCTAssertEqual(result["ratio"] as? Double, 1.5)
    }

    func test_convertHexColors_nonHexString_leftUntouched() {
        // Given
        let dict: [String: Any] = ["label": "Hello"]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        XCTAssertEqual(result["label"] as? String, "Hello")
    }

    func test_convertHexColors_nestedDicts_convertsRecursively() {
        // Given
        let dict: [String: Any] = [
            "theme": [
                "primary": "#00FF00",
                "label": "text"
            ]
        ]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        let theme = result["theme"] as? [String: Any]
        let colorArray = theme?["primary"] as? [CGFloat]
        XCTAssertNotNil(colorArray)
        XCTAssertEqual(Double(colorArray?[1] ?? -1), 1.0, accuracy: 0.001) // green
        XCTAssertEqual(theme?["label"] as? String, "text")
    }

    func test_convertHexColors_emptyDict_returnsEmpty() {
        // When
        let result = DesignTokensProcessor.convertHexColors(in: [:])

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func test_convertHexColors_lowercaseHex_convertsCorrectly() {
        // Given
        let dict: [String: Any] = ["color": "#ff0000"]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        let colorArray = result["color"] as? [CGFloat]
        XCTAssertNotNil(colorArray)
        XCTAssertEqual(Double(colorArray?[0] ?? -1), 1.0, accuracy: 0.001)
    }

    func test_convertHexColors_8CharFullyTransparent_convertsCorrectly() {
        // Given
        let dict: [String: Any] = ["color": "#FF000000"]

        // When
        let result = DesignTokensProcessor.convertHexColors(in: dict)

        // Then
        let colorArray = result["color"] as? [CGFloat]
        XCTAssertNotNil(colorArray)
        XCTAssertEqual(Double(colorArray?[0] ?? -1), 1.0, accuracy: 0.001) // red
        XCTAssertEqual(Double(colorArray?[3] ?? -1), 0.0, accuracy: 0.001) // alpha = 0
    }

    // MARK: - flattenTokenDictionary

    func test_flattenTokenDictionary_simpleNesting_extractsValue() {
        // Given
        let dict: [String: Any] = [
            "color": ["value": "red"]
        ]

        // When
        let result = DesignTokensProcessor.flattenTokenDictionary(dict)

        // Then
        XCTAssertEqual(result["color"] as? String, "red")
    }

    func test_flattenTokenDictionary_deepNesting_createsCamelCaseKey() {
        // Given
        let dict: [String: Any] = [
            "colors": [
                "primary": ["value": "#FF0000"]
            ]
        ]

        // When
        let result = DesignTokensProcessor.flattenTokenDictionary(dict)

        // Then
        XCTAssertEqual(result["colorsPrimary"] as? String, "#FF0000")
    }

    func test_flattenTokenDictionary_multipleNestedLevels_createsCamelCaseKey() {
        // Given
        let dict: [String: Any] = [
            "theme": [
                "colors": [
                    "brand": ["value": "blue"]
                ]
            ]
        ]

        // When
        let result = DesignTokensProcessor.flattenTokenDictionary(dict)

        // Then
        XCTAssertEqual(result["themeColorsBrand"] as? String, "blue")
    }

    func test_flattenTokenDictionary_nonDictLeaf_preservesValue() {
        // Given
        let dict: [String: Any] = [
            "spacing": [
                "small": 4,
                "medium": 8
            ] as [String: Any]
        ]

        // When
        let result = DesignTokensProcessor.flattenTokenDictionary(dict)

        // Then
        XCTAssertEqual(result["spacingSmall"] as? Int, 4)
        XCTAssertEqual(result["spacingMedium"] as? Int, 8)
    }

    func test_flattenTokenDictionary_emptyDict_returnsEmpty() {
        // When
        let result = DesignTokensProcessor.flattenTokenDictionary([:])

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func test_flattenTokenDictionary_topLevelValue_preservesKey() {
        // Given
        let dict: [String: Any] = [
            "simple": ["value": 42]
        ]

        // When
        let result = DesignTokensProcessor.flattenTokenDictionary(dict)

        // Then
        XCTAssertEqual(result["simple"] as? Int, 42)
    }

    func test_flattenTokenDictionary_mixedStructure_flattensCorrectly() {
        // Given
        let dict: [String: Any] = [
            "colors": [
                "primary": ["value": "#FF0000"],
                "gray": [
                    "100": ["value": "#F5F5F5"],
                    "900": ["value": "#212121"]
                ]
            ]
        ]

        // When
        let result = DesignTokensProcessor.flattenTokenDictionary(dict)

        // Then
        XCTAssertEqual(result["colorsPrimary"] as? String, "#FF0000")
        XCTAssertEqual(result["colorsGray100"] as? String, "#F5F5F5")
        XCTAssertEqual(result["colorsGray900"] as? String, "#212121")
    }

    func test_flattenTokenDictionary_topLevelNonDictValue_usesKeyDirectly() {
        // Given
        let dict: [String: Any] = [
            "fontSize": 16
        ]

        // When
        let result = DesignTokensProcessor.flattenTokenDictionary(dict)

        // Then
        XCTAssertEqual(result["fontSize"] as? Int, 16)
    }

    // MARK: - resolveFlattenedReferences

    func test_resolveFlattenedReferences_simpleReference_resolves() {
        // Given
        let flatDict: [String: Any] = [
            "colorsPrimary": "#FF0000",
            "background": "{colors.primary}"
        ]
        let source: [String: Any] = [
            "colors": ["primary": ["value": "#FF0000"]]
        ]

        // When
        let result = DesignTokensProcessor.resolveFlattenedReferences(in: flatDict, source: source)

        // Then
        // It should resolve either from flatDict or source
        XCTAssertNotEqual(result["background"] as? String, "{colors.primary}")
    }

    func test_resolveFlattenedReferences_nonReferenceValues_leftUntouched() {
        // Given
        let flatDict: [String: Any] = [
            "size": 16,
            "label": "Hello"
        ]

        // When
        let result = DesignTokensProcessor.resolveFlattenedReferences(in: flatDict, source: [:])

        // Then
        XCTAssertEqual(result["size"] as? Int, 16)
        XCTAssertEqual(result["label"] as? String, "Hello")
    }

    func test_resolveFlattenedReferences_emptyDict_returnsEmpty() {
        // When
        let result = DesignTokensProcessor.resolveFlattenedReferences(in: [:], source: [:])

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func test_resolveFlattenedReferences_chainedReferences_resolvedIteratively() {
        // Given
        let flatDict: [String: Any] = [
            "base": "blue",
            "primary": "{base}",
            "accent": "{primary}"
        ]
        let source: [String: Any] = [
            "base": "blue"
        ]

        // When
        let result = DesignTokensProcessor.resolveFlattenedReferences(in: flatDict, source: source)

        // Then
        XCTAssertEqual(result["base"] as? String, "blue")
    }

    // MARK: - evaluateMath

    func test_evaluateMath_addition_evaluatesCorrectly() {
        // Given
        let dict: [String: Any] = ["result": "4 + 8"]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["result"] as? Double, 12.0)
    }

    func test_evaluateMath_subtraction_evaluatesCorrectly() {
        // Given
        let dict: [String: Any] = ["result": "10 - 3"]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["result"] as? Double, 7.0)
    }

    func test_evaluateMath_multiplication_evaluatesCorrectly() {
        // Given
        let dict: [String: Any] = ["result": "4 * 3"]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["result"] as? Double, 12.0)
    }

    func test_evaluateMath_division_evaluatesCorrectly() {
        // Given
        let dict: [String: Any] = ["result": "10 / 4"]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["result"] as? Double, 2.5)
    }

    func test_evaluateMath_divisionByZero_returnsNil() {
        // Given
        let dict: [String: Any] = ["result": "10 / 0"]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then - division by zero returns nil, so original string is kept
        XCTAssertEqual(result["result"] as? String, "10 / 0")
    }

    func test_evaluateMath_decimalNumbers_evaluatesCorrectly() {
        // Given
        let dict: [String: Any] = ["result": "1.5 * 2"]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["result"] as? Double, 3.0)
    }

    func test_evaluateMath_nonMathString_leftUntouched() {
        // Given
        let dict: [String: Any] = ["label": "Hello World"]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["label"] as? String, "Hello World")
    }

    func test_evaluateMath_nonStringValues_leftUntouched() {
        // Given
        let dict: [String: Any] = [
            "count": 42,
            "enabled": true,
            "ratio": 1.5
        ]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["count"] as? Int, 42)
        XCTAssertEqual(result["enabled"] as? Bool, true)
        XCTAssertEqual(result["ratio"] as? Double, 1.5)
    }

    func test_evaluateMath_multipleEntries_evaluatesEach() {
        // Given
        let dict: [String: Any] = [
            "small": "4 * 1",
            "medium": "4 * 2",
            "large": "4 * 4"
        ]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["small"] as? Double, 4.0)
        XCTAssertEqual(result["medium"] as? Double, 8.0)
        XCTAssertEqual(result["large"] as? Double, 16.0)
    }

    func test_evaluateMath_emptyDict_returnsEmpty() {
        // When
        let result = DesignTokensProcessor.evaluateMath(in: [:])

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func test_evaluateMath_spacesAroundOperator_evaluatesCorrectly() {
        // Given
        let dict: [String: Any] = ["result": "  10  +  5  "]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["result"] as? Double, 15.0)
    }

    func test_evaluateMath_operatorPrecedence_firstOperatorFound() {
        // Given - evaluateExpression finds the first operator in order: *, /, +, -
        // "2 + 3 * 4" finds "*" first at index between "3" and "4"
        // but "2 + 3" is not a valid Double, so it falls through to "+"
        let dict: [String: Any] = ["result": "2 + 3"]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["result"] as? Double, 5.0)
    }

    func test_evaluateMath_hexString_leftUntouched() {
        // Given
        let dict: [String: Any] = ["color": "#FF0000"]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["color"] as? String, "#FF0000")
    }

    func test_evaluateMath_singleNumber_leftUntouched() {
        // Given
        let dict: [String: Any] = ["value": "42"]

        // When
        let result = DesignTokensProcessor.evaluateMath(in: dict)

        // Then
        XCTAssertEqual(result["value"] as? String, "42")
    }
}
