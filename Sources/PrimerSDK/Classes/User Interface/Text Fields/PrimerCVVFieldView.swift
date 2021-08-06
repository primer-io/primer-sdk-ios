//
//  PrimerCVVFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/21.
//

import UIKit

public final class PrimerCVVFieldView: PrimerTextFieldView {
    
    internal var cvv: String {
        return textField._text ?? ""
    }
    public var cardNetwork: CardNetwork = .unknown
    
    override func xibSetup() {
        super.xibSetup()
        
        textField.delegate = self
        isValid = { [weak self] text in
            guard let strongSelf = self else { return nil }
            return text.isTypingValidCVV(cardNetwork: strongSelf.cardNetwork)
        }
    }
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        if !(newText.isNumeric || newText.isEmpty) { return false }
        
        let maxDigits = cardNetwork.validation?.code.length ?? 4
        if string != "" && newText.withoutNonNumericCharacters.count > maxDigits { return false }
        
        switch self.isValid?(newText) {
        case true:
            validation = .valid
        case false:
            validation = .invalid(NSError(domain: "primer", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid value."]))
        default:
            validation = .notAvailable
        }
        
        primerTextField._text = newText
        primerTextField.text = newText
        return false
    }
    
}
