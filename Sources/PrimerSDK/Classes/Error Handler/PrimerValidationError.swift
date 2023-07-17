//
//  PrimerValidationError.swift
//  PrimerSDK
//
//  Created by Boris on 18.7.23..
//

#if canImport(UIKit)

import Foundation
import UIKit

public enum PrimerValidationError: PrimerErrorProtocol {
    
    case invalidCardholderName(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidCardnumber(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidCvv(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidExpiryMonth(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidExpiryYear(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidExpiryDate(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidPostalCode(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidFirstName(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidLastName(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidAddress(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidState(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidCountry(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidPhoneNumber(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidRetailer(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidRawData(userInfo: [String: String]?, diagnosticsId: String)
    case vaultedPaymentMethodAdditionalDataMismatch(paymentMethodType: String, validVaultedPaymentMethodAdditionalDataType: String, userInfo: [String: String]?, diagnosticsId: String)
    
    public var diagnosticsId: String {
        switch self {
        case .invalidCardholderName(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidCardnumber(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidCvv(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidExpiryDate(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidPostalCode(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidFirstName(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidLastName(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidAddress(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidState(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidCountry(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidPhoneNumber(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidRawData(_, let diagnosticsId):
            return diagnosticsId
        case .invalidExpiryMonth(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidExpiryYear(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidRetailer(_, _, let diagnosticsId):
            return diagnosticsId
        case .vaultedPaymentMethodAdditionalDataMismatch(_, _, _, let diagnosticsId):
            return diagnosticsId
        }
    }

    public var errorId: String {
        switch self {
        case .invalidCardholderName:
            return "invalid-cardholder-name"
        case .invalidCardnumber:
            return "invalid-card-number"
        case .invalidCvv:
            return "invalid-cvv"
        case .invalidExpiryMonth:
            return "invalid-expiry-month"
        case .invalidExpiryYear:
            return "invalid-expiry-year"
        case .invalidExpiryDate:
            return "invalid-expiry-date"
        case .invalidPostalCode:
            return "invalid-postal-code"
        case .invalidFirstName:
            return "invalid-first-name"
        case .invalidLastName:
            return "invalid-last-name"
        case .invalidAddress:
            return "invalid-address"
        case .invalidState:
            return "invalid-state"
        case .invalidCountry:
            return "invalid-country"
        case .invalidPhoneNumber:
            return "invalid-phone-number"
        case .invalidRawData:
            return "invalid-raw-data"
        case .invalidRetailer:
            return "invalid-retailer"
        case .vaultedPaymentMethodAdditionalDataMismatch:
            return "vaulted-payment-method-additional-data-mismatch"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidCardholderName(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidCardnumber(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidCvv(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidExpiryMonth(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidExpiryYear(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidExpiryDate(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidPostalCode(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidFirstName(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidLastName(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidAddress(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidState(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidCountry(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidPhoneNumber(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidRawData:
            return "[\(errorId)] Raw data is not valid."
        case .invalidRetailer(let message, _, _):
            return "[\(errorId)] \(message)"
        case .vaultedPaymentMethodAdditionalDataMismatch(let paymentMethodType, let validVaultedPaymentMethodAdditionalDataType, _, _):
            return "[\(errorId)] Vaulted payment method \(paymentMethodType) needs additional data of type \(validVaultedPaymentMethodAdditionalDataType)"
        }
    }
    
    var info: [String: Any]? {
        var tmpUserInfo: [String: Any] = errorUserInfo

        switch self {
        case .invalidCardholderName(_, let userInfo, _),
                .invalidCardnumber(_, let userInfo, _),
                .invalidCvv(_, let userInfo, _),
                .invalidExpiryMonth(_, let userInfo, _),
                .invalidExpiryYear(_, let userInfo, _),
                .invalidExpiryDate(_, let userInfo, _),
                .invalidPostalCode(_, let userInfo, _),
                .invalidFirstName(_, let userInfo, _),
                .invalidLastName(_, let userInfo, _),
                .invalidAddress(_, let userInfo, _),
                .invalidState(_, let userInfo, _),
                .invalidCountry(_, let userInfo, _),
                .invalidPhoneNumber(_, let userInfo, _),
                .invalidRawData(let userInfo, _),
                .invalidRetailer(_, let userInfo, _),
                .vaultedPaymentMethodAdditionalDataMismatch(_, _, let userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
        }

        return tmpUserInfo
    }
    
    public var errorUserInfo: [String : Any] {
        var tmpUserInfo: [String: Any] = [
            "createdAt": Date().toString(),
            "diagnosticsId": diagnosticsId
        ]
        
        if let inputElementType {
            tmpUserInfo["inputElementType"] = inputElementType
        }
        
        return tmpUserInfo
    }
    
    public var recoverySuggestion: String? {
        return nil
    }
    
    var exposedError: Error {
        return self
    }
    
    var inputElementType: String? {
        switch self {
        case .invalidCardholderName:
            return "CARDHOLDER_NAME"
        case .invalidCardnumber:
            return "CARD_NUMBER"
        case .invalidCvv:
            return "CVV"
        case .invalidExpiryMonth:
            return "EXPIRY_MONTH"
        case .invalidExpiryYear:
            return "EXPIRY_YEAR"
        case .invalidExpiryDate:
            return "EXPIRY_DATE"
        case .invalidPostalCode:
            return nil
        case .invalidFirstName:
            return nil
        case .invalidLastName:
            return nil
        case .invalidAddress:
            return nil
        case .invalidState:
            return nil
        case .invalidCountry:
            return nil
        case .invalidPhoneNumber:
            return "PHONE_NUMBER"
        case .invalidRetailer:
            return "RETAILER"
        case .invalidRawData:
            return nil
        case .vaultedPaymentMethodAdditionalDataMismatch:
            return nil
        }
    }
}

#endif
