//
//  KlarnaHelpersTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerCore

final class KlarnaHelpersTests: XCTestCase {

    func test_isDarkAppearance_forcedModeWins_systemFollowsTheSystemAppearance() {
        let isSystemDarkAppearance = [false, true]
        let expected: [PrimerAppearanceMode: [Bool]] = [
            .light: [false, false],
            .dark: [true, true],
            .system: [false, true]
        ]

        for (mode, isDarkAppearance) in expected {
            XCTAssertEqual(isSystemDarkAppearance.map { mode.isDarkAppearance(orSystem: $0) }, isDarkAppearance, "\(mode)")
        }
    }
}
