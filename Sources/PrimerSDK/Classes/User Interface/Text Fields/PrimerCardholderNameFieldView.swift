//
//  PrimerCardholderFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
//

#if canImport(UIKit)

import UIKit

public final class PrimerCardholderNameFieldView: PrimerTextFieldView {
    
    internal var cardholderName: String {
        return textField._text ?? ""
    }
    
    override func xibSetup() {
        super.xibSetup()
        
        textField.keyboardType = .default
        textField.isAccessibilityElement = true
        textField.accessibilityIdentifier = "card_holder_txt_fld"
        textField.delegate = self
        isValid = { text in
            return text.isTypingValidCardholderName
        }
    }
    
    public override func textFieldDidBeginEditing(_ textField: UITextField) {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .focus,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
                    url: nil),
                extra: nil,
                objectType: .input,
                objectId: .cardHolder,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
    }
    
    public override func textFieldDidEndEditing(_ textField: UITextField) {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .blur,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
                    url: nil),
                extra: nil,
                objectType: .input,
                objectId: .cardHolder,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let positionOriginal = textField.beginningOfDocument
        let cursorLocation = textField.position(from: positionOriginal, offset: (range.location + NSString(string: string).length))
        
        guard let primerTextField = textField as? PrimerTextField else { return true }
        guard string.isValidCardholderName == true || string.isEmpty else { return false }
        let currentText = primerTextField._text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        
        switch self.isValid?(newText) {
        case true:
            validation = .valid
        case false:
            let err = PrimerValidationError.invalidCardholderName(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            validation = .invalid(err)
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

#endif
