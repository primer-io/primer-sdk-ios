//
//  CheckoutComponents.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

import Foundation

@objc
public enum PrimerInputElementType: Int {
    case cardNumber, expiryDate, cvv, cardholderName, otp, unknown
    
    internal func validate(value: Any, detectedValueType: Any?) -> Bool {
        switch self {
        case .cardNumber:
            guard let text = value as? String else { return false }
            return text.isValidCardNumber
            
        case .expiryDate:
            guard let text = value as? String else { return false }
            return text.isValidExpiryDate
            
        case .cvv:
            guard let text = value as? String else { return false }
            if let cardNetwork = detectedValueType as? CardNetwork, cardNetwork != .unknown {
                return text.isValidCVV(cardNetwork: cardNetwork)
            } else {
                return text.count >= 3 && text.count <= 5
            }
            
        case .cardholderName:
            guard let text = value as? String else { return false }
            return text.isValidCardholderName
            
        case .otp:
            guard let text = value as? String else { return false }
            return text.isNumeric

        default:
            return true
        }
    }
    
    internal func format(value: Any) -> Any {
        switch self {
        case .cardNumber:
            guard let text = value as? String else { return value }
            return text.withoutWhiteSpace.separate(every: 4, with: self.delimiter!)
            
        case .expiryDate:
            guard let text = value as? String else { return value }
            return text.withoutWhiteSpace.separate(every: 2, with: self.delimiter!)
            
        default:
            return value
        }
    }
    
    internal func clearFormatting(value: Any) -> Any? {
        switch self {
        case .cardNumber,
                .expiryDate:
            guard let text = value as? String else { return nil }
            let textWithoutWhiteSpace = text.withoutWhiteSpace
            return textWithoutWhiteSpace.replacingOccurrences(of: self.delimiter!, with: "")
            
        default:
            return value
        }
    }
    
    internal func detectType(for value: Any) -> Any? {
        switch self {
        case .cardNumber:
            guard let text = value as? String else { return nil }
            return CardNetwork(cardNumber: text)
            
        default:
            return value
        }
    }
    
    internal var delimiter: String? {
        switch self {
        case .cardNumber:
            return " "
        case .expiryDate:
            return "/"
        default:
            return nil
        }
    }
    
    internal var maxAllowedLength: Int? {
        switch self {
        case .cardNumber:
            return nil
        case .expiryDate:
            return 4
        case .cvv:
            return nil
        default:
            return nil
        }
    }
    
    internal var allowedCharacterSet: CharacterSet? {
        switch self {
        case .cardNumber:
            return CharacterSet(charactersIn: "0123456789")
            
        case .expiryDate:
            return CharacterSet(charactersIn: "0123456789")
            
        case .cvv:
            return CharacterSet(charactersIn: "0123456789")
            
        case .cardholderName:
            return CharacterSet.letters
            
        case .otp:
            return CharacterSet(charactersIn: "0123456789")

        default:
            return nil
        }
    }
    
    internal var keyboardType: UIKeyboardType? {
        return nil
    }
}

@objc
public protocol PrimerInputElement {
    var inputElementDelegate: PrimerInputElementDelegate! { get set }
    var type: PrimerInputElementType { get set }
    var isValid: Bool { get }
}

@objc
public protocol PrimerInputElementDelegate {
    @objc optional func inputElementShouldFocus(_ sender: PrimerInputElement) -> Bool
    @objc optional func inputElementDidFocus(_ sender: PrimerInputElement)
    @objc optional func inputElementShouldBlur(_ sender: PrimerInputElement) -> Bool
    @objc optional func inputElementDidBlur(_ sender: PrimerInputElement)
    @objc optional func inputElementValueDidChange(_ sender: PrimerInputElement)
    @objc optional func inputElementValueIsValid(_ sender: PrimerInputElement, isValid: Bool)
    
    @objc optional func inputElementDidDetectType(_ sender: PrimerInputElement, type: Any?)
}

public protocol PrimerPaymentMethodViewControllerProtocol where Self: UIViewController {
    var paymentMethodType: PaymentMethodConfigType! { get set }
    var inputElements: [PrimerInputElement] { get set }
    var paymentButton: UIButton! { get set }
}

public protocol PrimerCheckoutComponentsDelegate {
    func onEvent(_ event: PrimerCheckoutComponentsEvent)
}

public enum PrimerCheckoutComponentsEvent {
    case configurationStarted
    case paymentMethodPresented
    case tokenizationStarted
    case tokenizationSuccess(paymentMethodToken: PaymentMethodToken, resumeHandler: ResumeHandlerProtocol?)
    case error(err: Error)
}
