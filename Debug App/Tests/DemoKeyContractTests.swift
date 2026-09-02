//
//  DemoKeyContractTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import Debug_App
import XCTest

/// Pins the deep link's `demo` values. They are shared byte-for-byte with Primer Studio (Android) and
/// the E2E page objects, so a change here is a cross-repo contract change, not a refactor.
final class DemoKeyContractTests: XCTestCase {

    private let expectedKeys = [
        "default_checkout", "inline_checkout", "inline_card_form", "card_form_sheet", "custom_card_form",
        "prefill_cardholder_name", "before_payment_gate", "payment_method_list_only", "custom_payment_methods",
        "custom_grid_payment_methods", "radio_selection", "vault_management", "vaulted_payment_methods",
        "vault_mode_inline", "dynamic_vault", "merchant_navigation", "custom_result_screens", "custom_navigation",
        "custom_theme", "red_theme", "green_theme", "purple_theme", "no_radius_theme", "small_sizes_theme",
        "large_sizes_theme", "light_typography_theme", "bold_typography_theme", "large_typography_theme",
        "custom_font_theme", "refresh_client_session"
    ]

    func testKeys_MatchTheCrossPlatformContract() {
        XCTAssertEqual(DemoKey.allCases.map(\.rawValue), expectedKeys)
    }

    func testKeys_AreLowercaseSnakeCase() throws {
        let shape = try NSRegularExpression(pattern: "^[a-z0-9]+(_[a-z0-9]+)*$")
        for key in DemoKey.allCases {
            let raw = key.rawValue
            let range = NSRange(raw.startIndex..., in: raw)
            XCTAssertEqual(shape.numberOfMatches(in: raw, range: range), 1, "\(raw) is not lowercase snake_case")
        }
    }

    func testKeys_AreUnique() {
        XCTAssertEqual(Set(DemoKey.allCases.map(\.rawValue)).count, DemoKey.allCases.count)
    }
}
