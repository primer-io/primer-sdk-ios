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
