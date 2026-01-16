//
//  PrimerHeadlessUniversalCheckoutInputElement.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
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

    func validate(value: Any, detectedValueType: Any?) -> Bool {
        switch self {
        case .cardNumber:
			return (value as? String)?.isValidCardNumber ?? false
		case .expiryDate:
			return (value as? String)?.isValidExpiryDate ?? false
		case .cardholderName:
			return (value as? String)?.isValidNonDecimalString ?? false
		case .otp:
			return (value as? String)?.isNumeric ?? false
		case .postalCode:
			return (value as? String)?.isValidPostalCode ?? false
		case .phoneNumber:
			return (value as? String)?.isNumeric ?? false
		case .cvv:
			guard let text = value as? String else { return false }
			if let cardNetwork = detectedValueType as? CardNetwork, cardNetwork != .unknown {
				return text.isValidCVV(cardNetwork: cardNetwork)
			} else {
				return text.count >= 3 && text.count <= 5
			}
        default:
            return true
        }
    }

    func format(value: Any) -> Any {
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

    func clearFormatting(value: Any) -> Any? {
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

    func detectType(for value: Any) -> Any? {
        switch self {
        case .cardNumber:
            guard let text = value as? String else { return nil }
            return CardNetwork(cardNumber: text)

        default:
            return value
        }
    }

    var delimiter: String? {
        switch self {
        case .cardNumber:
            return " "
        case .expiryDate:
            return "/"
        default:
            return nil
        }
    }

    var maxAllowedLength: Int? {
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

    var allowedCharacterSet: CharacterSet? {
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

    var keyboardType: UIKeyboardType {
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
