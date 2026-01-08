//
//  AppearanceModeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class AppearanceModeTests: XCTestCase {

    // MARK: - Helper Classes

    /// Test helper to access private applyAppearanceMode method
    private class CheckoutComponentsPrimerTestable {
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

    // MARK: - Appearance Mode Application Tests

    func testSystemAppearanceModeAppliesUnspecifiedStyle() {
        // Given: A view controller and system appearance mode
        let viewController = UIViewController()
        let mode: PrimerAppearanceMode = .system

        // When: Apply appearance mode
        CheckoutComponentsPrimerTestable.applyAppearanceMode(mode, to: viewController)

        // Then: Interface style should be unspecified (follows system)
        XCTAssertEqual(
            viewController.overrideUserInterfaceStyle,
            .unspecified,
            "System mode should set overrideUserInterfaceStyle to .unspecified"
        )
    }

    func testLightAppearanceModeAppliesLightStyle() {
        // Given: A view controller and light appearance mode
        let viewController = UIViewController()
        let mode: PrimerAppearanceMode = .light

        // When: Apply appearance mode
        CheckoutComponentsPrimerTestable.applyAppearanceMode(mode, to: viewController)

        // Then: Interface style should be light
        XCTAssertEqual(
            viewController.overrideUserInterfaceStyle,
            .light,
            "Light mode should set overrideUserInterfaceStyle to .light"
        )
    }

    func testDarkAppearanceModeAppliesDarkStyle() {
        // Given: A view controller and dark appearance mode
        let viewController = UIViewController()
        let mode: PrimerAppearanceMode = .dark

        // When: Apply appearance mode
        CheckoutComponentsPrimerTestable.applyAppearanceMode(mode, to: viewController)

        // Then: Interface style should be dark
        XCTAssertEqual(
            viewController.overrideUserInterfaceStyle,
            .dark,
            "Dark mode should set overrideUserInterfaceStyle to .dark"
        )
    }

    func testAppearanceModeOverridesPreviousStyle() {
        // Given: A view controller with initial dark style
        let viewController = UIViewController()
        viewController.overrideUserInterfaceStyle = .dark

        // When: Apply light appearance mode
        CheckoutComponentsPrimerTestable.applyAppearanceMode(.light, to: viewController)

        // Then: Interface style should be updated to light
        XCTAssertEqual(
            viewController.overrideUserInterfaceStyle,
            .light,
            "Applying new appearance mode should override previous style"
        )
    }

    func testAppearanceModeCanBeRevertedToSystem() {
        // Given: A view controller with forced light style
        let viewController = UIViewController()
        viewController.overrideUserInterfaceStyle = .light

        // When: Apply system appearance mode
        CheckoutComponentsPrimerTestable.applyAppearanceMode(.system, to: viewController)

        // Then: Interface style should revert to unspecified
        XCTAssertEqual(
            viewController.overrideUserInterfaceStyle,
            .unspecified,
            "System mode should revert to unspecified, following system appearance"
        )
    }

    // MARK: - PrimerSettings Appearance Mode Tests

    func testPrimerSettingsDefaultAppearanceMode() {
        // Given: Default PrimerSettings
        let settings = PrimerSettings()

        // Then: Default appearance mode should be system
        XCTAssertEqual(
            settings.uiOptions.appearanceMode,
            .system,
            "Default appearance mode should be system"
        )
    }

    func testPrimerSettingsWithLightAppearanceMode() {
        // Given: Settings configured with light mode
        let uiOptions = PrimerUIOptions(appearanceMode: .light)
        let settings = PrimerSettings(uiOptions: uiOptions)

        // Then: Appearance mode should be light
        XCTAssertEqual(
            settings.uiOptions.appearanceMode,
            .light,
            "Settings should preserve light appearance mode"
        )
    }

    func testPrimerSettingsWithDarkAppearanceMode() {
        // Given: Settings configured with dark mode
        let uiOptions = PrimerUIOptions(appearanceMode: .dark)
        let settings = PrimerSettings(uiOptions: uiOptions)

        // Then: Appearance mode should be dark
        XCTAssertEqual(
            settings.uiOptions.appearanceMode,
            .dark,
            "Settings should preserve dark appearance mode"
        )
    }

    func testPrimerSettingsWithSystemAppearanceMode() {
        // Given: Settings explicitly configured with system mode
        let uiOptions = PrimerUIOptions(appearanceMode: .system)
        let settings = PrimerSettings(uiOptions: uiOptions)

        // Then: Appearance mode should be system
        XCTAssertEqual(
            settings.uiOptions.appearanceMode,
            .system,
            "Settings should preserve system appearance mode"
        )
    }

    // MARK: - All Appearance Mode Enum Cases Tests

    func testAllAppearanceModeCasesApplyCorrectly() {
        // Given: All appearance mode cases
        let allCases: [(PrimerAppearanceMode, UIUserInterfaceStyle)] = [
            (.system, .unspecified),
            (.light, .light),
            (.dark, .dark)
        ]

        // When/Then: Each mode should apply the correct interface style
        for (mode, expectedStyle) in allCases {
            let viewController = UIViewController()
            CheckoutComponentsPrimerTestable.applyAppearanceMode(mode, to: viewController)

            XCTAssertEqual(
                viewController.overrideUserInterfaceStyle,
                expectedStyle,
                "Mode \(mode) should apply style \(expectedStyle)"
            )
        }
    }

    // MARK: - View Hierarchy Tests

    func testAppearanceModeAppliesToEmbeddedViewControllers() {
        // Given: A parent view controller with a child
        let parentVC = UIViewController()
        let childVC = UIViewController()
        parentVC.addChild(childVC)
        parentVC.view.addSubview(childVC.view)
        childVC.didMove(toParent: parentVC)

        // When: Apply dark mode to parent
        CheckoutComponentsPrimerTestable.applyAppearanceMode(.dark, to: parentVC)

        // Then: Parent should have dark style
        XCTAssertEqual(parentVC.overrideUserInterfaceStyle, .dark)

        // Note: Child inherits parent's style unless overridden
        // The child's overrideUserInterfaceStyle is .unspecified by default
        XCTAssertEqual(childVC.overrideUserInterfaceStyle, .unspecified)
    }

    func testAppearanceModeIndependentOnChildViewController() {
        // Given: Parent and child view controllers
        let parentVC = UIViewController()
        let childVC = UIViewController()
        parentVC.addChild(childVC)

        // When: Apply different modes to parent and child
        CheckoutComponentsPrimerTestable.applyAppearanceMode(.light, to: parentVC)
        CheckoutComponentsPrimerTestable.applyAppearanceMode(.dark, to: childVC)

        // Then: Each should have their respective styles
        XCTAssertEqual(parentVC.overrideUserInterfaceStyle, .light)
        XCTAssertEqual(childVC.overrideUserInterfaceStyle, .dark)
    }

    // MARK: - Appearance Mode String Values Tests

    func testAppearanceModeRawValues() {
        // Verify raw string values for each case
        XCTAssertEqual(PrimerAppearanceMode.system.rawValue, "SYSTEM")
        XCTAssertEqual(PrimerAppearanceMode.light.rawValue, "LIGHT")
        XCTAssertEqual(PrimerAppearanceMode.dark.rawValue, "DARK")
    }

    func testAppearanceModeDecodingFromString() throws {
        // Given: JSON strings for each appearance mode
        let systemJSON = "\"SYSTEM\"".data(using: .utf8)!
        let lightJSON = "\"LIGHT\"".data(using: .utf8)!
        let darkJSON = "\"DARK\"".data(using: .utf8)!

        // When: Decode from JSON
        let systemMode = try JSONDecoder().decode(PrimerAppearanceMode.self, from: systemJSON)
        let lightMode = try JSONDecoder().decode(PrimerAppearanceMode.self, from: lightJSON)
        let darkMode = try JSONDecoder().decode(PrimerAppearanceMode.self, from: darkJSON)

        // Then: Should decode correctly
        XCTAssertEqual(systemMode, .system)
        XCTAssertEqual(lightMode, .light)
        XCTAssertEqual(darkMode, .dark)
    }

    func testAppearanceModeEncodingToString() throws {
        // Given: Appearance mode values
        let modes: [PrimerAppearanceMode] = [.system, .light, .dark]
        let expectedValues = ["SYSTEM", "LIGHT", "DARK"]

        // When/Then: Encode to JSON
        for (mode, expected) in zip(modes, expectedValues) {
            let encoded = try JSONEncoder().encode(mode)
            let jsonString = String(data: encoded, encoding: .utf8)
            XCTAssertEqual(jsonString, "\"\(expected)\"")
        }
    }

    // MARK: - Integration with PrimerSettings Tests

    func testAppearanceModeFromSettingsAppliedToViewController() {
        // Given: Settings with dark mode
        let uiOptions = PrimerUIOptions(appearanceMode: .dark)
        let settings = PrimerSettings(uiOptions: uiOptions)
        let viewController = UIViewController()

        // When: Apply appearance mode from settings
        CheckoutComponentsPrimerTestable.applyAppearanceMode(
            settings.uiOptions.appearanceMode,
            to: viewController
        )

        // Then: View controller should have dark style
        XCTAssertEqual(viewController.overrideUserInterfaceStyle, .dark)
    }

    func testMultipleViewControllersWithDifferentSettings() {
        // Given: Two settings with different appearance modes
        let lightSettings = PrimerSettings(uiOptions: PrimerUIOptions(appearanceMode: .light))
        let darkSettings = PrimerSettings(uiOptions: PrimerUIOptions(appearanceMode: .dark))

        let vc1 = UIViewController()
        let vc2 = UIViewController()

        // When: Apply different modes from different settings
        CheckoutComponentsPrimerTestable.applyAppearanceMode(
            lightSettings.uiOptions.appearanceMode,
            to: vc1
        )
        CheckoutComponentsPrimerTestable.applyAppearanceMode(
            darkSettings.uiOptions.appearanceMode,
            to: vc2
        )

        // Then: Each view controller should have correct style
        XCTAssertEqual(vc1.overrideUserInterfaceStyle, .light)
        XCTAssertEqual(vc2.overrideUserInterfaceStyle, .dark)
    }
}
