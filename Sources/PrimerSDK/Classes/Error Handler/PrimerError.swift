//
//  Error.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

#if canImport(UIKit)

// swiftlint:disable file_length
import Foundation
import UIKit

internal protocol PrimerErrorProtocol: CustomNSError, LocalizedError {
    var errorId: String { get }
    var exposedError: Error { get }
    var info: [String: Any]? { get }
    var diagnosticsId: String { get }
}

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
                .invalidRetailer(_, let userInfo, _):
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
        }
    }
}

internal enum InternalError: PrimerErrorProtocol {
    
    case failedToEncode(message: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case failedToDecode(message: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case failedToSerialize(message: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case connectivityErrors(errors: [Error], userInfo: [String: String]?, diagnosticsId: String?)
    case invalidUrl(url: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case invalidValue(key: String, value: Any?, userInfo: [String: String]?, diagnosticsId: String?)
    case noData(userInfo: [String: String]?, diagnosticsId: String?)
    case serverError(status: Int, response: PrimerServerErrorResponse?, userInfo: [String: String]?, diagnosticsId: String?)
    case unauthorized(url: String, method: HTTPMethod, userInfo: [String: String]?, diagnosticsId: String?)
    case underlyingErrors(errors: [Error], userInfo: [String: String]?, diagnosticsId: String?)
    case failedToPerform3dsButShouldContinue(error: Primer3DSErrorContainer)
    case failedToPerform3dsAndShouldBreak(error: Error)
    case noNeedToPerform3ds(status: String)
    
    var errorId: String {
        switch self {
        case .failedToEncode:
            return "failed-to-encode"
        case .failedToDecode:
            return "failed-to-decode"
        case .failedToSerialize:
            return "failed-to-serialize"
        case .connectivityErrors:
            return "connectivity-errors"
        case .invalidUrl:
            return "invalid-url"
        case .invalidValue:
            return "invalid-value"
        case .noData:
            return "no-data"
        case .serverError:
            return "server-error"
        case .unauthorized:
            return "unauthorized"
        case .underlyingErrors:
            return "underlying-errors"
        case .failedToPerform3dsButShouldContinue:
            return "failed-to-perform-3ds-but-should-continue"
        case .failedToPerform3dsAndShouldBreak:
            return "failed-to-perform-3ds-and-should-break"
        case .noNeedToPerform3ds:
            return "no-need-to-perform-3ds"
        }
    }
    
    var diagnosticsId: String {
        switch self {
        case .failedToEncode(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .failedToDecode(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .failedToSerialize(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .connectivityErrors(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidUrl(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidValue(_, _, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .noData(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .serverError(_, _, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .unauthorized(_, _, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .underlyingErrors(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .failedToPerform3dsButShouldContinue,
                .failedToPerform3dsAndShouldBreak,
                .noNeedToPerform3ds:
            return UUID().uuidString
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .failedToEncode(let message, _, _):
            return "[\(errorId)] Failed to encode\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId))"
        case .failedToDecode(let message, _, _):
            return "[\(errorId)] Failed to decode\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId))"
        case .failedToSerialize(let message, _, _):
            return "[\(errorId)] Failed to serialize\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId))"
        case .connectivityErrors(let errors, _, _):
            return "[\(errorId)] Connectivity failure | Errors: \(errors.combinedDescription) (diagnosticsId: \(self.diagnosticsId))"
        case .invalidUrl(let url, _, _):
            return "[\(errorId)] Invalid URL \(url ?? "nil") (diagnosticsId: \(self.diagnosticsId))"
        case .invalidValue(let key, let value, _, _):
            return "[\(errorId)] Invalid value \(value ?? "nil") for key \(key) (diagnosticsId: \(self.diagnosticsId))"
        case .noData:
            return "[\(errorId)] No data"
        case .serverError(let status, let response, _, _):
            var resStr: String = "nil"
            if let response = response,
               let resData = try? JSONEncoder().encode(response),
                let str = resData.prettyPrintedJSONString as String?
            {
                resStr = str
            }
            return "[\(errorId)] Server error [\(status)] Response: \(resStr) (diagnosticsId: \(self.diagnosticsId))"
        case .unauthorized(let url, let method, _, _):
            return "[\(errorId)] Unauthorized response for URL \(url) [\(method.rawValue)] (diagnosticsId: \(self.diagnosticsId))"
        case .underlyingErrors(let errors, _, _):
            return "[\(errorId)] Multiple errors occured | Errors \(errors.combinedDescription) (diagnosticsId: \(self.diagnosticsId))"
        case .failedToPerform3dsButShouldContinue:
            return "[\(errorId)] Failed to perform 3DS but should continue"
        case .failedToPerform3dsAndShouldBreak(let error):
            return "[\(errorId)] Failed to perform 3DS with error \(error.localizedDescription), and should break"
        case .noNeedToPerform3ds(let status):
            return "[\(errorId)] No need to perform 3DS because status is \(status)"
        }
    }
    
    var info: [String: Any]? {
        var tmpUserInfo: [String: String] = ["createdAt": Date().toString()]
        
        switch self {
        case .failedToEncode(_, let userInfo, _),
                .failedToDecode(_, let userInfo, _),
                .failedToSerialize(_, let userInfo, _),
                .connectivityErrors(_, let userInfo, _),
                .invalidUrl(_, let userInfo, _),
                .invalidValue(_, _, let userInfo, _),
                .noData(let userInfo, _),
                .serverError(_, _, let userInfo, _),
                .unauthorized(_, _, let userInfo, _),
                .underlyingErrors(_, let userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
            tmpUserInfo["diagnosticsId"] = self.diagnosticsId
        case .failedToPerform3dsButShouldContinue,
                .failedToPerform3dsAndShouldBreak,
                .noNeedToPerform3ds:
            break
        }
        
        return tmpUserInfo
    }
    
    var errorUserInfo: [String : Any] {
        return info ?? [:]
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .failedToEncode:
            return "Check object's encode(to:) function for wrong CodingKeys, or unexpected values."
        case .failedToDecode:
            return "Check object's init(from:) function for wrong CodingKeys, or unexpected values."
        case .failedToSerialize:
            return "Check if all object's properties can be serialized."
        case .connectivityErrors:
            return "Check underlying conectivity errors for more information."
        case .invalidUrl:
            return "Provide a valid URL, meaning that it must include http(s):// at the begining and also follow URL formatting rules."
        case .invalidValue(let key, let value, _, _):
            return "Check if value \(value ?? "nil") is valid for key \(key)"
        case .noData:
            return "If you were expecting data on this response, check that your backend has sent the appropriate data."
        case .serverError:
            return "Check the server's response to debug this error further."
        case .unauthorized:
            return "Check that the you have provided the SDK with a client token."
        case .underlyingErrors(let errors, _, _):
            return "Check underlying errors' recovery suggestions for more information.\nRecovery Suggestions:\n\(errors.compactMap({ ($0 as NSError).localizedRecoverySuggestion }))"
        case .failedToPerform3dsButShouldContinue,
                .failedToPerform3dsAndShouldBreak,
                .noNeedToPerform3ds:
            return nil
        }
    }

    var exposedError: Error {
        switch self {
        case .failedToPerform3dsButShouldContinue(let error):
            return error.primerError
        case .failedToPerform3dsAndShouldBreak(let error):
            return error.primerError
        default:
            return PrimerError.unknown(userInfo: self.errorUserInfo as? [String: String], diagnosticsId: self.diagnosticsId)
        }
    }
}

public enum PrimerError: PrimerErrorProtocol {
    
    case generic(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case uninitializedSDKSession(userInfo: [String: String]?, diagnosticsId: String)
    case invalidClientToken(userInfo: [String: String]?, diagnosticsId: String)
    case missingPrimerConfiguration(userInfo: [String: String]?, diagnosticsId: String)
    case missingPrimerDelegate(userInfo: [String: String]?, diagnosticsId: String)
    case missingPrimerCheckoutComponentsDelegate(userInfo: [String: String]?, diagnosticsId: String)
    case misconfiguredPaymentMethods(userInfo: [String: String]?, diagnosticsId: String)
    case missingPrimerInputElement(inputElementType: PrimerInputElementType, userInfo: [String: String]?, diagnosticsId: String)
    case cancelled(paymentMethodType: String, userInfo: [String: String]?, diagnosticsId: String)
    case failedToCreateSession(error: Error?, userInfo: [String: String]?, diagnosticsId: String)
    case failedOnWebViewFlow(error: Error?, userInfo: [String: String]?, diagnosticsId: String)
    case failedToImport3DS(userInfo: [String: String]?, diagnosticsId: String)
    case failedToPerform3DS(error: Error?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidUrl(url: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalid3DSKey(userInfo: [String: String]?, diagnosticsId: String)
    case invalidArchitecture(description: String, recoverSuggestion: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidClientSessionValue(name: String, value: String?, allowedValue: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidMerchantCapabilities(userInfo: [String: String]?, diagnosticsId: String)
    case invalidMerchantIdentifier(merchantIdentifier: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidUrlScheme(urlScheme: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidSetting(name: String, value: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidSupportedPaymentNetworks(userInfo: [String: String]?, diagnosticsId: String)
    case invalidValue(key: String, value: Any?, userInfo: [String: String]?, diagnosticsId: String)
    case unableToMakePaymentsOnProvidedNetworks(userInfo: [String: String]?, diagnosticsId: String)
    case unableToPresentPaymentMethod(paymentMethodType: String, userInfo: [String: String]?, diagnosticsId: String)
    case unsupportedIntent(intent: PrimerSessionIntent, userInfo: [String: String]?, diagnosticsId: String)
    case unsupportedPaymentMethod(paymentMethodType: String, userInfo: [String: String]?, diagnosticsId: String)
    case underlyingErrors(errors: [Error], userInfo: [String: String]?, diagnosticsId: String)
    case missingCustomUI(paymentMethod: String, userInfo: [String: String]?, diagnosticsId: String)
    case missingSDK(paymentMethodType: String, sdkName: String, userInfo: [String: String]?, diagnosticsId: String)
    case merchantError(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case cancelledByCustomer(message: String?, userInfo: [String: String]?, diagnosticsId: String)
    case paymentFailed(description: String, userInfo: [String: String]?, diagnosticsId: String)
    case applePayTimedOut(userInfo: [String: String]?, diagnosticsId: String)
    case failedToFindModule(name: String, userInfo: [String: String]?, diagnosticsId: String)
    case sdkDismissed
    case failedToProcessPayment(paymentId: String, status: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidVaultedPaymentMethodId(vaultedPaymentMethodId: String, userInfo: [String: String]?, diagnosticsId: String)
    case unknown(userInfo: [String: String]?, diagnosticsId: String)
    
    public var errorId: String {
        switch self {
        case .generic:
            return "primer-generic"
        case .uninitializedSDKSession:
            return "uninitialized-sdk-session"
        case .invalidClientToken:
            return "invalid-client-token"
        case .missingPrimerConfiguration:
            return "missing-configuration"
        case .missingPrimerDelegate:
            return "missing-primer-delegate"
        case .missingPrimerCheckoutComponentsDelegate:
            return "missing-primer-checkout-components-delegate"
        case .misconfiguredPaymentMethods:
            return "misconfigured-payment-methods"
        case .missingPrimerInputElement:
            return "missing-primer-input-element"
        case .cancelled:
            return "payment-cancelled"
        case .cancelledByCustomer:
            return PrimerPaymentErrorCode.cancelledByCustomer.rawValue
        case .failedToCreateSession:
            return "failed-to-create-session"
        case .failedOnWebViewFlow:
            return "failed-on-webview"
        case .failedToImport3DS:
            return "failed-to-import-3ds"
        case .failedToPerform3DS:
            return "failed-to-perform-3ds"
        case .invalid3DSKey:
            return "invalid-3ds-key"
        case .invalidArchitecture:
            return "invalid-architecture"
        case .invalidClientSessionValue:
            return "invalid-client-session-value"
        case .invalidUrl:
            return "invalid-url"
        case .invalidMerchantCapabilities:
            return "invalid-merchant-capabilities"
        case .invalidMerchantIdentifier:
            return "invalid-merchant-identifier"
        case .invalidUrlScheme:
            return "invalid-url-scheme"
        case .invalidSetting:
            return "invalid-setting"
        case .invalidSupportedPaymentNetworks:
            return "invalid-supported-payment-networks"
        case .invalidValue:
            return "invalid-value"
        case .unableToMakePaymentsOnProvidedNetworks:
            return "unable-to-make-payments-on-provided-networks"
        case .unableToPresentPaymentMethod:
            return "unable-to-present-payment-method"
        case .unsupportedIntent:
            return "unsupported-session-intent"
        case .unsupportedPaymentMethod:
            return "unsupported-payment-method-type"
        case .underlyingErrors:
            return "generic-underlying-errors"
        case .missingCustomUI:
            return "missing-custom-ui"
        case .missingSDK:
            return "missing-sdk-dependency"
        case .merchantError:
            return "merchant-error"
        case .paymentFailed:
            return PrimerPaymentErrorCode.failed.rawValue
        case .applePayTimedOut:
            return "apple-pay-timed-out"
        case .failedToFindModule:
            return "failed-to-find-module"
        case .sdkDismissed:
            return "sdk-dismissed"
        case .failedToProcessPayment:
            return "failed-to-process-payment"
        case .invalidVaultedPaymentMethodId:
            return "invalid-vaulted-payment-method-id"
        case .unknown:
            return "unknown"
        }
    }
    
    public var diagnosticsId: String {
        switch self {
        case .generic(_, _, let diagnosticsId):
            return diagnosticsId
        case .uninitializedSDKSession(_, let diagnosticsId):
            return diagnosticsId
        case .invalidClientToken(_, let diagnosticsId):
            return diagnosticsId
        case .missingPrimerConfiguration(_, let diagnosticsId):
            return diagnosticsId
        case .missingPrimerDelegate(_, let diagnosticsId):
            return diagnosticsId
        case .missingPrimerCheckoutComponentsDelegate(_, let diagnosticsId):
            return diagnosticsId
        case .misconfiguredPaymentMethods(_, let diagnosticsId):
            return diagnosticsId
        case .missingPrimerInputElement(_, _, let diagnosticsId):
            return diagnosticsId
        case .cancelled(_, _, let diagnosticsId):
            return diagnosticsId
        case .failedToCreateSession(_, _, let diagnosticsId):
            return diagnosticsId
        case .failedOnWebViewFlow(_, _, let diagnosticsId):
            return diagnosticsId
        case .failedToImport3DS(_, let diagnosticsId):
            return diagnosticsId
        case .failedToPerform3DS(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidUrl(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalid3DSKey(_, let diagnosticsId):
            return diagnosticsId
        case .invalidArchitecture(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidClientSessionValue(_, _, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidMerchantCapabilities(_, let diagnosticsId):
            return diagnosticsId
        case .invalidMerchantIdentifier(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidUrlScheme(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidSetting(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidSupportedPaymentNetworks(_, let diagnosticsId):
            return diagnosticsId
        case .invalidValue(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .unableToMakePaymentsOnProvidedNetworks(_, let diagnosticsId):
            return diagnosticsId
        case .unableToPresentPaymentMethod(_, _, let diagnosticsId):
            return diagnosticsId
        case .unsupportedIntent(_, _, let diagnosticsId):
            return diagnosticsId
        case .unsupportedPaymentMethod(_, _, let diagnosticsId):
            return diagnosticsId
        case .underlyingErrors(_, _, let diagnosticsId):
            return diagnosticsId
        case .missingCustomUI(_, _, let diagnosticsId):
            return diagnosticsId
        case .missingSDK(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .merchantError(_, _, let diagnosticsId):
            return diagnosticsId
        case .cancelledByCustomer(_, _, let diagnosticsId):
            return diagnosticsId
        case .paymentFailed(_, _, let diagnosticsId):
            return diagnosticsId
        case .applePayTimedOut(_, let diagnosticsId):
            return diagnosticsId
        case .failedToFindModule(_, _, let diagnosticsId):
            return diagnosticsId
        case .sdkDismissed:
            return UUID().uuidString
        case .failedToProcessPayment(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidVaultedPaymentMethodId(_, _, let diagnosticsId):
            return diagnosticsId
        case .unknown(_, let diagnosticsId):
            return diagnosticsId
        }
    }
    
    var plainDescription: String? {
        switch self {
        case .generic(let message, let userInfo, _):
            if let userInfo = userInfo,
                let jsonData = try? JSONSerialization.data(withJSONObject: userInfo, options: .fragmentsAllowed),
               let jsonStr = jsonData.prettyPrintedJSONString as String? {
                return "Generic error | Message: \(message) | Data: \(jsonStr))"
            } else {
                return "Generic error | Message: \(message)"
            }
        case .uninitializedSDKSession:
            return "[\(errorId)] SDK session has not been initialzed (diagnosticsId: \(self.diagnosticsId)"
        case .invalidClientToken:
            return "Client token is not valid"
        case .missingPrimerConfiguration:
            return "Missing SDK configuration"
        case .missingPrimerDelegate:
            return "Primer delegate has not been set"
        case .missingPrimerCheckoutComponentsDelegate:
            return "Primer Checkout Components delegate has not been set"
        case .missingPrimerInputElement(let inputElementType, _, _):
            return "Missing primer input element for \(inputElementType)"
        case .missingSDK(let paymentMethodType, let sdkName, _, _):
            return "\(paymentMethodType) configuration has been found, but dependency \(sdkName) is missing"
        case .misconfiguredPaymentMethods:
            return "Payment methods haven't been set up correctly"
        case .cancelled(let paymentMethodType, _, _):
            return "Payment method \(paymentMethodType) cancelled"
        case .cancelledByCustomer(let message, _, _):
            let messageToShow = message != nil ? " with message \(message!)" : ""
            return "Payment cancelled\(messageToShow)"
        case .failedToCreateSession(error: let error, _, _):
            return "Failed to create session with error: \(error?.localizedDescription ?? "nil")"
        case .failedOnWebViewFlow(error: let error, _, _):
            return "Failed on webview flow with error: \(error?.localizedDescription ?? "nil")"
        case .failedToImport3DS(_, _):
            return "Failed on import Primer3DS"
        case .failedToPerform3DS(let error, _, _):
            return "Failed on perform 3DS with error: \(error?.localizedDescription ?? "nil")"
        case .invalid3DSKey:
            return "Invalid 3DS key"
        case .invalidArchitecture(let description, _, _, _):
            return "\(description)"
        case .invalidClientSessionValue(let name, let value, _, _, _):
            return "Invalid client session value for '\(name)' with value '\(value ?? "nil")'"
        case .invalidUrl(url: let url, _, _):
            return "Invalid URL: \(url ?? "nil")"
        case .invalidMerchantCapabilities:
            return "Invalid merchant capabilities"
        case .invalidMerchantIdentifier(let merchantIdentifier, _, _):
            return "Invalid merchant identifier: \(merchantIdentifier == nil ? "nil" : "\(merchantIdentifier!)")"
        case .invalidUrlScheme(let urlScheme, _, _):
            return "Invalid URL scheme: \(urlScheme == nil ? "nil" : "\(urlScheme!)")"
        case .invalidSetting(let name, let value, _, _):
            return "Invalid setting for \(name) (provided value is \(value ?? "nil"))"
        case .invalidSupportedPaymentNetworks:
            return "Invalid supported payment networks"
        case .invalidValue(key: let key, value: let value, _, _):
            return "Invalid value '\(value ?? "nil")' for key '\(key)'"
        case .unableToMakePaymentsOnProvidedNetworks:
            return "Unable to make payments on provided networks"
        case .unableToPresentPaymentMethod(let paymentMethodType, _, _):
            return "Unable to present payment method \(paymentMethodType)"
        case .unsupportedIntent(let intent, _, _):
            return "Unsupported session intent \(intent.rawValue)"
        case .underlyingErrors(let errors, _, _):
            return "Multiple errors occured: \(errors.combinedDescription)"
        case .unsupportedPaymentMethod(let paymentMethodType, _, _):
            return "Unsupported payment method type \(paymentMethodType)"
        case .missingCustomUI(let paymentMethod, _, _):
            return "Missing custom user interface for \(paymentMethod)"
        case .merchantError(let message, _, _):
            return message
        case .paymentFailed(let description, _, _):
            return "\(description)"
        case .applePayTimedOut:
            return "Apple Pay timed out"
        case .failedToFindModule(let name, _, _):
            return "Failed to find module \(name)"
        case .sdkDismissed:
            return "SDK has been dismissed"
        case .failedToProcessPayment(let paymentId, let status, _, _):
            return "The payment with id \(paymentId) was created but ended up in a \(status) status."
        case .invalidVaultedPaymentMethodId(let vaultedPaymentMethodId, _, _):
            return "The vaulted payment method with id '\(vaultedPaymentMethodId)' doesn't exist."
        case .unknown:
            return "Something went wrong"
        }
    }
    
    public var errorDescription: String? {
        return "[\(errorId)] \(plainDescription ?? "") (diagnosticsId: \(self.errorUserInfo["diagnosticsId"] as? String ?? "nil"))"
    }
    
    var info: [String: Any]? {
        var tmpUserInfo: [String: Any] = errorUserInfo
        
        switch self {
        case .generic(_, let userInfo, _),
                .uninitializedSDKSession(let userInfo, _),
                .invalidClientToken(let userInfo, _),
                .missingPrimerConfiguration(let userInfo, _),
                .missingPrimerDelegate(let userInfo, _),
                .missingPrimerCheckoutComponentsDelegate(let userInfo, _),
                .missingPrimerInputElement(_, let userInfo, _),
                .misconfiguredPaymentMethods(let userInfo, _),
                .cancelled(_, let userInfo, _),
                .failedToCreateSession(_, let userInfo, _),
                .failedOnWebViewFlow(_, let userInfo, _),
                .failedToImport3DS(let userInfo, _),
                .failedToPerform3DS(_, let userInfo, _),
                .invalidUrl(_, let userInfo, _),
                .invalid3DSKey(let userInfo, _),
                .invalidArchitecture(_, _, let userInfo, _),
                .invalidClientSessionValue(_, _, _, let userInfo, _),
                .invalidMerchantCapabilities(let userInfo, _),
                .invalidMerchantIdentifier(_, let userInfo, _),
                .invalidUrlScheme(_, let userInfo, _),
                .invalidSetting(_, _, let userInfo, _),
                .invalidSupportedPaymentNetworks(let userInfo, _),
                .invalidValue(_, _, let userInfo, _),
                .unableToMakePaymentsOnProvidedNetworks(let userInfo, _),
                .unableToPresentPaymentMethod(_, let userInfo, _),
                .unsupportedIntent(_, let userInfo, _),
                .unsupportedPaymentMethod(_, let userInfo, _),
                .underlyingErrors(_, let userInfo, _),
                .missingCustomUI(_, let userInfo, _),
                .missingSDK(_, _, let userInfo, _),
                .merchantError(_, let userInfo, _),
                .cancelledByCustomer(_, let userInfo, _),
                .paymentFailed(_, let userInfo, _),
                .applePayTimedOut(let userInfo, _),
                .failedToFindModule(_, let userInfo, _),
                .failedToProcessPayment(_, _, let userInfo, _),
                .invalidVaultedPaymentMethodId(_, let userInfo, _),
                .unknown(let userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
            
        case .sdkDismissed:
            break
        }
        
        return tmpUserInfo
    }
    
    public var errorUserInfo: [String : Any] {
        let tmpUserInfo: [String: Any] = [
            "createdAt": Date().toString(),
            "diagnosticsId": diagnosticsId
        ]
        
        return tmpUserInfo
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .generic:
            return nil
        case .uninitializedSDKSession:
            return "Make sure you have provided the SDK with a client token."
        case .invalidClientToken:
            return "Check if the token you have provided is a valid token (not nil and not expired)."
        case .missingPrimerConfiguration:
            return "Check if you have an active internet connection."
        case .missingPrimerDelegate:
            return "Primer's delegate has not been set. Ensure that you have added Primer.shared.delegate = self on the view controller you wish to present Primer's SDK."
        case .missingPrimerCheckoutComponentsDelegate:
            return "Primer Checkout Components' delegate has not been set. Ensure that you have added PrimerCheckoutComponents.delegate = self on the view controller you wish to implement the components."
        case .missingPrimerInputElement(let inputElementtype, _, _):
            return "A PrimerInputElement for \(inputElementtype) has to be provided."
        case .misconfiguredPaymentMethods:
            return "Payment Methods are not configured correctly. Ensure that you have configured them in the Connection, and/or that they are set up for the specified conditions on your dashboard https://dashboard.primer.io/"
        case .cancelled:
            return nil
        case .cancelledByCustomer:
            return nil
        case .failedToCreateSession:
            return nil
        case .failedOnWebViewFlow:
            return nil
        case .failedToImport3DS:
            // We need to check all the possibilities of underlying errors, and provide a suggestion that makes sense
            return nil
        case .failedToPerform3DS:
            return nil
        case .invalidUrl:
            return nil
        case .invalid3DSKey:
            return "Contact Primer to enable 3DS on your account."
        case .invalidArchitecture(_, let recoverySuggestion, _, _):
            return recoverySuggestion
        case .invalidClientSessionValue(let name, _, let allowedValue, _, _):
            var str = "Check if you have provided a valid value for \"\(name)\" in your client session."
            if let allowedValue {
                str +=  " Allowed values are [\(allowedValue)]."
            }
            return str
        case .invalidMerchantCapabilities:
            return nil
        case .invalidMerchantIdentifier:
            return "Check if you have provided a valid merchant identifier in the SDK settings."
        case .invalidUrlScheme:
            return "Check if you have provided a valid URL scheme in the SDK settings."
        case .invalidSetting(let name, _, _, _):
            return "Check if you have provided a value for \(name) in the SDK settings."
        case .invalidSupportedPaymentNetworks:
            return nil
        case .invalidValue(let key, let value, _, _):
            return "Check if value \(value ?? "nil") is valid for key \(key)"
        case .unableToMakePaymentsOnProvidedNetworks:
            return nil
        case .unableToPresentPaymentMethod:
            return "Check if all necessary values have been provided on your client session. You can find the necessary values on our documentation (website)."
        case .unsupportedIntent(let intent, _, _):
            if intent == .checkout {
                return "Change the intent to .vault"
            } else {
                return "Change the intent to .checkout"
            }
        case .unsupportedPaymentMethod(_, _, _):
            return "Change the payment method type"
        case .underlyingErrors:
            return "Check underlying errors for more information."
        case .missingCustomUI(let paymentMethod, _, _):
            return "You have to built your UI for \(paymentMethod) and utilize PrimerCheckoutComponents.UIManager's functionality."
        case .missingSDK(let paymentMethodType, let sdkName, _, _):
            return "Add \(sdkName) in your project so you can perform payments with \(paymentMethodType)"
        case .merchantError:
            return nil
        case .paymentFailed:
            return nil
        case .applePayTimedOut:
            return "Make sure you have an active internet connection and your Apple Pay configuration is correct."
        case .failedToFindModule(let name, _, _):
            return "Make sure you have added the module \(name) in your project."
        case .sdkDismissed:
            return nil
        case .failedToProcessPayment:
            return nil
        case .invalidVaultedPaymentMethodId:
            return "Please provide the id of one of the vaulted payment methods that have been returned by the 'fetchVaultedPaymentMethods' function."
        case .unknown:
            return "Contact Primer and provide them diagnostics id \(self.diagnosticsId)"
        }
    }
    
    var exposedError: Error {
        return self
    }
}

// TODO: Reiew custom initializer for simplified payment error
extension PrimerError {
    
    internal static func simplifiedErrorFromErrorID(_ errorCode: PrimerPaymentErrorCode, message: String? = nil, userInfo: [String: String]?) -> PrimerError? {
        
        switch errorCode {
        case .failed:
            return PrimerError.paymentFailed(description: message ?? "", userInfo: userInfo, diagnosticsId: UUID().uuidString)
        case .cancelledByCustomer:
            return PrimerError.cancelledByCustomer(message: message, userInfo: userInfo, diagnosticsId: UUID().uuidString)
        default:
            return nil
        }
    }
}

fileprivate extension Array where Element == Error {
    
    var combinedDescription: String {
        var message: String = ""
        
        self.forEach { err in
            if let primerError = err as? PrimerErrorProtocol {
                message += "\(primerError.localizedDescription) | "
            } else {
                let nsErr = err as NSError
                message += "Domain: \(nsErr.domain), Code: \(nsErr.code), Description: \(nsErr.localizedDescription)  | "
            }
        }
        
        if message.hasSuffix(" | ") {
            message = String(message.dropLast(3))
        }
        
        return "[\(message)]"
    }
}

internal struct PrimerServerErrorResponse: Codable {
    var errorId: String
    var `description`: String
    var diagnosticsId: String
    var validationErrors: [String]?
}

internal extension Error {
    
    var primerError: Error {
        if let internalErr = self as? InternalError {
            return internalErr.exposedError
        } else if let primer3DSErr = self as? Primer3DSErrorContainer {
            return primer3DSErr
        } else if let primerErr = self as? PrimerError {
            switch primerErr {
            case .underlyingErrors(let errors, _, _):
                if errors.isEmpty {
                    let unknownErr = PrimerError.unknown(
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString)
                    return unknownErr
                } else if errors.count == 1 {
                    return errors.first!.primerError
                } else {
                    return primerErr
                }
            default:
                return primerErr
            }
        } else if let validationErr = self as? PrimerValidationError {
            return validationErr
        } else {
            let primerErr = PrimerError.underlyingErrors(
                errors: [self],
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            return primerErr
        }
    }
}

#endif
