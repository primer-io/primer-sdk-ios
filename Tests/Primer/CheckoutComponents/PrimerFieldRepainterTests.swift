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

    func test_configure_tintsANewFieldsCaretWithTheFocusedBorderColour() throws {
        let themed = try DesignTokensManager.makeTokens(for: .light)
        themed.primerColorBorderOutlinedFocus = Color(red: 1, green: 0, blue: 0)
        let field = UITextField()

        field.configurePrimerStyle(
            placeholder: "Card number",
            configuration: .numberPad,
            tokens: themed,
            doneButtonTarget: nil,
            doneButtonAction: #selector(UIResponder.resignFirstResponder)
        )

        XCTAssertEqual(field.tintColor, UIColor(CheckoutColors.borderFocus(tokens: themed)))
    }

    /// The caret follows the focused border, and a theme can move both.
    func test_repaint_tintsTheCaretWithTheFocusedBorderColour() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let themed = try DesignTokensManager.makeTokens(for: .light)
        themed.primerColorBorderOutlinedFocus = Color(red: 1, green: 0, blue: 0)
        let field = makeField(tokens: light)

        field.repaintPrimerColors(placeholder: "Card number", tokens: themed)

        XCTAssertEqual(field.tintColor, UIColor(CheckoutColors.borderFocus(tokens: themed)))
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

    /// A theme can give dark mode its own brand, and the Done button is drawn in the brand.
    func test_repaint_tintsTheExistingDoneButtonWithTheNewBrand() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let dark = try DesignTokensManager.makeTokens(for: .dark)
        dark.primerColorBrand = Color(red: 0, green: 1, blue: 0)
        let field = UITextField()
        field.configurePrimerStyle(
            placeholder: "Card number",
            configuration: .numberPad,
            tokens: light,
            doneButtonTarget: nil,
            doneButtonAction: #selector(UIResponder.resignFirstResponder)
        )
        let toolbar = try XCTUnwrap(field.inputAccessoryView as? UIToolbar)

        field.repaintPrimerColors(placeholder: "Card number", tokens: dark)

        let brand = UIColor(CheckoutColors.buttonPrimary(tokens: dark))
        XCTAssertTrue(field.inputAccessoryView === toolbar)
        XCTAssertEqual(toolbar.tintColor, brand)
        XCTAssertEqual(toolbar.items?.last?.titleTextAttributes(for: .normal)?[.foregroundColor] as? UIColor, brand)
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

    func test_repaint_locked_paintsTheTypedTextDisabledAndKeepsThePlaceholder() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let field = makeField(tokens: light)

        field.repaintPrimerColors(placeholder: "Card number", tokens: light, isEnabled: false)

        XCTAssertEqual(field.textColor, UIColor(CheckoutColors.textDisabled(tokens: light)))
        let placeholderColour = field.attributedPlaceholder?
            .attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertEqual(placeholderColour, UIColor(CheckoutColors.textPlaceholder(tokens: light)))
    }

    func test_repaintIfNeeded_lockChange_repaintsWithTheSameTokens() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let field = makeField(tokens: light)
        let repainter = PrimerFieldRepainter()
        repainter.markApplied(light)

        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: light, isEnabled: false)
        XCTAssertEqual(field.textColor, UIColor(CheckoutColors.textDisabled(tokens: light)))

        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: light, isEnabled: true)
        XCTAssertEqual(field.textColor, UIColor(CheckoutColors.inputText(tokens: light)))
    }

    // MARK: - What a lock does besides the colours

    func test_repaintIfNeeded_lock_disablesTheFieldAndUnlockEnablesItAgain() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let field = makeField(tokens: light)
        let repainter = PrimerFieldRepainter()
        repainter.markApplied(light)

        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: light, isEnabled: false)
        XCTAssertFalse(field.isEnabled)

        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: light, isEnabled: true)
        XCTAssertTrue(field.isEnabled)
    }

    func test_repaintIfNeeded_lock_endsTheEditOfAFocusedField() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let field = FocusedField()
        let repainter = PrimerFieldRepainter()
        repainter.markApplied(light)

        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: light, isEnabled: false)
        drainMainQueue()

        XCTAssertEqual(field.resignCount, 1)
    }

    func test_repaintIfNeeded_unlockAndNewTokens_leaveTheFocusAlone() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let dark = try DesignTokensManager.makeTokens(for: .dark)
        let field = FocusedField()
        let repainter = PrimerFieldRepainter()
        repainter.markApplied(light)
        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: light, isEnabled: false)
        drainMainQueue()
        field.hasFocus = true

        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: light, isEnabled: true)
        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: dark, isEnabled: true)
        drainMainQueue()

        XCTAssertEqual(field.resignCount, 1, "only the lock ends the edit")
    }

    // MARK: - Re-theme

    func test_repaintIfNeeded_reTheme_movesTheFontAndSpacingOfTypedTextAndPlaceholder() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let themed = try DesignTokensManager.makeTokens(for: .light)
        themed.primerTypographyBodyLargeSize = 22
        themed.primerTypographyBodyLargeLetterSpacing = 1.5
        let field = makeConfiguredField(tokens: light)
        field.text = "4242 4242"
        let repainter = PrimerFieldRepainter()
        repainter.markApplied(light)

        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: themed)
        XCTAssertEqual(field.font, PrimerFont.uiFontBodyLarge(tokens: light), "the font must wait for the update to end")
        drainMainQueue()

        let font = PrimerFont.uiFontBodyLarge(tokens: themed)
        let kern = try XCTUnwrap(PrimerTextStyle.bodyLarge.letterSpacing(tokens: themed))
        XCTAssertNotEqual(kern, PrimerTextStyle.bodyLarge.letterSpacing(tokens: light))
        XCTAssertEqual(field.font, font)
        XCTAssertEqual(field.defaultTextAttributes[.kern] as? CGFloat, kern)
        XCTAssertEqual(field.attributedPlaceholder?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont, font)
        XCTAssertEqual(field.attributedPlaceholder?.attribute(.kern, at: 0, effectiveRange: nil) as? CGFloat, kern)
        XCTAssertEqual(field.text, "4242 4242")
    }

    /// Rewriting the font from every update stopped the card form rendering, so a scheme change must not.
    func test_repaintIfNeeded_schemeChange_leavesTheFontAlone() throws {
        let light = try DesignTokensManager.makeTokens(for: .light)
        let dark = try DesignTokensManager.makeTokens(for: .dark)
        let field = makeConfiguredField(tokens: light)
        field.font = UIFont.systemFont(ofSize: 21)
        let repainter = PrimerFieldRepainter()
        repainter.markApplied(light)

        repainter.repaintIfNeeded(field, placeholder: "Card number", tokens: dark)
        drainMainQueue()

        XCTAssertEqual(field.font, UIFont.systemFont(ofSize: 21))
    }

    private func makeConfiguredField(tokens: DesignTokens) -> UITextField {
        let field = UITextField()
        field.configurePrimerStyle(
            placeholder: "Card number",
            configuration: .numberPad,
            tokens: tokens,
            doneButtonTarget: nil,
            doneButtonAction: #selector(UIResponder.resignFirstResponder)
        )
        return field
    }

    private func drainMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)
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

/// Reports focus without a key window, which a unit test cannot rely on.
private final class FocusedField: UITextField {
    var hasFocus = true
    private(set) var resignCount = 0
    override var isFirstResponder: Bool { hasFocus }
    override func resignFirstResponder() -> Bool {
        resignCount += 1
        hasFocus = false
        return true
    }
}
