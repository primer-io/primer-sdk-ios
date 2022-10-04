//
//  PrimerHeadlessUniversalCheckoutProtocols.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//


#if canImport(UIKit)

import Foundation
import UIKit

@objc
public enum PrimerInputElementType: Int {
    
    case cardNumber
    case expiryDate
    case cvv
    case cardholderName
    case otp
    case postalCode
    case phoneNumber
    case retailer
    case unknown
    
    public var stringValue: String {
        switch self {
        case .cardNumber:
            return "CARD_NUMBER"
        case .expiryDate:
            return "EXPIRY_DATE"
        case .cvv:
            return "CVV"
        case .cardholderName:
            return "CARDHOLDER_NAME"
        case .otp:
            return "OTP"
        case .postalCode:
            return "POSTAL_CODE"
        case .phoneNumber:
            return "PHONE_NUMBER"
        case .retailer:
            return "RETAILER"
        case .unknown:
            return "UNKNOWN"
        }
    }
    
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
            
        case .phoneNumber:
            guard let text = value as? String else { return false }
            return text.isNumeric
        
        case .retailer:
            guard let text = value as? String else { return false }
            return !text.isEmpty
            
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
        case .cardNumber,
                .expiryDate,
                .cvv,
                .otp,
                .phoneNumber:
            return CharacterSet(charactersIn: "0123456789")
            
        case .cardholderName:
            return CharacterSet.letters.union(.whitespaces)
            
        default:
            return nil
        }
    }
    
    internal var keyboardType: UIKeyboardType {
        switch self {
        case .cardNumber,
                .expiryDate,
                .cvv,
                .otp,
                .phoneNumber:
            return UIKeyboardType.numberPad
            
            
        case .cardholderName,
                .postalCode:
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
public protocol PrimerUIEventsDelegate {
    
    @objc optional func primerHeadlessUniversalCheckoutPreparationDidStart(for paymentMethodType: String)
    @objc optional func primerHeadlessUniversalCheckoutPaymentMethodDidShow(for paymentMethodType: String)
}

@objc
public protocol PrimerCheckoutEventsDelegate {
    
    @objc func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckoutPaymentMethod])
    @objc optional func primerHeadlessUniversalCheckoutTokenizationDidStart(for paymentMethodType: String)
    @objc optional func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void)
    @objc optional func primerHeadlessUniversalCheckoutDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void)
    @objc optional func primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)
    @objc optional func primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)
    @objc optional func primerHeadlessUniversalCheckoutDidFail(withError err: Error)
    @objc func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData)
    @objc optional func primerHeadlessUniversalCheckoutClientSessionWillUpdate()
    @objc optional func primerHeadlessUniversalCheckoutClientSessionDidUpdate(_ clientSession: PrimerClientSession)
    @objc optional func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void)
}

#endif
