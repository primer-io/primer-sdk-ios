//
//  PrimerNameField.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 2/6/21.
//

import Foundation

public final class PrimerNameField: PrimerPCITextField {
    
    override func xibSetup() {
        super.xibSetup()
        
        primerTextField.keyboardType = .default
        
        // This validation will be performed on textField did finish editing.
        self.isValid = { text in
            return (text.split(separator: " ").count > 1)
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
                
        let replacementStr = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        primerTextField._text = replacementStr
        primerTextField.text = replacementStr
        return false
    }
    
}
