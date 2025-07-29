//
//  PrimerValidationError.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length
// swiftlint:disable file_length
// swiftlint:disable identifier_name
// swiftlint:disable function_body_length

import Foundation

public enum PrimerValidationError: PrimerErrorProtocol, Encodable {
    case invalidCardholderName(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidCardnumber(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidCvv(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidExpiryDate(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidPostalCode(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidFirstName(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidLastName(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidAddress(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidCity(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidState(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidCountry(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidPhoneNumber(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidRetailer(
        message: String,
        userInfo: [String: String]?,
        diagnosticsId: String
    )
    case invalidRawData(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case vaultedPaymentMethodAdditionalDataMismatch(
        paymentMethodType: String,
        validVaultedPaymentMethodAdditionalDataType: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidOTPCode(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidCardType(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case banksNotLoaded(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidBankId(
        bankId: String?,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case sessionNotCreated(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidPaymentCategory(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case paymentAlreadyFinalized(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidUserDetails(
        field: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )

    public var diagnosticsId: String {
        switch self {
        case let .invalidCardholderName(_, _, diagnosticsId): diagnosticsId
        case let .invalidCardnumber(_, _, diagnosticsId): diagnosticsId
        case let .invalidCvv(_, _, diagnosticsId): diagnosticsId
        case let .invalidExpiryDate(_, _, diagnosticsId): diagnosticsId
        case let .invalidPostalCode(_, _, diagnosticsId): diagnosticsId
        case let .invalidFirstName(_, _, diagnosticsId): diagnosticsId
        case let .invalidLastName(_, _, diagnosticsId): diagnosticsId
        case let .invalidAddress(_, _, diagnosticsId): diagnosticsId
        case let .invalidCity(_, _, diagnosticsId): diagnosticsId
        case let .invalidState(_, _, diagnosticsId): diagnosticsId
        case let .invalidCountry(_, _, diagnosticsId): diagnosticsId
        case let .invalidPhoneNumber(_, _, diagnosticsId): diagnosticsId
        case .invalidRetailer(_, _, let diagnosticsId): diagnosticsId
        case let .invalidRawData(_, diagnosticsId): diagnosticsId
        case let .vaultedPaymentMethodAdditionalDataMismatch(_, _, _, diagnosticsId): diagnosticsId
        case let .invalidOTPCode(_, _, diagnosticsId): diagnosticsId
        case let .invalidCardType(_, _, diagnosticsId): diagnosticsId
        case .banksNotLoaded(userInfo: _, let diagnosticId): diagnosticId
        case .invalidBankId(bankId: _, userInfo: _, let diagnosticId): diagnosticId
        case .sessionNotCreated(userInfo: _, diagnosticsId: let diagnosticsId): diagnosticsId
        case .invalidPaymentCategory(userInfo: _, diagnosticsId: let diagnosticsId): diagnosticsId
        case .paymentAlreadyFinalized(userInfo: _, diagnosticsId: let diagnosticsId): diagnosticsId
        case let .invalidUserDetails(_, _, diagnosticsId): diagnosticsId
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
        case .invalidUserDetails(let field, _, _):
            return "invalid-customer-\(field)"
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
        case .invalidUserDetails(let field, _, _):
            return "The \(field) is not valid."
        }
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
        case .invalidUserDetails:
            return "USER_DETAILS"
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
