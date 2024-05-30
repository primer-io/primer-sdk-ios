//
//  TextFieldViewDelegate.swift
//
//
//  Created by Jack Newcombe on 21/05/2024.
//

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
