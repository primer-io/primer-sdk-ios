//
//  PrimerFieldRepainterTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
final class PrimerFieldRepainterTests: XCTestCase {
    private func makeField(tokens: DesignTokens?) -> UITextField {
        let field = UITextField()
        field.repaintPrimerColors(placeholder: "Card number", tokens: tokens)
        return field
    }

    // MARK: - What a repaint writes

    func test_repaint_takesTextAndPlaceholderColoursFromTheGivenTokens() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let dark = try DesignTokensManager.makeTokens(for: .dark)
        let field = makeField(tokens: light)

        field.repaintPrimerColors(placeholder: "Card number", tokens: dark)

        XCTAssertEqual(field.textColor, UIColor(CheckoutColors.inputText(tokens: dark)))
        let placeholderColour = field.attributedPlaceholder?
            .attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertEqual(placeholderColour, UIColor(CheckoutColors.textPlaceholder(tokens: dark)))
    }

    /// The two earlier attempts at this fix rewrote these as well, and lost the shopper's input.
    func test_repaint_leavesText_font_borderAndAccessoryAlone() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let dark = try DesignTokensManager.makeTokens(for: .dark)
        let field = makeField(tokens: light)
        field.text = "4242 4242"
        field.font = UIFont.systemFont(ofSize: 21)
        field.borderStyle = .roundedRect
        let accessory = UIToolbar()
        field.inputAccessoryView = accessory

        field.repaintPrimerColors(placeholder: "Card number", tokens: dark)

        XCTAssertEqual(field.text, "4242 4242")
        XCTAssertEqual(field.font, UIFont.systemFont(ofSize: 21))
        XCTAssertEqual(field.borderStyle, .roundedRect)
        XCTAssertTrue(field.inputAccessoryView === accessory)
    }

    func test_repaint_onASecureField_keepsTheRealValue() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let dark = try DesignTokensManager.makeTokens(for: .dark)
        let field = SecureTextField()
        field.repaintPrimerColors(placeholder: "Card number", tokens: light)
        field.internalText = "4242424242424242"

        field.repaintPrimerColors(placeholder: "Card number", tokens: dark)

        XCTAssertEqual(field.internalText, "4242424242424242")
    }

    // MARK: - When a repaint fires

    func test_repaintIfNeeded_sameTokens_doesNothing() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let field = makeField(tokens: light)
        field.textColor = .magenta
        let repainter = PrimerFieldRepainter()
        repainter.markApplied(light)

        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: light)

        XCTAssertEqual(field.textColor, .magenta, "a keystroke must not trigger a repaint")
    }

    func test_repaintIfNeeded_newTokens_repaintsOnceAndThenStops() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let dark = try DesignTokensManager.makeTokens(for: .dark)
        let field = makeField(tokens: light)
        let repainter = PrimerFieldRepainter()
        repainter.markApplied(light)

        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: dark)
        XCTAssertEqual(field.textColor, UIColor(CheckoutColors.inputText(tokens: dark)))

        field.textColor = .magenta
        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: dark)
        XCTAssertEqual(field.textColor, .magenta, "the same token set must not repaint twice")
    }
}
