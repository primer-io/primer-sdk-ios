//
//  PrimerCardNumberFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
//

#if canImport(UIKit)

import UIKit

public final class PrimerCardNumberFieldView: PrimerTextFieldView {
        
    private(set) public var cardNetwork: CardNetwork = .unknown
    internal var cardnumber: String {
        return (textField._text ?? "").replacingOccurrences(of: " ", with: "").withoutWhiteSpace
    }
    
    override func xibSetup() {
        super.xibSetup()
        
        textField.keyboardType = .numberPad
        textField.isAccessibilityElement = true
        textField.accessibilityIdentifier = "card_txt_fld"
        textField.delegate = self
        isValid = { text in
            return text.isValidCardNumber
        }
    }
    
    public override func textFieldDidBeginEditing(_ textField: UITextField) {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: nil,
                extra: "cardnumber textfield",
                objectType: .textField,
                objectId: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
    }
    
    public override func textFieldDidEndEditing(_ textField: UITextField) {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .blur,
                context: nil,
                extra: "cardnumber textfield",
                objectType: .textField,
                objectId: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        if string != "" && currentText.withoutWhiteSpace.count == 19 { return false }
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        if !newText.withoutWhiteSpace.isNumeric && !string.isEmpty { return false }
        primerTextField._text = newText
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.cardNetwork = CardNetwork(cardNumber: primerTextField._text ?? "")
            
            DispatchQueue.main.async {
                if newText.isEmpty {
                    self.delegate?.primerTextFieldView(self, didDetectCardNetwork: nil)
                } else {
                    self.delegate?.primerTextFieldView(self, didDetectCardNetwork: self.cardNetwork)
                }
            }
            
            self.validation = (self.isValid?(primerTextField._text?.withoutWhiteSpace ?? "") ?? false) ? PrimerTextField.Validation.valid : PrimerTextField.Validation.invalid(PrimerError.invalidCardnumber)
            
            DispatchQueue.main.async {
                switch self.validation {
                case .valid:
                    self.delegate?.primerTextFieldView(self, isValid: true)
                default:
                    self.delegate?.primerTextFieldView(self, isValid: nil)
                }
            }
        }
        
        
        primerTextField.text = newText.withoutWhiteSpace.separate(every: 4, with: " ")
        return false
    }
    
}

#endif
