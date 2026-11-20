//
//  NameInputFieldValidationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

@available(iOS 15.0, *)
@MainActor
final class NameInputFieldValidationTests: XCTestCase {

    func test_firstNameField_rejectsDigits() {
        let field = FieldBox(.firstName, text: "Jane1")

        field.leave()

        XCTAssertFalse(field.isValid)
        XCTAssertEqual(field.errorMessage, CheckoutComponentsStrings.firstNameErrorInvalid)
    }
}

@available(iOS 15.0, *)
@MainActor
private final class FieldBox {
    var text: String
    var isValid = false
    var errorMessage: String?
    var isFocused = true
    private var coordinator: NameTextField.Coordinator!

    init(_ inputType: PrimerInputElementType, text: String) {
        self.text = text
        coordinator = NameTextField.Coordinator(
            validationService: DefaultValidationService(),
            name: Binding(get: { self.text }, set: { self.text = $0 }),
            isValid: Binding(get: { self.isValid }, set: { self.isValid = $0 }),
            errorMessage: Binding(get: { self.errorMessage }, set: { self.errorMessage = $0 }),
            isFocused: Binding(get: { self.isFocused }, set: { self.isFocused = $0 }),
            inputType: inputType,
            scope: nil,
            onNameChange: nil,
            onValidationChange: nil
        )
    }

    func leave() {
        coordinator.textFieldDidEndEditing(UITextField())
    }
}
