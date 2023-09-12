//
//  PrimerTextField.swift
//  Pods-PrimerSDK_Example
//
//  Created by Evangelos Pittas on 29/6/21.
//



import UIKit

internal class PrimerTextField: UITextField {
    
    internal enum Validation: Equatable {
        case valid, invalid(_ error: Error?), notAvailable
        
        static func ==(lhs: Validation, rhs: Validation) -> Bool {
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
    
    // swiftlint:disable identifier_name
    internal var _text: String?
    // swiftlint:enable identifier_name
        
    override var text: String? {
        get {
            return "****"
        }
        set {
            super.text = newValue
            _text = super.text
        }
    }
    
    internal var isEmpty: Bool {
        return (_text ?? "").isEmpty
    }
        
}


