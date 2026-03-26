//
//  AppearanceModeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class AppearanceModeTests: XCTestCase {

    private enum TestableAppearanceMode {
        static func applyAppearanceMode(_ mode: PrimerAppearanceMode, to controller: UIViewController) {
            switch mode {
            case .system:
                controller.overrideUserInterfaceStyle = .unspecified
            case .light:
                controller.overrideUserInterfaceStyle = .light
            case .dark:
                controller.overrideUserInterfaceStyle = .dark
            }
        }
    }

    // MARK: - Appearance Mode Application

    func test_systemAppearanceMode_appliesUnspecifiedStyle() {
        // Given
        let viewController = UIViewController()

        // When
        TestableAppearanceMode.applyAppearanceMode(.system, to: viewController)

        // Then
        XCTAssertEqual(viewController.overrideUserInterfaceStyle, .unspecified)
    }

    func test_lightAppearanceMode_appliesLightStyle() {
        // Given
        let viewController = UIViewController()

        // When
        TestableAppearanceMode.applyAppearanceMode(.light, to: viewController)

        // Then
        XCTAssertEqual(viewController.overrideUserInterfaceStyle, .light)
    }

    func test_darkAppearanceMode_appliesDarkStyle() {
        // Given
        let viewController = UIViewController()

        // When
        TestableAppearanceMode.applyAppearanceMode(.dark, to: viewController)

        // Then
        XCTAssertEqual(viewController.overrideUserInterfaceStyle, .dark)
    }

    func test_appearanceMode_overridesPreviousStyle() {
        // Given
        let viewController = UIViewController()
        viewController.overrideUserInterfaceStyle = .dark

        // When
        TestableAppearanceMode.applyAppearanceMode(.light, to: viewController)

        // Then
        XCTAssertEqual(viewController.overrideUserInterfaceStyle, .light)
    }

    func test_appearanceMode_canBeRevertedToSystem() {
        // Given
        let viewController = UIViewController()
        viewController.overrideUserInterfaceStyle = .light

        // When
        TestableAppearanceMode.applyAppearanceMode(.system, to: viewController)

        // Then
        XCTAssertEqual(viewController.overrideUserInterfaceStyle, .unspecified)
    }

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

    // MARK: - All Cases

    func test_allAppearanceModeCases_applyCorrectly() {
        // Given
        let allCases: [(PrimerAppearanceMode, UIUserInterfaceStyle)] = [
            (.system, .unspecified),
            (.light, .light),
            (.dark, .dark)
        ]

        // When / Then
        for (mode, expectedStyle) in allCases {
            let viewController = UIViewController()
            TestableAppearanceMode.applyAppearanceMode(mode, to: viewController)
            XCTAssertEqual(viewController.overrideUserInterfaceStyle, expectedStyle)
        }
    }

    // MARK: - View Hierarchy

    func test_appearanceMode_appliesToParentOnly() {
        // Given
        let parentVC = UIViewController()
        let childVC = UIViewController()
        parentVC.addChild(childVC)
        parentVC.view.addSubview(childVC.view)
        childVC.didMove(toParent: parentVC)

        // When
        TestableAppearanceMode.applyAppearanceMode(.dark, to: parentVC)

        // Then
        XCTAssertEqual(parentVC.overrideUserInterfaceStyle, .dark)
        XCTAssertEqual(childVC.overrideUserInterfaceStyle, .unspecified)
    }

    func test_appearanceMode_independentOnChildViewController() {
        // Given
        let parentVC = UIViewController()
        let childVC = UIViewController()
        parentVC.addChild(childVC)

        // When
        TestableAppearanceMode.applyAppearanceMode(.light, to: parentVC)
        TestableAppearanceMode.applyAppearanceMode(.dark, to: childVC)

        // Then
        XCTAssertEqual(parentVC.overrideUserInterfaceStyle, .light)
        XCTAssertEqual(childVC.overrideUserInterfaceStyle, .dark)
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

    // MARK: - Integration with PrimerSettings

    func test_appearanceModeFromSettings_appliedToViewController() {
        // Given
        let settings = PrimerSettings(uiOptions: PrimerUIOptions(appearanceMode: .dark))
        let viewController = UIViewController()

        // When
        TestableAppearanceMode.applyAppearanceMode(settings.uiOptions.appearanceMode, to: viewController)

        // Then
        XCTAssertEqual(viewController.overrideUserInterfaceStyle, .dark)
    }

    func test_multipleViewControllers_withDifferentSettings() {
        // Given
        let lightSettings = PrimerSettings(uiOptions: PrimerUIOptions(appearanceMode: .light))
        let darkSettings = PrimerSettings(uiOptions: PrimerUIOptions(appearanceMode: .dark))
        let vc1 = UIViewController()
        let vc2 = UIViewController()

        // When
        TestableAppearanceMode.applyAppearanceMode(lightSettings.uiOptions.appearanceMode, to: vc1)
        TestableAppearanceMode.applyAppearanceMode(darkSettings.uiOptions.appearanceMode, to: vc2)

        // Then
        XCTAssertEqual(vc1.overrideUserInterfaceStyle, .light)
        XCTAssertEqual(vc2.overrideUserInterfaceStyle, .dark)
    }
}
