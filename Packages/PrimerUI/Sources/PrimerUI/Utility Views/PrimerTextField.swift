//
//  PrimerTextField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public final class PrimerTextField: UITextField {

    public enum Validation: Equatable {
        case valid, invalid(_ error: Error?), notAvailable

        public static func == (lhs: Validation, rhs: Validation) -> Bool {
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

    override public var delegate: UITextFieldDelegate? {
        get {
            super.delegate
        }
        set {
            if let primerTextFieldView = newValue as? PrimerTextFieldView {
                super.delegate = primerTextFieldView
            }
        }
    }

    public var internalText: String?

    override public var text: String? {
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

}
