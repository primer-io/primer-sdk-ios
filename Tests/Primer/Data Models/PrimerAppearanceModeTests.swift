//
//  PrimerAppearanceModeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PrimerAppearanceModeTests: XCTestCase {
    
    // MARK: - PrimerAppearanceMode Tests
    
    func testAppearanceModeRawValues() {
        XCTAssertEqual(PrimerAppearanceMode.system.rawValue, "SYSTEM")
        XCTAssertEqual(PrimerAppearanceMode.light.rawValue, "LIGHT")
        XCTAssertEqual(PrimerAppearanceMode.dark.rawValue, "DARK")
    }
    
    func testAppearanceModeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding and decoding each mode
        let modes: [PrimerAppearanceMode] = [.system, .light, .dark]
        
        for mode in modes {
            let data = try encoder.encode(mode)
            let decodedMode = try decoder.decode(PrimerAppearanceMode.self, from: data)
            XCTAssertEqual(mode, decodedMode)
        }
    }
    
    // MARK: - PrimerUIOptions with AppearanceMode Tests
    
    func testPrimerUIOptionsDefaultAppearanceMode() {
        let uiOptions = PrimerUIOptions()
        XCTAssertEqual(uiOptions.appearanceMode, .system)
    }
    
    func testPrimerUIOptionsWithCustomAppearanceMode() {
        let lightOptions = PrimerUIOptions(appearanceMode: .light)
        XCTAssertEqual(lightOptions.appearanceMode, .light)
        
        let darkOptions = PrimerUIOptions(appearanceMode: .dark)
        XCTAssertEqual(darkOptions.appearanceMode, .dark)
        
        let systemOptions = PrimerUIOptions(appearanceMode: .system)
        XCTAssertEqual(systemOptions.appearanceMode, .system)
    }
    
    func testPrimerUIOptionsCodableWithAppearanceMode() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let originalOptions = PrimerUIOptions(
            isInitScreenEnabled: false,
            isSuccessScreenEnabled: true,
            isErrorScreenEnabled: false,
            appearanceMode: .light
        )
        
        let data = try encoder.encode(originalOptions)
        let decodedOptions = try decoder.decode(PrimerUIOptions.self, from: data)
        
        XCTAssertEqual(decodedOptions.isInitScreenEnabled, originalOptions.isInitScreenEnabled)
        XCTAssertEqual(decodedOptions.isSuccessScreenEnabled, originalOptions.isSuccessScreenEnabled)
        XCTAssertEqual(decodedOptions.isErrorScreenEnabled, originalOptions.isErrorScreenEnabled)
        XCTAssertEqual(decodedOptions.appearanceMode, originalOptions.appearanceMode)
    }
    
    func testPrimerUIOptionsDecodingWithoutAppearanceMode() throws {
        // Test that decoding old JSON without appearanceMode defaults to .system
        let jsonWithoutAppearanceMode = """
        {
            "isInitScreenEnabled": true,
            "isSuccessScreenEnabled": false,
            "isErrorScreenEnabled": true,
            "dismissalMechanism": []
        }
        """
        
        let decoder = JSONDecoder()
        let data = jsonWithoutAppearanceMode.data(using: .utf8)!
        let options = try decoder.decode(PrimerUIOptions.self, from: data)
        
        XCTAssertEqual(options.appearanceMode, .system)
    }
}