//
//  PrimerValidationError.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public enum PrimerValidationError: PrimerErrorProtocol, Encodable {
    case invalidCardholderName(message: String, diagnosticsId: String = .uuid)
    case invalidCardnumber(message: String, diagnosticsId: String = .uuid)
    case invalidCvv(message: String, diagnosticsId: String = .uuid)
    case invalidExpiryDate(message: String, diagnosticsId: String = .uuid)
    case invalidPostalCode(message: String, diagnosticsId: String = .uuid)
    case invalidFirstName(message: String, diagnosticsId: String = .uuid)
    case invalidLastName(message: String, diagnosticsId: String = .uuid)
    case invalidAddress(message: String, diagnosticsId: String = .uuid)
    case invalidCity(message: String, diagnosticsId: String = .uuid)
    case invalidState(message: String, diagnosticsId: String = .uuid)
    case invalidCountry(message: String, diagnosticsId: String = .uuid)
    case invalidPhoneNumber(message: String, diagnosticsId: String = .uuid)
    case invalidRawData(diagnosticsId: String = .uuid)
    case invalidOTPCode(message: String, diagnosticsId: String = .uuid)
    case invalidCardType(message: String, diagnosticsId: String = .uuid)
    case banksNotLoaded(diagnosticsId: String = .uuid)
    case invalidBankId(bankId: String?, diagnosticsId: String = .uuid)
    case sessionNotCreated(diagnosticsId: String = .uuid)
    case invalidPaymentCategory(diagnosticsId: String = .uuid)
    case paymentAlreadyFinalized(diagnosticsId: String = .uuid)
    case invalidUserDetails(field: String, diagnosticsId: String = .uuid)
    case vaultedPaymentDataMismatch(paymentMethod: String, dataType: String, diagnosticsId: String = .uuid)

    public var diagnosticsId: String {
        switch self {
        case let .invalidCardholderName(_, diagnosticsId): diagnosticsId
        case let .invalidCardnumber(_, diagnosticsId): diagnosticsId
        case let .invalidCvv(_, diagnosticsId): diagnosticsId
        case let .invalidExpiryDate(_, diagnosticsId): diagnosticsId
        case let .invalidPostalCode(_, diagnosticsId): diagnosticsId
        case let .invalidFirstName(_, diagnosticsId): diagnosticsId
        case let .invalidLastName(_, diagnosticsId): diagnosticsId
        case let .invalidAddress(_, diagnosticsId): diagnosticsId
        case let .invalidCity(_, diagnosticsId): diagnosticsId
        case let .invalidState(_, diagnosticsId): diagnosticsId
        case let .invalidCountry(_, diagnosticsId): diagnosticsId
        case let .invalidPhoneNumber(_, diagnosticsId): diagnosticsId
        case let .invalidRawData(diagnosticsId): diagnosticsId
        case let .vaultedPaymentDataMismatch(_, _, diagnosticsId): diagnosticsId
        case let .invalidOTPCode(_, diagnosticsId): diagnosticsId
        case let .invalidCardType(_, diagnosticsId): diagnosticsId
        case let .banksNotLoaded(diagnosticId): diagnosticId
        case let .invalidBankId(_, diagnosticId): diagnosticId
        case let .sessionNotCreated(diagnosticsId): diagnosticsId
        case let .invalidPaymentCategory(diagnosticsId): diagnosticsId
        case let .paymentAlreadyFinalized(diagnosticsId): diagnosticsId
        case let .invalidUserDetails(_, diagnosticsId): diagnosticsId
        }
    }

    public var errorId: String {
        switch self {
        case .invalidCardholderName: "invalid-cardholder-name"
        case .invalidCardnumber: "invalid-card-number"
        case .invalidCvv: "invalid-cvv"
        case .invalidExpiryDate: "invalid-expiry-date"
        case .invalidPostalCode: "invalid-postal-code"
        case .invalidFirstName: "invalid-first-name"
        case .invalidLastName: "invalid-last-name"
        case .invalidAddress: "invalid-address"
        case .invalidCity: "invalid-city"
        case .invalidState: "invalid-state"
        case .invalidCountry: "invalid-country"
        case .invalidPhoneNumber: "invalid-phone-number"
        case .invalidRawData: "invalid-raw-data"
        case .vaultedPaymentDataMismatch: "vaulted-payment-method-additional-data-mismatch"
        case .invalidOTPCode: "invalid-otp-code"
        case .invalidCardType: "unsupported-card-type"
        case .invalidBankId: "invalid-bank-id"
        case .banksNotLoaded: "banks-not-loaded"
        case .sessionNotCreated: "session-not-created"
        case .invalidPaymentCategory: "invalid-payment-category"
        case .paymentAlreadyFinalized: "payment-already-finalized"
        case .invalidUserDetails(let field, _): "invalid-customer-\(field)"
        }
    }

    public var errorDescription: String? {
        switch self {
        case .invalidCardholderName(let message, _),
                .invalidCardnumber(let message, _),
                .invalidCvv(let message, _),
                .invalidExpiryDate(let message, _),
                .invalidPostalCode(let message, _),
                .invalidFirstName(let message, _),
                .invalidLastName(let message, _),
                .invalidAddress(let message, _),
                .invalidCity(let message, _),
                .invalidState(let message, _),
                .invalidCountry(let message, _),
                .invalidPhoneNumber(let message, _),
                .invalidOTPCode(let message, _),
                .invalidCardType(let message, _): "[\(errorId)] \(message)"
        case .invalidRawData: "[\(errorId)] Raw data is not valid."
        case .invalidBankId: "Please provide a valid bank id"
        case .banksNotLoaded: "Banks need to be loaded before bank id can be collected."
        case .sessionNotCreated: "Session needs to be created before payment category can be collected."
        case .invalidPaymentCategory: "Payment category is invalid."
        case .paymentAlreadyFinalized: "This payment was configured to be finalized automatically."
        case .invalidUserDetails(let field, _): "The \(field) is not valid."
        case .vaultedPaymentDataMismatch(let methodType, let dataType, _):
            "[\(errorId)] Vaulted payment method \(methodType) needs additional data of type \(dataType)"
        }
    }

    public var errorUserInfo: [String: Any] {
        var tmpUserInfo: [String: Any] = [
            "createdAt": Date().toString(),
            "diagnosticsId": diagnosticsId
        ]
        if let inputElementType { tmpUserInfo["inputElementType"] = inputElementType }
        return tmpUserInfo
    }

    public var recoverySuggestion: String? { nil }

    var exposedError: Error { self }

    var inputElementType: String? {
        switch self {
        case .invalidCardholderName: "CARDHOLDER_NAME"
        case .invalidCardnumber: "CARD_NUMBER"
        case .invalidCvv: "CVV"
        case .invalidExpiryDate: "EXPIRY_DATE"
        case .invalidPhoneNumber: "PHONE_NUMBER"
        case .invalidOTPCode: "OTP"
        case .invalidCardType: "CARD_NUMBER"
        case .banksNotLoaded: "BANKS"
        case .invalidBankId: "BANK"
        case .invalidUserDetails: "USER_DETAILS"
        default: nil
        }
    }

    var analyticsContext: [String: Any] {
        var context: [String: Any] = [:]
        context[AnalyticsContextKeys.errorId] = errorId
        if let paymentMethodType { context[AnalyticsContextKeys.paymentMethodType] = paymentMethodType }
        return context
    }

    private var paymentMethodType: String? {
        switch self {
        case .vaultedPaymentDataMismatch(let paymentMethodType, _, _): paymentMethodType
        default: nil
        }
    }
}
