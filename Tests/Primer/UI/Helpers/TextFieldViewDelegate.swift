//
//  TextFieldViewDelegate.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

class MockTextFieldViewDelegate: PrimerTextFieldViewDelegate {

    var onDidBeginEditing: (() -> Void)?

    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        onDidBeginEditing?()
    }

    var onDidEndEditing: (() -> Void)?

    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView) {
        onDidEndEditing?()
    }

    var onShouldBeginEditing: (() -> Bool)?

    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        onShouldBeginEditing?() ?? false
    }

    var onShouldEndEditing: (() -> Bool)?

    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        onShouldEndEditing?() ?? false
    }

    var onIsValid: ((Bool?) -> Void)?

    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        onIsValid?(isValid)
    }
}
