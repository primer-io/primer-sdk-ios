//
//  PrimerValidationError.swift
//  PrimerSDK
//
//  Created by Boris on 19.9.23..
//

import Foundation

public enum PrimerValidationError: PrimerErrorProtocol, Encodable {

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
    case invalidPhoneNumberCountryCode(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidRetailer(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidRawData(userInfo: [String: String]?, diagnosticsId: String)
    case vaultedPaymentMethodAdditionalDataMismatch(paymentMethodType: String, validVaultedPaymentMethodAdditionalDataType: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidOTPCode(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case banksNotLoaded(userInfo: [String: String]?, diagnosticsId: String)
    case invalidBankId(bankId: String?, userInfo: [String: String]?, diagnosticsId: String)

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
        case .invalidPhoneNumberCountryCode(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidOTPCode(_, _, let diagnosticsId):
            return diagnosticsId
        case .banksNotLoaded(userInfo: _, let diagnosticId):
            return diagnosticId
        case .invalidBankId(bankId: _, userInfo: _, let diagnosticId):
            return diagnosticId
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
        case .invalidPhoneNumberCountryCode:
            return "invalid-phone-number-country-code"
        case .invalidOTPCode:
            return "invalid-otp-code"
        case .invalidBankId:
            return "invalid-bank-id"
        case .banksNotLoaded:
            return "banks-not-loaded"
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
        case .invalidPhoneNumberCountryCode(message: let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidOTPCode(message: let message, _, _):
            return "[\(errorId)] \(message)"
        case .invalidBankId:
            return "Please provide a valid bank id"
        case .banksNotLoaded:
            return "Banks need to be loaded before bank id can be collected."
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
                .vaultedPaymentMethodAdditionalDataMismatch(_, _, let userInfo, _),
                .invalidPhoneNumberCountryCode(_, let userInfo, _),
                .invalidOTPCode(_, let userInfo, _),
                .invalidBankId(_, let userInfo, _),
                .banksNotLoaded(let userInfo, _):
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
        case .invalidPhoneNumberCountryCode:
            return "PHONE_NUMBER_COUNTRY_CODE"
        case .invalidOTPCode:
            return "OTP"
        case .banksNotLoaded:
            return "BANKS"
        case .invalidBankId:
            return "BANK"
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

extension PrimerValidationError: Equatable {
    public static func == (lhs: PrimerValidationError, rhs: PrimerValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCardholderName(let message1, let userInfo1, let id1), .invalidCardholderName(let message2, let userInfo2, let id2)),
            (.invalidCardnumber(let message1, let userInfo1, let id1), .invalidCardnumber(let message2, let userInfo2, let id2)),
            (.invalidCvv(let message1, let userInfo1, let id1), .invalidCvv(let message2, let userInfo2, let id2)),
            (.invalidExpiryMonth(let message1, let userInfo1, let id1), .invalidExpiryMonth(let message2, let userInfo2, let id2)),
            (.invalidExpiryYear(let message1, let userInfo1, let id1), .invalidExpiryYear(let message2, let userInfo2, let id2)),
            (.invalidExpiryDate(let message1, let userInfo1, let id1), .invalidExpiryDate(let message2, let userInfo2, let id2)),
            (.invalidPostalCode(let message1, let userInfo1, let id1), .invalidPostalCode(let message2, let userInfo2, let id2)),
            (.invalidFirstName(let message1, let userInfo1, let id1), .invalidFirstName(let message2, let userInfo2, let id2)),
            (.invalidLastName(let message1, let userInfo1, let id1), .invalidLastName(let message2, let userInfo2, let id2)),
            (.invalidAddress(let message1, let userInfo1, let id1), .invalidAddress(let message2, let userInfo2, let id2)),
            (.invalidState(let message1, let userInfo1, let id1), .invalidState(let message2, let userInfo2, let id2)),
            (.invalidCountry(let message1, let userInfo1, let id1), .invalidCountry(let message2, let userInfo2, let id2)),
            (.invalidPhoneNumber(let message1, let userInfo1, let id1), .invalidPhoneNumber(let message2, let userInfo2, let id2)),
            (.invalidPhoneNumberCountryCode(let message1, let userInfo1, let id1), .invalidPhoneNumberCountryCode(let message2, let userInfo2, let id2)),
            (.invalidRetailer(let message1, let userInfo1, let id1), .invalidRetailer(let message2, let userInfo2, let id2)),
            (.invalidOTPCode(let message1, let userInfo1, let id1), .invalidOTPCode(let message2, let userInfo2, let id2)):
            return message1 == message2 && userInfo1 == userInfo2 && id1 == id2
        case (.invalidRawData(let userInfo1, let id1), .invalidRawData(let userInfo2, let id2)),
            (.banksNotLoaded(let userInfo1, let id1), .banksNotLoaded(let userInfo2, let id2)):
            return userInfo1 == userInfo2 && id1 == id2
        case (.vaultedPaymentMethodAdditionalDataMismatch(let type1, let validType1, let userInfo1, let id1),
              .vaultedPaymentMethodAdditionalDataMismatch(let type2, let validType2, let userInfo2, let id2)):
            return type1 == type2 && validType1 == validType2 && userInfo1 == userInfo2 && id1 == id2
        case (.invalidBankId(let bankId1, userInfo: let userInfo1, diagnosticsId: let id1), .invalidBankId(let bankId2, userInfo: let userInfo2, diagnosticsId: let id2)):
            return bankId1 == bankId2 && userInfo1 == userInfo2 && id1 == id2
        default:
            return false
        }
    }
}
