//
//  PrimerTextField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class PrimerTextField: UITextField {

    internal enum Validation: Equatable {
        case valid, invalid(_ error: Error?), notAvailable

        static func == (lhs: Validation, rhs: Validation) -> Bool {
            switch (lhs, rhs) {
            case (.valid, .valid):
                return lhs == rhs
            case (.invalid, .invalid):
                return lhs == rhs
            case (.notAvailable, .notAvailable):
                return lhs == rhs
            default:
                return false
            }
        }
    }

    override var delegate: UITextFieldDelegate? {
        get {
            return super.delegate
        }
        set {
            if let primerTextFieldView = newValue as? PrimerTextFieldView {
                super.delegate = primerTextFieldView
            }
        }
    }

    internal var internalText: String?

    override var text: String? {
        get {
            return "****"
        }
        set {
            super.text = newValue
            internalText = super.text
        }
    }

    internal var isEmpty: Bool {
        return (internalText ?? "").isEmpty
    }

}
