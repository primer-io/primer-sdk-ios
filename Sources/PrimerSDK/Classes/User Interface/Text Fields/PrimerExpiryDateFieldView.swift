//
//  PrimerExpiryDateFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
//

import UIKit

public final class PrimerExpiryDateFieldView: PrimerTextFieldView {
            
    override func xibSetup() {
        super.xibSetup()
        
        textField.delegate = self
        isValid = { text in
            let isValid = text.isTypingValidExpiryDate
            print(isValid)
            return isValid
        }
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        var newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        newText = newText.replacingOccurrences(of: "/", with: "")
        if !(newText.isNumeric || newText.isEmpty) { return false }
        if string != "" && newText.withoutWhiteSpace.count >= 5 { return false }
        
        validation = (self.isValid?(newText) ?? false) ? .valid : .invalid(NSError(domain: "primer", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid value."]))
        
        if string != "" {   // Typing
            if newText.count == 2 {
                newText += "/"
            } else {
                newText = newText.separate(every: 2, with: "/")
            }
            
        } else {            // Deleting
            if newText.count == 2 {
    //            newText += "/"
            } else {
                newText = newText.separate(every: 2, with: "/")
            }
        }
        
        primerTextField._text = newText
        primerTextField.text = newText
        return false
    }
    
}
