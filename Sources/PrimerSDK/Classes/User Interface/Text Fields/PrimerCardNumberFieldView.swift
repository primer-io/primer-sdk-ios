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
        
        textField.keyboardType = .numberPad
        textField.delegate = self
        isValid = { text in
            return text.isValidCardNumber
        }
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        if string != "" && currentText.withoutWhiteSpace.count == 19 { return false }
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        if !newText.withoutWhiteSpace.isNumeric && !string.isEmpty { return false }
        primerTextField._text = newText
        cardNetwork = CardNetwork(cardNumber: primerTextField._text ?? "")
        delegate?.primerTextFieldView(self, didDetectCardNetwork: cardNetwork)
        validation = (self.isValid?(primerTextField._text?.withoutWhiteSpace ?? "") ?? false) ? .valid : .invalid(PrimerError.invalidCardnumber)
        
        switch validation {
        case .valid:
            delegate?.primerTextFieldView(self, isValid: true)
        default:
            delegate?.primerTextFieldView(self, isValid: nil)
        }
        
        primerTextField.text = newText.withoutWhiteSpace.separate(every: 4, with: " ")
        return false
    }
    
}
