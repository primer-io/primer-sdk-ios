//
//  UIScreenExtensionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class UIScreenExtensionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset settings to default before each test
        Primer.shared.configure(settings: PrimerSettings())
    }
    
    override func tearDown() {
        super.tearDown()
        // Reset settings after each test
        Primer.shared.configure(settings: PrimerSettings())
    }
    
    func testIsDarkModeEnabledWithSystemAppearance() {
        // Given: Settings with system appearance mode (default)
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(appearanceMode: .system)
        )
        Primer.shared.configure(settings: settings)
        
        // When: Checking isDarkModeEnabled
        let isDarkMode = UIScreen.isDarkModeEnabled
        
        // Then: It should match the system's trait collection
        let systemIsDarkMode = UIScreen.main.traitCollection.userInterfaceStyle == .dark
        XCTAssertEqual(isDarkMode, systemIsDarkMode)
    }
    
    func testIsDarkModeEnabledWithLightAppearanceOverride() {
        // Given: Settings forcing light mode
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(appearanceMode: .light)
        )
        Primer.shared.configure(settings: settings)
        
        // When: Checking isDarkModeEnabled
        let isDarkMode = UIScreen.isDarkModeEnabled
        
        // Then: It should always return false
        XCTAssertFalse(isDarkMode)
    }
    
    func testIsDarkModeEnabledWithDarkAppearanceOverride() {
        // Given: Settings forcing dark mode
        let settings = PrimerSettings(
            uiOptions: PrimerUIOptions(appearanceMode: .dark)
        )
        Primer.shared.configure(settings: settings)
        
        // When: Checking isDarkModeEnabled
        let isDarkMode = UIScreen.isDarkModeEnabled
        
        // Then: It should always return true
        XCTAssertTrue(isDarkMode)
    }
    
    func testIsDarkModeEnabledWithNoUIOptions() {
        // Given: Settings with default UIOptions (system appearance)
        let settings = PrimerSettings()
        Primer.shared.configure(settings: settings)
        
        // When: Checking isDarkModeEnabled
        let isDarkMode = UIScreen.isDarkModeEnabled
        
        // Then: It should match the system's trait collection
        let systemIsDarkMode = UIScreen.main.traitCollection.userInterfaceStyle == .dark
        XCTAssertEqual(isDarkMode, systemIsDarkMode)
    }
}