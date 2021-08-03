//
//  PrimerCVVFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
//

import UIKit

public final class PrimerCVVFieldView: PrimerTextFieldView {
    
    internal var cvv: String {
        return textField._text ?? ""
    }
    
    override func xibSetup() {
        super.xibSetup()
        
        textField.keyboardType = .numberPad
        textField.delegate = self
        isValid = { text in
            return text.isTypingValidCVV
        }
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        if !(newText.isNumeric || newText.isEmpty) { return false }
        if string != "" && newText.withoutWhiteSpace.count >= 5 { return false }
        
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
        return false
    }
    
}
