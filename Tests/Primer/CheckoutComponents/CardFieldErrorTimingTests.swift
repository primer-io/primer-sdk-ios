//
//  CardFieldErrorTimingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

@available(iOS 15.0, *)
@MainActor
final class CardFieldErrorTimingTests: XCTestCase {

    private var text = ""
    private var month = ""
    private var year = ""
    private var cardNetwork: CardNetwork = .unknown
    private var isValid = false
    private var errorMessage: String?
    private var isFocused = false

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
    }

    override func tearDown() async throws {
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_cardNumber_keepsItsErrorWhenFocusedAgain_untilTheNumberIsValid() async {
        let scope = await makeScope()
        let coordinator = CardNumberTextField.Coordinator(
            scope: scope,
            validationService: DefaultValidationService(),
            cardNumber: binding(\.text),
            cardNetwork: binding(\.cardNetwork),
            isValid: binding(\.isValid),
            errorMessage: binding(\.errorMessage),
            isFocused: binding(\.isFocused)
        )
        let field = SecureTextField()

        typeCardNumber("55555555", into: field, with: coordinator)
        await leaveAndFocusAgain(field, with: coordinator)
        XCTAssertNotNil(errorMessage)

        typeCardNumber("5555444", into: field, with: coordinator)
        XCTAssertNotNil(errorMessage)

        typeCardNumber("4", into: field, with: coordinator)
        XCTAssertNil(errorMessage)
        XCTAssertNil(scope.getFieldError(.cardNumber))
    }

    func test_expiryDate_keepsItsErrorWhenFocusedAgain_untilTheDateIsValid() async {
        let scope = await makeScope()
        let coordinator = ExpiryDateTextField.Coordinator(
            validationService: DefaultValidationService(),
            expiryDate: binding(\.text),
            month: binding(\.month),
            year: binding(\.year),
            isValid: binding(\.isValid),
            errorMessage: binding(\.errorMessage),
            isFocused: binding(\.isFocused),
            scope: scope
        )
        let field = UITextField()

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "0120")
        await leaveAndFocusAgain(field, with: coordinator)
        XCTAssertNotNil(errorMessage)

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 3, length: 2), replacementString: "3")
        XCTAssertNotNil(errorMessage)

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 4, length: 0), replacementString: "0")
        XCTAssertNil(errorMessage)
        XCTAssertNil(scope.getFieldError(.expiryDate))
    }

    func test_expiryDate_leftEmpty_showsNoError() async {
        let coordinator = ExpiryDateTextField.Coordinator(
            validationService: DefaultValidationService(),
            expiryDate: binding(\.text),
            month: binding(\.month),
            year: binding(\.year),
            isValid: binding(\.isValid),
            errorMessage: binding(\.errorMessage),
            isFocused: binding(\.isFocused),
            scope: await makeScope()
        )

        await leaveAndFocusAgain(UITextField(), with: coordinator)

        XCTAssertNil(errorMessage)
    }

    func test_cvv_keepsItsErrorWhenFocusedAgain_untilTheCodeIsValid() async {
        let scope = await makeScope()
        let coordinator = makeCVVCoordinator(scope: scope)
        let field = UITextField()

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "12")
        await leaveAndFocusAgain(field, with: coordinator)
        XCTAssertNotNil(errorMessage)

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 2, length: 0), replacementString: "3")
        XCTAssertNil(errorMessage)
        XCTAssertNil(scope.getFieldError(.cvv))
    }

    func test_cvv_clearedAfterAnError_hidesTheError() async {
        let scope = await makeScope()
        let coordinator = makeCVVCoordinator(scope: scope)
        let field = UITextField()

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "12")
        await leaveAndFocusAgain(field, with: coordinator)
        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 2), replacementString: "")

        XCTAssertNil(errorMessage)
        XCTAssertNil(scope.getFieldError(.cvv))
    }

    func test_cardholderName_keepsItsErrorWhenFocusedAgain_untilTheNameIsValid() async {
        let scope = await makeScope()
        let coordinator = CardholderNameTextField.Coordinator(
            validationService: DefaultValidationService(),
            cardholderName: binding(\.text),
            isValid: binding(\.isValid),
            errorMessage: binding(\.errorMessage),
            isFocused: binding(\.isFocused),
            scope: scope
        )
        let field = UITextField()

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "J")
        await leaveAndFocusAgain(field, with: coordinator)
        XCTAssertNotNil(errorMessage)

        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 1, length: 0), replacementString: "ohn")
        XCTAssertNil(errorMessage)
        XCTAssertNil(scope.getFieldError(.cardholderName))
    }

    private func typeCardNumber(_ digits: String, into field: SecureTextField, with coordinator: CardNumberTextField.Coordinator) {
        let formatted = CardNumberFormatter.format(text, for: cardNetwork)
        field.internalText = formatted
        _ = coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: formatted.count, length: 0), replacementString: digits)
    }

    private func leaveAndFocusAgain(_ field: UITextField, with delegate: UITextFieldDelegate) async {
        delegate.textFieldDidEndEditing?(field)
        await drainMainQueue()
        delegate.textFieldDidBeginEditing?(field)
        await drainMainQueue()
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    private func makeCVVCoordinator(scope: DefaultCardFormScope) -> CVVTextField.Coordinator {
        CVVTextField.Coordinator(
            validationService: DefaultValidationService(),
            cardNetwork: .masterCard,
            cvv: binding(\.text),
            isValid: binding(\.isValid),
            errorMessage: binding(\.errorMessage),
            isFocused: binding(\.isFocused),
            scope: scope
        )
    }

    private func makeScope() async -> DefaultCardFormScope {
        DefaultCardFormScope(
            checkoutScope: await ContainerTestHelpers.createMockCheckoutScope(),
            presentationContext: .fromPaymentSelection,
            processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
            validateInputInteractor: MockValidateInputInteractor(),
            cardNetworkDetectionInteractor: MockCardNetworkDetectionInteractor(),
            analyticsInteractor: MockAnalyticsInteractor(),
            configurationService: MockConfigurationService.withDefaultConfiguration()
        )
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<CardFieldErrorTimingTests, Value>) -> Binding<Value> {
        Binding(get: { self[keyPath: keyPath] }, set: { self[keyPath: keyPath] = $0 })
    }
}
