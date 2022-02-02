//
//  PRTextField.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

#if canImport(UIKit)

import UIKit

public class PrimerCheckoutComponents {
    
    public static func listAvailablePaymentMethods(forSession clientToken: String, completion: @escaping ([PaymentMethodConfigType]?, Error?) -> Void) {
        do {
            try ClientTokenService.storeClientToken(clientToken)
        } catch {
            completion(nil, error)
        }
        
        let primerConfigurationService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
        firstly {
            primerConfigurationService.fetchConfig()
        }
        .done {
            let availablePaymentMethodTypes = PrimerConfiguration.paymentMethodConfigs?.compactMap({ $0.type })
            completion(availablePaymentMethodTypes, nil)
        }
        .catch { err in
            completion(nil, err)
        }
    }
    
    public static func listInputElementTypes(for paymentMethodType: PaymentMethodConfigType) -> [PrimerInputElementType] {
        switch paymentMethodType {
        case .adyenAlipay:
            return []
        case .adyenDotPay:
            return []
        case .adyenGiropay:
            return []
        case .adyenIDeal:
            return []
        case .adyenMobilePay:
            return []
        case .adyenSofort:
            return []
        case .adyenTrustly:
            return []
        case .adyenTwint:
            return []
        case .adyenVipps:
            return []
        case .apaya:
            return []
        case .applePay:
            return []
        case .atome:
            return []
        case .buckarooBancontact:
            return []
        case .buckarooEps:
            return []
        case .buckarooGiropay:
            return []
        case .buckarooIdeal:
            return []
        case .buckarooSofort:
            return []
        case .goCardlessMandate:
            return []
        case .googlePay:
            return []
        case .hoolah:
            return []
        case .klarna:
            return []
        case .mollieBankcontact:
            return []
        case .mollieIdeal:
            return []
        case .payNLBancontact:
            return []
        case .payNLGiropay:
            return []
        case .payNLIdeal:
            return []
        case .payNLPayconiq:
            return []
        case .paymentCard:
            return [.cardNumber, .expiryDate, .cvv, .cardholderName]
        case .payPal:
            return []
        case .xfers:
            return []
        case .other(let rawValue):
            return []
        }
    }
    
}

extension PrimerCheckoutComponents {
    internal class Delegate: NSObject, UITextFieldDelegate {
        
        private var inputElement: PrimerInputElement
        private var inputElementDelegate: PrimerInputElementDelegate
        private var detectedType: Any?
        
        init(inputElement: PrimerInputElement, inputElementDelegate: PrimerInputElementDelegate) {
            self.inputElement = inputElement
            self.inputElementDelegate = inputElementDelegate
        }
        
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            guard let inputElementShouldFocus = self.inputElementDelegate.inputElementShouldFocus?(self.inputElement) else { return true }
            return inputElementShouldFocus
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            self.inputElementDelegate.inputElementDidFocus?(self.inputElement)
        }
        
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            guard let inputElementShouldBlur = self.inputElementDelegate.inputElementShouldBlur?(self.inputElement) else { return true }
            return inputElementShouldBlur
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            self.inputElementDelegate.inputElementDidBlur?(self.inputElement)
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let primerCheckoutComponentsTextField = textField as? PrimerCheckoutComponents.TextField else { return false }
            if !string.isEmpty {
                // Characters aren't in the allowed character set
                if let allowedCharacterSet = self.inputElement.type.allowedCharacterSet, string.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                    return false
                }
            }
            
            let currentText = primerCheckoutComponentsTextField._text ?? ""
            
            var newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
            if let deformattedText = self.inputElement.type.clearFormatting(value: newText) as? String {
                newText = deformattedText
            }
            
            if let maxAllowedLength = self.inputElement.type.maxAllowedLength {
                if newText.count > maxAllowedLength {
                    return false
                }
            }
            
//            DispatchQueue.global(qos: .userInitiated).async {
//            DispatchQueue.main.async {
            
            if self.inputElement.type == .cardNumber {
                if let cardNetwork = self.inputElement.type.detectType(for: newText) as? CardNetwork {
                    if self.detectedType == nil, cardNetwork != .unknown {
                        self.detectedType = cardNetwork
                        self.inputElementDelegate.inputElementDidDetectType?(self.inputElement, type: self.detectedType)
                    } else if self.detectedType != nil, cardNetwork == .unknown {
                        self.detectedType = nil
                        self.inputElementDelegate.inputElementDidDetectType?(self.inputElement, type: self.detectedType)
                    }
                } else {
                    if self.detectedType != nil {
                        self.detectedType = nil
                        self.inputElementDelegate.inputElementDidDetectType?(self.inputElement, type: self.detectedType)
                    }
                }
            }
            
            if let cardNetwork = self.detectedType as? CardNetwork {
                if self.inputElement.type == .cardNumber,
                   let cardNetworkMaxAllowedLength = cardNetwork.validation?.lengths.max(),
                   newText.count > cardNetworkMaxAllowedLength {
                    return false
                }
                
            } else if let cardNetwork = primerCheckoutComponentsTextField.detectedValueType as? CardNetwork {
                if self.inputElement.type == .cvv {
                    if let cvvMaxAllowedLength = cardNetwork.validation?.code.length,
                       newText.count > cvvMaxAllowedLength {
                        return false
                    }
                }
            }
            
            let isValid = self.inputElement.type.validate(value: newText, detectedValueType: primerCheckoutComponentsTextField.detectedValueType)
            self.inputElementDelegate.inputElementValueIsValid?(self.inputElement, isValid: isValid)
            
            let formattedText = self.inputElement.type.format(value: newText)
            textField.text = formattedText as? String
            
            return false
        }
    }
}

#endif
