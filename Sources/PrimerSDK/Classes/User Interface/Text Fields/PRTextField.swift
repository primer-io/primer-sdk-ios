//
//  PrimerTextField.swift
//  Pods-PrimerSDK_Example
//
//  Created by Evangelos Pittas on 29/6/21.
//

import UIKit

internal class PrimerTextField: UITextField {
    
    internal enum Validation {
        case valid, invalid(_ error: Error?), notAvailable
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
        
}
