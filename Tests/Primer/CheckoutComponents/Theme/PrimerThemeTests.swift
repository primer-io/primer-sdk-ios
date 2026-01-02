//
//  PrimerThemeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for PrimerTheme class and its lazy properties.
final class PrimerThemeClassTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_withDefaultData_createsTheme() {
        // When
        let theme = PrimerTheme()

        // Then
        XCTAssertNotNil(theme)
    }

    func test_init_withCustomData_createsTheme() {
        // Given
        let data = PrimerThemeData()

        // When
        let theme = PrimerTheme(with: data)

        // Then
        XCTAssertNotNil(theme)
    }

    // MARK: - Colors Tests

    func test_colors_lazyInit_returnsColorSwatch() {
        // Given
        let theme = PrimerTheme()

        // When
        let colors = theme.colors

        // Then
        XCTAssertNotNil(colors)
    }

    func test_colors_accessedMultipleTimes_returnsSameInstance() {
        // Given
        let theme = PrimerTheme()

        // When
        let colors1 = theme.colors
        let colors2 = theme.colors

        // Then - verify lazy var is cached (same value properties)
        XCTAssertEqual(colors1.primary, colors2.primary)
        XCTAssertEqual(colors1.error, colors2.error)
    }

    // MARK: - BlurView Tests

    func test_blurView_lazyInit_returnsViewTheme() {
        // Given
        let theme = PrimerTheme()

        // When
        let blurView = theme.blurView

        // Then
        XCTAssertNotNil(blurView)
    }

    // MARK: - View Tests

    func test_view_lazyInit_returnsViewTheme() {
        // Given
        let theme = PrimerTheme()

        // When
        let view = theme.view

        // Then
        XCTAssertNotNil(view)
    }

    // MARK: - Text Tests

    func test_text_lazyInit_returnsTextStyle() {
        // Given
        let theme = PrimerTheme()

        // When
        let text = theme.text

        // Then
        XCTAssertNotNil(text)
    }

    func test_text_hasAllSubStyles() {
        // Given
        let theme = PrimerTheme()

        // When
        let text = theme.text

        // Then
        XCTAssertNotNil(text.body)
        XCTAssertNotNil(text.title)
        XCTAssertNotNil(text.subtitle)
        XCTAssertNotNil(text.amountLabel)
        XCTAssertNotNil(text.system)
        XCTAssertNotNil(text.error)
    }

    // MARK: - PaymentMethodButton Tests

    func test_paymentMethodButton_lazyInit_returnsButtonTheme() {
        // Given
        let theme = PrimerTheme()

        // When
        let buttonTheme = theme.paymentMethodButton

        // Then
        XCTAssertNotNil(buttonTheme)
    }

    // MARK: - MainButton Tests

    func test_mainButton_lazyInit_returnsButtonTheme() {
        // Given
        let theme = PrimerTheme()

        // When
        let buttonTheme = theme.mainButton

        // Then
        XCTAssertNotNil(buttonTheme)
    }

    // MARK: - Input Tests

    func test_input_lazyInit_returnsInputTheme() {
        // Given
        let theme = PrimerTheme()

        // When
        let inputTheme = theme.input

        // Then
        XCTAssertNotNil(inputTheme)
    }

    // MARK: - Equatable Tests

    func test_equality_sameInstance_returnsTrue() {
        // Given
        let theme = PrimerTheme()

        // When/Then
        XCTAssertEqual(theme, theme)
    }

    func test_equality_differentInstances_returnsFalse() {
        // Given
        let theme1 = PrimerTheme()
        let theme2 = PrimerTheme()

        // When/Then - identity comparison means different instances are not equal
        XCTAssertNotEqual(theme1, theme2)
    }

    func test_equality_sameInstanceViaReference_returnsTrue() {
        // Given
        let theme1 = PrimerTheme()
        let theme2 = theme1

        // When/Then - same instance should be equal
        XCTAssertEqual(theme1, theme2)
    }

    // MARK: - Full Theme Configuration Tests

    func test_fullThemeAccess_allPropertiesAccessible() {
        // Given
        let theme = PrimerTheme()

        // When - access all properties
        let colors = theme.colors
        let blurView = theme.blurView
        let view = theme.view
        let text = theme.text
        let paymentMethodButton = theme.paymentMethodButton
        let mainButton = theme.mainButton
        let input = theme.input

        // Then - all should be accessible
        XCTAssertNotNil(colors)
        XCTAssertNotNil(blurView)
        XCTAssertNotNil(view)
        XCTAssertNotNil(text)
        XCTAssertNotNil(paymentMethodButton)
        XCTAssertNotNil(mainButton)
        XCTAssertNotNil(input)
    }

    // MARK: - PrimerThemeProtocol Conformance Tests

    func test_conformsToPrimerThemeProtocol() {
        // Given
        let theme = PrimerTheme()

        // Then - verify protocol conformance
        let protocolConformingTheme: PrimerThemeProtocol = theme
        XCTAssertNotNil(protocolConformingTheme.colors)
        XCTAssertNotNil(protocolConformingTheme.blurView)
        XCTAssertNotNil(protocolConformingTheme.view)
        XCTAssertNotNil(protocolConformingTheme.text)
        XCTAssertNotNil(protocolConformingTheme.paymentMethodButton)
        XCTAssertNotNil(protocolConformingTheme.mainButton)
        XCTAssertNotNil(protocolConformingTheme.input)
    }
}
