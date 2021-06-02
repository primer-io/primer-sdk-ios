//
//  PrimerCardNumberField.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 1/6/21.
//

import UIKit

public final class PrimerCardNumberField: PrimerPCITextField {
    
    private(set) public var cardScheme: CardScheme = .unknown {
        didSet {
            cardIconView.image = cardScheme.icon
            
            switch cardScheme {
            case .amex:
                cardIconContainerView.isHidden = false
            case .diners:
                cardIconContainerView.isHidden = false
            case .discover:
                cardIconContainerView.isHidden = false
            case .jcb:
                cardIconContainerView.isHidden = false
            case .maestro:
                cardIconContainerView.isHidden = false
            case .masterCard:
                cardIconContainerView.isHidden = false
            case .visa:
                cardIconContainerView.isHidden = false
            case .invalid:
                cardIconContainerView.isHidden = false
            case .bancontact:
                cardIconContainerView.isHidden = false
            case .unknown:
                cardIconView.image = nil
                cardIconContainerView.isHidden = true
            }
        }
    }
    
    private var isCardIconHidden: Bool = false {
        didSet {
            cardIconView.isHidden = isCardIconHidden
        }
    }
    
    override func xibSetup() {
        super.xibSetup()
        
        primerTextField.keyboardType = .numberPad
        
        self.isValid = { text in
            return text.isValidCardnumber
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        if string != "" && currentText.withoutWhiteSpace.count == 19 { return false }
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
        primerTextField._text = newText
        cardScheme = CardScheme(account: primerTextField._text ?? "")
        validation = .empty
        primerTextField.text = newText.withoutWhiteSpace.separate(every: 4, with: " ")
        return false
    }
    
}
