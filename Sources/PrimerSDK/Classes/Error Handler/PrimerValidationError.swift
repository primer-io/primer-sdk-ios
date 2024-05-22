//
//  PrimerValidationError.swift
//  PrimerSDK
//
//  Created by Boris on 19.9.23..
//

// swiftlint:disable type_body_length
// swiftlint:disable file_length
// swiftlint:disable identifier_name
// swiftlint:disable function_body_length

import Foundation

public enum PrimerValidationError: PrimerErrorProtocol, Encodable {

    case invalidCardholderName(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidCardnumber(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidCvv(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidExpiryDate(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidPostalCode(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidFirstName(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidLastName(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidAddress(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidCity(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidState(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidCountry(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidPhoneNumber(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidRetailer(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidRawData(userInfo: [String: String]?, diagnosticsId: String)
    case vaultedPaymentMethodAdditionalDataMismatch(paymentMethodType: String,
                                                    validVaultedPaymentMethodAdditionalDataType: String,
                                                    userInfo: [String: String]?,
                                                    diagnosticsId: String)
    case invalidOTPCode(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidCardType(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case banksNotLoaded(userInfo: [String: String]?, diagnosticsId: String)
    case invalidBankId(bankId: String?, userInfo: [String: String]?, diagnosticsId: String)
    case sessionNotCreated(userInfo: [String: String]?, diagnosticsId: String)
    case invalidPaymentCategory(userInfo: [String: String]?, diagnosticsId: String)
    case paymentAlreadyFinalized(userInfo: [String: String]?, diagnosticsId: String)
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
        case .invalidCity(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidState(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidCountry(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidPhoneNumber(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidRawData(_, let diagnosticsId):
            return diagnosticsId
        case .invalidRetailer(_, _, let diagnosticsId):
            return diagnosticsId
        case .vaultedPaymentMethodAdditionalDataMismatch(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidOTPCode(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidCardType(_, _, let diagnosticsId):
            return diagnosticsId
        case .banksNotLoaded(userInfo: _, let diagnosticId):
            return diagnosticId
        case .invalidBankId(bankId: _, userInfo: _, let diagnosticId):
            return diagnosticId
        case .sessionNotCreated(userInfo: _, diagnosticsId: let diagnosticsId):
            return diagnosticsId
        case .invalidPaymentCategory(userInfo: _, diagnosticsId: let diagnosticsId):
            return diagnosticsId
        case .paymentAlreadyFinalized(userInfo: _, diagnosticsId: let diagnosticsId):
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
        case .invalidCity:
            return "invalid-city"
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
        case .invalidOTPCode:
            return "invalid-otp-code"
        case .invalidCardType:
            return "unsupported-card-type"
        case .invalidBankId:
            return "invalid-bank-id"
        case .banksNotLoaded:
            return "banks-not-loaded"
        case .sessionNotCreated:
            return "session-not-created"
        case .invalidPaymentCategory:
            return "invalid-payment-category"
        case .paymentAlreadyFinalized:
            return "payment-already-finalized"
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
        case .invalidCity(let message, _, _):
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
        case .invalidOTPCode(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidCardType(let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidBankId:
            return "Please provide a valid bank id"
        case .banksNotLoaded:
            return "Banks need to be loaded before bank id can be collected."
        case .sessionNotCreated:
            return "Session needs to be created before payment category can be collected."
        case .invalidPaymentCategory:
            return "Payment category is invalid."
        case .paymentAlreadyFinalized:
            return "This payment was configured to be finalized automatically."
        }
    }

    var info: [String: Any]? {
        var tmpUserInfo: [String: Any] = errorUserInfo

        switch self {
        case .invalidCardholderName(_, let userInfo, _),
             .invalidCardnumber(_, let userInfo, _),
             .invalidCvv(_, let userInfo, _),
             .invalidExpiryDate(_, let userInfo, _),
             .invalidPostalCode(_, let userInfo, _),
             .invalidFirstName(_, let userInfo, _),
             .invalidLastName(_, let userInfo, _),
             .invalidAddress(_, let userInfo, _),
             .invalidCity(_, let userInfo, _),
             .invalidState(_, let userInfo, _),
             .invalidCountry(_, let userInfo, _),
             .invalidPhoneNumber(_, let userInfo, _),
             .invalidRawData(let userInfo, _),
             .invalidRetailer(_, let userInfo, _),
             .vaultedPaymentMethodAdditionalDataMismatch(_, _, let userInfo, _),
             .invalidOTPCode(_, let userInfo, _),
             .invalidCardType(_, let userInfo, _),
             .invalidBankId(_, let userInfo, _),
             .banksNotLoaded(let userInfo, _),
             .sessionNotCreated(let userInfo, _),
             .invalidPaymentCategory(let userInfo, _),
             .paymentAlreadyFinalized(let userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
        }

        return tmpUserInfo
    }

    public var errorUserInfo: [String: Any] {
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
        case .invalidExpiryDate:
            return "EXPIRY_DATE"
        case .invalidPhoneNumber:
            return "PHONE_NUMBER"
        case .invalidRetailer:
            return "RETAILER"
        case .invalidOTPCode:
            return "OTP"
        case .invalidCardType:
            return "CARD_NUMBER"
        case .banksNotLoaded:
            return "BANKS"
        case .invalidBankId:
            return "BANK"
        default:
            return nil
        }
    }

    var analyticsContext: [String: Any] {
        var context: [String: Any] = [:]
        context[AnalyticsContextKeys.errorId] = errorId
        if let paymentMethodType = paymentMethodType {
            context[AnalyticsContextKeys.paymentMethodType] = paymentMethodType
        }
        return context
    }

    private var paymentMethodType: String? {
        switch self {
        case .vaultedPaymentMethodAdditionalDataMismatch(let paymentMethodType, _, _, _):
            return paymentMethodType
        default: return nil
        }
    }
}
// swiftlint:enable type_body_length
// swiftlint:enable identifier_name
// swiftlint:enable function_body_length
// swiftlint:enable file_length
