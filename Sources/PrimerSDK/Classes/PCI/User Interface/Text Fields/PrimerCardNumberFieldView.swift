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
        keyboardType = .numberPad
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "card_txt_fld"
        textField.delegate = self
        isEditingAnalyticsEnabled = true
        editingAnalyticsObjectId = .cardNumber
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.cardNetwork = CardNetwork(cardNumber: primerTextField._text ?? "")
            
            DispatchQueue.main.async {
                if newText.isEmpty {
                    self.delegate?.primerTextFieldView(self, didDetectCardNetwork: nil)
                } else {
                    self.delegate?.primerTextFieldView(self, didDetectCardNetwork: self.cardNetwork)
                }
            }
            
            if self.isValid?(primerTextField._text?.withoutWhiteSpace ?? "") ?? false {
                self.validation = .valid
            } else if (primerTextField._text?.withoutWhiteSpace ?? "").isEmpty {
                let err = PrimerValidationError.invalidCardnumber(
                    message: "Card number can not be blank.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                self.validation = PrimerTextField.Validation.invalid(err)
                
            } else {
                let err = PrimerValidationError.invalidCardnumber(
                    message: "Card number is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                self.validation = PrimerTextField.Validation.invalid(err)
            }
            
            DispatchQueue.main.async {
                switch self.validation {
                case .valid:
                    if let maxLength = self.cardNetwork.validation?.lengths.max(), newText.withoutWhiteSpace.count == maxLength {
                        self.delegate?.primerTextFieldView(self, isValid: true)
                    } else {
                        self.delegate?.primerTextFieldView(self, isValid: nil)
                    }
                case .invalid:
                    if let maxLength = self.cardNetwork.validation?.lengths.max(), newText.withoutWhiteSpace.count == maxLength {
                        self.delegate?.primerTextFieldView(self, isValid: false)
                    } else {
                        self.delegate?.primerTextFieldView(self, isValid: nil)
                    }
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
