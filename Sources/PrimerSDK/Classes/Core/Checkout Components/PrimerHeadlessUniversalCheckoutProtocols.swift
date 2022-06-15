//
//  CheckoutComponents.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

#if canImport(UIKit)

import Foundation
import UIKit

@objc
public enum PrimerInputElementType: Int {
    case cardNumber, expiryDate, cvv, cardholderName, otp, postalCode, unknown
    
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
            
        case .postalCode:
            guard let text = value as? String else { return false }
            return text.isValidPostalCode

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
        case .postalCode:
            return 10
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
    
    internal var keyboardType: UIKeyboardType {
        switch self {
        case .cardNumber:
            return UIKeyboardType.numberPad
            
        case .expiryDate:
            return UIKeyboardType.numberPad
            
        case .cvv:
            return UIKeyboardType.numberPad
            
        case .cardholderName:
            return UIKeyboardType.alphabet
            
        case .otp:
            return UIKeyboardType.numberPad
            
        case .postalCode:
            return UIKeyboardType.alphabet

        default:
            return UIKeyboardType.default
        }
    }
}

@objc
public protocol PrimerInputElement {
    var inputElementDelegate: PrimerInputElementDelegate! { get set }
    var type: PrimerInputElementType { get set }
    var isValid: Bool { get }
}

@objc
public protocol PrimerInputElementDelegate: AnyObject {
    
    @objc optional func inputElementShouldFocus(_ sender: PrimerInputElement) -> Bool
    @objc optional func inputElementDidFocus(_ sender: PrimerInputElement)
    @objc optional func inputElementShouldBlur(_ sender: PrimerInputElement) -> Bool
    @objc optional func inputElementDidBlur(_ sender: PrimerInputElement)
    @objc optional func inputElementValueDidChange(_ sender: PrimerInputElement)
    @objc optional func inputElementValueIsValid(_ sender: PrimerInputElement, isValid: Bool)
    @objc optional func inputElementDidDetectType(_ sender: PrimerInputElement, type: Any?)
}

@objc
public protocol PrimerHeadlessUniversalCheckoutDelegate {
    
    @objc func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethodTypes: [String])
    @objc optional func primerHeadlessUniversalCheckoutPreparationStarted(paymentMethodType: String)
    @objc optional func primerHeadlessUniversalCheckoutTokenizationStarted(paymentMethodType: String)
    @objc optional func primerHeadlessUniversalCheckoutPaymentMethodShowed(paymentMethodType: String)
    @objc optional func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void)
    @objc optional func primerHeadlessUniversalDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void)
    @objc optional func primerHeadlessUniversalCheckoutDidFail(withError err: Error)
    
    
    
    @objc func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData)
    @objc optional func primerClientSessionWillUpdate()
    @objc optional func primerClientSessionDidUpdate(_ clientSession: PrimerClientSession)
    @objc optional func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void)
}

#endif
