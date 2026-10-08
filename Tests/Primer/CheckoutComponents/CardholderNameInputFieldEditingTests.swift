//
//  CardholderNameInputFieldEditingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

/// AutoFill and paste hand the delegate a whole name in one call.
@available(iOS 15.0, *)
@MainActor
final class CardholderNameInputFieldEditingTests: XCTestCase {

    private var cardholderName = ""
    private var isValid = false
    private var errorMessage: String?
    private var isFocused = true

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
    }

    override func tearDown() async throws {
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_pastedNameWithAStrayCharacter_keepsTheName() async {
        await type("John Smith.")

        XCTAssertEqual(cardholderName, "John Smith")
    }

    func test_typographicApostrophe_isKeptAsAPlainOne() async {
        await type("Seán O\u{2019}Brien")

        XCTAssertEqual(cardholderName, "Seán O'Brien")
    }

    func test_typographicHyphenAndSpace_keepTheNamePartsApart() async {
        await type("Jean\u{2011}Pierre\u{00A0}Dupont")

        XCTAssertEqual(cardholderName, "Jean-Pierre Dupont")
    }

    func test_emoji_isDroppedWithItsVariationSelector() async {
        await type("Jane\u{2764}\u{FE0F}")

        XCTAssertEqual(cardholderName, "Jane")
    }

    /// The iOS Persian keyboard writes this surname with a zero-width non-joiner after the "n".
    func test_letterFollowedByAJoiner_keepsTheLetter() async {
        await type("\u{062D}\u{0633}\u{0646}\u{200C}\u{0632}\u{0627}\u{062F}\u{0647}")

        XCTAssertEqual(cardholderName, "\u{062D}\u{0633}\u{0646}\u{0632}\u{0627}\u{062F}\u{0647}")
    }

    func test_conjunctWithAJoiner_keepsItsLetters() async {
        await type("\u{0915}\u{094D}\u{200D}\u{0937}")

        XCTAssertEqual(cardholderName, "\u{0915}\u{094D}\u{0937}")
    }

    func test_letterWithASkinToneModifier_keepsTheLetter() async {
        await type("Ana\u{1F3FD}")

        XCTAssertEqual(cardholderName, "Ana")
    }

    func test_onlyDisallowedCharacters_changeNothing() async {
        cardholderName = "Jo"

        await type("42", at: NSRange(location: 2, length: 0))

        XCTAssertEqual(cardholderName, "Jo")
    }

    private func type(_ string: String, at range: NSRange = NSRange(location: 0, length: 0)) async {
        let scope = DefaultCardFormScope(
            checkoutScope: await ContainerTestHelpers.createMockCheckoutScope(),
            presentationContext: .fromPaymentSelection,
            processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
            validateInputInteractor: MockValidateInputInteractor(),
            cardNetworkDetectionInteractor: MockCardNetworkDetectionInteractor(),
            analyticsInteractor: MockAnalyticsInteractor(),
            configurationService: MockConfigurationService.withDefaultConfiguration()
        )
        let coordinator = CardholderNameTextField.Coordinator(
            validationService: DefaultValidationService(),
            cardholderName: Binding(get: { self.cardholderName }, set: { self.cardholderName = $0 }),
            isValid: Binding(get: { self.isValid }, set: { self.isValid = $0 }),
            errorMessage: Binding(get: { self.errorMessage }, set: { self.errorMessage = $0 }),
            isFocused: Binding(get: { self.isFocused }, set: { self.isFocused = $0 }),
            scope: scope
        )
        _ = coordinator.textField(UITextField(), shouldChangeCharactersIn: range, replacementString: string)
    }
}
