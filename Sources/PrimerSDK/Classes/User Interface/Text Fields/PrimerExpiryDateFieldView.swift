//
//  PrimerExpiryDateFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
//

#if canImport(UIKit)

import UIKit

public final class PrimerExpiryDateFieldView: PrimerTextFieldView {
    
    private(set) public var expiryMonth: String?
    private(set) public var expiryYear: String?
            
    override func xibSetup() {
        super.xibSetup()
        
        textField.keyboardType = .numberPad
        textField.isAccessibilityElement = true
        textField.accessibilityIdentifier = "expiry_txt_fld"
        textField.delegate = self
        isValid = { text in
            let isValid = text.isValidExpiryDate
            return isValid
        }
    }
    
    public override func textFieldDidBeginEditing(_ textField: UITextField) {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .focus,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: PaymentMethodConfigType.paymentCard.rawValue,
                    url: nil),
                extra: nil,
                objectType: .input,
                objectId: .expiry,
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
                    paymentMethodType: PaymentMethodConfigType.paymentCard.rawValue,
                    url: nil),
                extra: nil,
                objectType: .input,
                objectId: .expiry,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        var newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        newText = newText.replacingOccurrences(of: "/", with: "")
        if !(newText.isNumeric || newText.isEmpty) { return false }
        if string != "" && newText.withoutWhiteSpace.count >= 5 { return false }
        
        validation = (self.isValid?(newText) ?? false) ? .valid : .invalid(PrimerError.invalidExpiryDate)
        
        switch validation {
        case .valid:
            delegate?.primerTextFieldView(self, isValid: true)
        default:
            delegate?.primerTextFieldView(self, isValid: nil)
        }
        
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
        
        if newText.isValidExpiryDate {
            expiryMonth = String(newText.prefix(2))
            expiryYear = String(newText.suffix(2))
        } else {
            expiryMonth = nil
            expiryYear = nil
        }
        return false
    }
    
}

#endif
