//
//  CardNumberInputFieldEditingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

/// Paste and AutoFill hand the delegate the whole string with the selection as the range.
@available(iOS 15.0, *)
@MainActor
final class CardNumberInputFieldEditingTests: XCTestCase {

    private var cardNumber = "4242424242424242"
    private var cardNetwork: CardNetwork = .visa
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

    func test_pasteOverASelectedGroup_replacesThoseDigits() async {
        let (coordinator, field) = await makeField()

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 4), replacementString: "5555")

        XCTAssertEqual(cardNumber, "5555424242424242")
    }

    func test_pasteOverTheWholeNumber_replacesIt() async {
        let (coordinator, field) = await makeField()

        _ = coordinator.textField(
            field, shouldChangeCharactersIn: NSRange(location: 0, length: 19), replacementString: "5555 5555 5555 4444")

        XCTAssertEqual(cardNumber, "5555555555554444")
    }

    func test_insertWithoutSelection_stillInsertsAtTheCaret() async {
        cardNumber = "424242424242424"
        let (coordinator, field) = await makeField(formatted: "4242 4242 4242 424")

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 18, length: 0), replacementString: "2")

        XCTAssertEqual(cardNumber, "4242424242424242")
    }

    func test_insertInTheMiddleWithoutSelection_landsAtTheCaret() async {
        cardNumber = "424242424242424"
        let (coordinator, field) = await makeField(formatted: "4242 4242 4242 424")

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 5, length: 0), replacementString: "9")

        XCTAssertEqual(cardNumber, "4242942424242424")
    }

    func test_pasteOverAMiddleGroup_leavesTheCaretAfterThePastedDigits() async throws {
        let (coordinator, field) = await makeField()

        let caret = try edit(coordinator, field, NSRange(location: 10, length: 4), "5555")

        XCTAssertEqual(field.internalText, "4242 4242 5555 4242")
        XCTAssertEqual(caret, 14)
    }

    func test_typeBeforeAGroupSpace_leavesTheCaretAfterTheDigit() async throws {
        cardNumber = "42424242"
        let (coordinator, field) = await makeField(formatted: "4242 4242")

        let caret = try edit(coordinator, field, NSRange(location: 4, length: 0), "9")

        XCTAssertEqual(field.internalText, "4242 9424 2")
        XCTAssertEqual(caret, 6)
    }

    func test_typeInTheMiddleOfAGroup_leavesTheCaretAfterTheDigit() async throws {
        cardNumber = "424242424242424"
        let (coordinator, field) = await makeField(formatted: "4242 4242 4242 424")

        let caret = try edit(coordinator, field, NSRange(location: 6, length: 0), "9")

        XCTAssertEqual(field.internalText, "4242 4924 2424 2424")
        XCTAssertEqual(caret, 7)
    }

    func test_typeAtTheEnd_leavesTheCaretAtTheEnd() async throws {
        cardNumber = "424242424242424"
        let (coordinator, field) = await makeField(formatted: "4242 4242 4242 424")

        let caret = try edit(coordinator, field, NSRange(location: 18, length: 0), "2")

        XCTAssertEqual(caret, 19)
    }

    func test_pastePastTheLengthCap_leavesTheCaretAtTheEnd() async throws {
        let (coordinator, field) = await makeField()

        let caret = try edit(coordinator, field, NSRange(location: 19, length: 0), "123456")

        XCTAssertEqual(cardNumber, "4242424242424242123")
        XCTAssertEqual(caret, field.internalText?.count)
    }

    func test_backspaceInTheMiddle_leavesTheCaretWhereTheDigitWas() async throws {
        let (coordinator, field) = await makeField()

        let caret = try edit(coordinator, field, NSRange(location: 6, length: 1), "")

        XCTAssertEqual(cardNumber, "424244242424242")
        XCTAssertEqual(caret, 6)
    }

    func test_backspaceOverAGroupSpace_deletesTheDigitBeforeIt() async throws {
        cardNumber = "42424242"
        let (coordinator, field) = await makeField(formatted: "4242 4242")

        let caret = try edit(coordinator, field, NSRange(location: 4, length: 1), "")

        XCTAssertEqual(cardNumber, "4244242")
        XCTAssertEqual(caret, 3)
    }

    func test_forwardDeleteOverAGroupSpace_deletesTheDigitAfterIt() async throws {
        cardNumber = "42424242"
        let (coordinator, field) = await makeField(formatted: "4242 4242")

        let caret = try edit(coordinator, field, NSRange(location: 4, length: 1), "", forwardDelete: true)

        XCTAssertEqual(cardNumber, "4242242")
        XCTAssertEqual(caret, 4)
    }

    func test_deleteASelectionAcrossAGroupSpace_leavesTheCaretAtItsStart() async throws {
        let (coordinator, field) = await makeField()

        let caret = try edit(coordinator, field, NSRange(location: 2, length: 5), "")

        XCTAssertEqual(cardNumber, "424242424242")
        XCTAssertEqual(caret, 2)
    }

    func test_autoFillWithDashesOverTheWholeNumber_leavesTheCaretAtTheEnd() async throws {
        let (coordinator, field) = await makeField()

        let caret = try edit(coordinator, field, NSRange(location: 0, length: 19), "5555-5555-5555-4444")

        XCTAssertEqual(field.internalText, "5555 5555 5555 4444")
        XCTAssertEqual(caret, 19)
    }

    func test_backspaceInAnAmexGroup_leavesTheCaretWhereTheDigitWas() async throws {
        cardNumber = "378282246310005"
        cardNetwork = .amex
        let (coordinator, field) = await makeField(formatted: "3782 822463 10005")

        let caret = try edit(coordinator, field, NSRange(location: 10, length: 1), "")

        XCTAssertEqual(cardNumber, "37828224610005")
        XCTAssertEqual(caret, 10)
    }

    /// Selects what UIKit has selected for this edit: a backspace leaves its caret after the removed
    /// character, a forward delete before it.
    private func edit(
        _ coordinator: CardNumberTextField.Coordinator, _ field: UITextField, _ range: NSRange, _ string: String,
        forwardDelete: Bool = false
    ) throws -> Int {
        let isSingleDelete = string.isEmpty && range.length == 1
        let caretAfter = isSingleDelete && !forwardDelete
        let start = try XCTUnwrap(field.position(from: field.beginningOfDocument, offset: range.location + (caretAfter ? 1 : 0)))
        let end = try XCTUnwrap(field.position(from: start, offset: isSingleDelete ? 0 : range.length))
        field.selectedTextRange = field.textRange(from: start, to: end)

        _ = coordinator.textField(field, shouldChangeCharactersIn: range, replacementString: string)

        let caret = try XCTUnwrap(field.selectedTextRange?.start)
        return field.offset(from: field.beginningOfDocument, to: caret)
    }

    private func makeField(formatted: String = "4242 4242 4242 4242") async -> (CardNumberTextField.Coordinator, SecureTextField) {
        let scope = DefaultCardFormScope(
            checkoutScope: await ContainerTestHelpers.createMockCheckoutScope(),
            presentationContext: .fromPaymentSelection,
            processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
            validateInputInteractor: MockValidateInputInteractor(),
            cardNetworkDetectionInteractor: MockCardNetworkDetectionInteractor(),
            analyticsInteractor: MockAnalyticsInteractor(),
            configurationService: MockConfigurationService.withDefaultConfiguration()
        )
        let coordinator = CardNumberTextField.Coordinator(
            scope: scope,
            validationService: DefaultValidationService(),
            cardNumber: Binding(get: { self.cardNumber }, set: { self.cardNumber = $0 }),
            cardNetwork: Binding(get: { self.cardNetwork }, set: { self.cardNetwork = $0 }),
            isValid: Binding(get: { self.isValid }, set: { self.isValid = $0 }),
            errorMessage: Binding(get: { self.errorMessage }, set: { self.errorMessage = $0 }),
            isFocused: Binding(get: { self.isFocused }, set: { self.isFocused = $0 })
        )
        let field = SecureTextField()
        field.internalText = formatted
        return (coordinator, field)
    }
}
