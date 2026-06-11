//
//  AppearanceModeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class AppearanceModeTests: XCTestCase {

    // MARK: - PrimerSettings Appearance Mode

    func test_primerSettings_defaultAppearanceMode_isSystem() {
        // Given
        let settings = PrimerSettings()

        // Then
        XCTAssertEqual(settings.uiOptions.appearanceMode, .system)
    }

    func test_primerSettings_lightAppearanceMode_isPreserved() {
        // Given
        let settings = PrimerSettings(uiOptions: PrimerUIOptions(appearanceMode: .light))

        // Then
        XCTAssertEqual(settings.uiOptions.appearanceMode, .light)
    }

    func test_primerSettings_darkAppearanceMode_isPreserved() {
        // Given
        let settings = PrimerSettings(uiOptions: PrimerUIOptions(appearanceMode: .dark))

        // Then
        XCTAssertEqual(settings.uiOptions.appearanceMode, .dark)
    }

    func test_primerSettings_systemAppearanceMode_isPreserved() {
        // Given
        let settings = PrimerSettings(uiOptions: PrimerUIOptions(appearanceMode: .system))

        // Then
        XCTAssertEqual(settings.uiOptions.appearanceMode, .system)
    }

    // MARK: - Raw Values

    func test_appearanceMode_rawValues() {
        XCTAssertEqual(PrimerAppearanceMode.system.rawValue, "SYSTEM")
        XCTAssertEqual(PrimerAppearanceMode.light.rawValue, "LIGHT")
        XCTAssertEqual(PrimerAppearanceMode.dark.rawValue, "DARK")
    }

    func test_appearanceMode_decodingFromString() throws {
        // Given
        let systemJSON = "\"SYSTEM\"".data(using: .utf8)!
        let lightJSON = "\"LIGHT\"".data(using: .utf8)!
        let darkJSON = "\"DARK\"".data(using: .utf8)!

        // When
        let systemMode = try JSONDecoder().decode(PrimerAppearanceMode.self, from: systemJSON)
        let lightMode = try JSONDecoder().decode(PrimerAppearanceMode.self, from: lightJSON)
        let darkMode = try JSONDecoder().decode(PrimerAppearanceMode.self, from: darkJSON)

        // Then
        XCTAssertEqual(systemMode, .system)
        XCTAssertEqual(lightMode, .light)
        XCTAssertEqual(darkMode, .dark)
    }

    func test_appearanceMode_encodingToString() throws {
        // Given
        let modes: [PrimerAppearanceMode] = [.system, .light, .dark]
        let expectedValues = ["SYSTEM", "LIGHT", "DARK"]

        // When / Then
        for (mode, expected) in zip(modes, expectedValues) {
            let encoded = try JSONEncoder().encode(mode)
            let jsonString = String(data: encoded, encoding: .utf8)
            XCTAssertEqual(jsonString, "\"\(expected)\"")
        }
    }
}
