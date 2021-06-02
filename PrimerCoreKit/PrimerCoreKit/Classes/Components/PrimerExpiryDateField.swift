//
//  PrimerCardNumberField.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 1/6/21.
//

import UIKit

public final class PrimerExpiryDateField: PrimerPCITextField {
    
    override func xibSetup() {
        super.xibSetup()
        
        primerTextField.keyboardType = .numberPad
        
        // This validation will be performed on textField did finish editing.
        self.isValid = { text in
            return (text.toDate(withFormat: "MM/yy", timeZone: nil)?.isValidExpiryDate == true)
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        
        let delimiter = "/"
        
        var replacementStr = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        
        // Remove the delimiter.
        replacementStr = replacementStr.replacingOccurrences(of: delimiter, with: "")
        
        // Replacement string must be numeric or empty.
        if !(replacementStr.isNumeric || replacementStr.isEmpty) { return false }
        
        // Replacement string cannot be longer than 4 chars.
        if replacementStr.count > 4 { return false }
        
        if replacementStr.count == 1 {
            // User has typed the first char. It can only be 0 or 1.
            if !(Int(replacementStr) == 0 || Int(replacementStr) == 1) {
                let err = NSError(domain: "primer.core", code: 10000, userInfo: [NSLocalizedDescriptionKey: "Month can only start with 0 or 1"])
                validation = .error(err)
            } else {
                validation = .empty
            }
            
        } else if replacementStr.count == 2 {
            // User has typed the first 2 chars (i.e. the month). It can only be within 1 to 12.
            if (Int(replacementStr) ?? 0) < 1 || (Int(replacementStr) ?? 0) > 12 {
                let err = NSError(domain: "primer.core", code: 10000, userInfo: [NSLocalizedDescriptionKey: "Month should be within range 1...12"])
                validation = .error(err)
            } else {
                validation = .empty
            }
            
        } else if replacementStr.count == 4 {
            // User has typed the whole expiry date. Validate if end of the month date is in the future.
            let validationStr = "\(replacementStr.prefix(2))/\(replacementStr.suffix(2))"
            validation = (isValid!(validationStr) == true) ? .valid : .error(NSError(domain: "primer.core", code: 10000, userInfo: [NSLocalizedDescriptionKey: "Invalid expiration date"]))
            
        } else {
            validation = .empty
        }
        
        if replacementStr.count == 2 && !string.isEmpty {
            // User has typed the month, add the delimiter
            replacementStr = replacementStr + delimiter
        } else if replacementStr.count == 2 && string.isEmpty {
            // User just deleted the year, don't add the delimiter
//            newText = newText.separate(every: 2, with: delimiter)
        } else {
            // User is typing, separate by the delimiter
            replacementStr = replacementStr.separate(every: 2, with: delimiter)
        }
        
        
        primerTextField._text = replacementStr
        primerTextField.text = replacementStr
        return false
    }
    
}
