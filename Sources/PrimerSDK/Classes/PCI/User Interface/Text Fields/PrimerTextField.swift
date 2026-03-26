//
//  PrimerTextField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class PrimerTextField: UITextField {

    enum Validation: Equatable {
        case valid, invalid(_ error: Error?), notAvailable

        static func == (lhs: Validation, rhs: Validation) -> Bool {
            switch (lhs, rhs) {
            case (.valid, .valid):
                lhs == rhs
            case (.invalid, .invalid):
                lhs == rhs
            case (.notAvailable, .notAvailable):
                lhs == rhs
            default:
                false
            }
        }
    }

    override var delegate: UITextFieldDelegate? {
        get {
            super.delegate
        }
        set {
            if let primerTextFieldView = newValue as? PrimerTextFieldView {
                super.delegate = primerTextFieldView
            }
        }
    }

    var internalText: String?

    override var text: String? {
        get {
            "****"
        }
        set {
            super.text = newValue
            internalText = super.text
        }
    }

    var isEmpty: Bool {
        (internalText ?? "").isEmpty
    }

    func wipe() {
        if var bytes = internalText?.utf8CString {
            for idx in bytes.indices { bytes[idx] = 0 }
        }
        internalText = nil
        super.text = nil
    }
}
