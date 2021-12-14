//
//  PrimerCVVFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
//

#if canImport(UIKit)

import UIKit

public final class PrimerCVVFieldView: PrimerTextFieldView {
    
    internal var cvv: String {
        return textField._text ?? ""
    }
    public var cardNetwork: CardNetwork = .unknown
    
    override func xibSetup() {
        super.xibSetup()
        
        textField.keyboardType = .numberPad
        textField.isAccessibilityElement = true
        textField.accessibilityIdentifier = "cvc_txt_fld"
        textField.delegate = self
        isValid = { [weak self] text in
            guard let strongSelf = self else { return false }
            return text.isTypingValidCVV(cardNetwork: strongSelf.cardNetwork)
        }
    }
    
    public override func textFieldDidBeginEditing(_ textField: UITextField) {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: nil,
                extra: "cvv textfield",
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
                extra: "cvv textfield",
                objectType: .textField,
                objectId: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        if !(newText.isNumeric || newText.isEmpty) { return false }
        if string != "" && newText.withoutWhiteSpace.count >= 5 { return false }
        
        switch self.isValid?(newText) {
        case true:
            validation = .valid
        case false:
            validation = .invalid(PrimerError.invalidCVV)
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
        return false
    }
    
}

#endif
