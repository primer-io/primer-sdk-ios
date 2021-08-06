//
//  PrimerCardNumberFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
//

import UIKit

public final class PrimerCardNumberFieldView: PrimerTextFieldView {
        
    private(set) public var cardNetwork: CardNetwork = .unknown
    internal var cardnumber: String {
        return (textField._text ?? "").replacingOccurrences(of: " ", with: "").withoutWhiteSpace
    }
    
    override func xibSetup() {
        super.xibSetup()
        
        textField.delegate = self
        isValid = { text in
            return text.isValidCardNumber
        }
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""

        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        if !newText.withoutNonNumericCharacters.isNumeric && !string.isEmpty { return false }
        
        cardNetwork = CardNetwork(cardNumber: primerTextField._text ?? "")
        let cardNetworkValidation = cardNetwork.validation
        let maxCardNetworkDigits = cardNetworkValidation?.lengths.max() ?? 19
        if string != "" && currentText.withoutNonNumericCharacters.count == maxCardNetworkDigits { return false }
        
        primerTextField._text = newText
        
        delegate?.primerTextFieldView(self, didDetectCardNetwork: cardNetwork)
        validation = (self.isValid?(primerTextField._text ?? "") ?? false) ? .valid : .invalid(NSError(domain: "primer", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid value."]))
        
        if let cardNetworkValidation = cardNetworkValidation {
            primerTextField.text = newText.withoutNonNumericCharacters.separate(on: cardNetworkValidation.gaps, with: " ")
        } else {
            primerTextField.text = newText.withoutNonNumericCharacters.separate(every: 4, with: " ")
        }
        
        return false
    }
    
}
