//
//  PrimerCVVField.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 2/6/21.
//


import UIKit

public final class PrimerCVVField: PrimerPCITextField {
    
    override func xibSetup() {
        super.xibSetup()
        
        primerTextField.keyboardType = .numberPad
        
        // This validation will be performed on textField did finish editing.
        self.isValid = { text in
            return text.count == 3
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
                
        let replacementStr = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        
        // Replacement string must be numeric or empty.
        if !(replacementStr.isNumeric || replacementStr.isEmpty) { return false }
        
        // Replacement string cannot be longer than 3 chars.
        if replacementStr.count > 3 { return false }
        
        validation = .empty
        
        primerTextField._text = replacementStr
        primerTextField.text = replacementStr
        return false
    }
    
}
