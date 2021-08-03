//
//  PrimerCardholderFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
//

import UIKit

public final class PrimerCardholderNameFieldView: PrimerTextFieldView {
    
    internal var cardholderName: String {
        return textField._text ?? ""
    }
    
    override func xibSetup() {
        super.xibSetup()
        
        textField.keyboardType = .namePhonePad
        textField.delegate = self
        isValid = { text in
            return text.isTypingValidCardholderName
        }
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let positionOriginal = textField.beginningOfDocument
        let cursorLocation = textField.position(from: positionOriginal, offset: (range.location + NSString(string: string).length))
        
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        
        switch self.isValid?(newText) {
        case true:
            validation = .valid
        case false:
            validation = .invalid(NSError(domain: "primer", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid value."]))
        default:
            validation = .notAvailable
        }
        
        switch validation {
        case .valid:
            delegate?.primerTextFieldView(self, isValid: true)
        default:
            delegate?.primerTextFieldView(self, isValid: nil)
        }
        
        primerTextField._text = newText
        primerTextField.text = newText
        
        if let cursorLoc = cursorLocation {
            textField.selectedTextRange = textField.textRange(from: cursorLoc, to: cursorLoc)
        }
        
        return false
    }
    
}
