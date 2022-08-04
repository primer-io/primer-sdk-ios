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
    var info: [String: String]? { get }
    var diagnosticsId: String { get }
}

internal enum PrimerValidationError: PrimerErrorProtocol {
    
    case invalidCardholderName(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidCardnumber(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidCvv(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidExpiryDate(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidPostalCode(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidFirstName(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidLastName(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidAddress(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidState(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidCountry(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidRawData(userInfo: [String: String]?, diagnosticsId: String?)
    
    var diagnosticsId: String {
        switch self {
        case .invalidCardholderName(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidCardnumber(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidCvv(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidExpiryDate(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidPostalCode(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidFirstName(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidLastName(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidAddress(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidState(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidCountry(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidRawData(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        }
    }

    var errorId: String {
        switch self {
        case .invalidCardholderName:
            return "invalid-cardholder-name"
        case .invalidCardnumber:
            return "invalid-cardnumber"
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
        case .invalidState:
            return "invalid-state"
        case .invalidCountry:
            return "invalid-country"
        case .invalidRawData:
            return "invalid-raw-data"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidCardholderName:
            return "[\(errorId)] Invalid cardholder name"
        case .invalidCardnumber:
            return "[\(errorId)] Invalid card number"
        case .invalidCvv:
            return "[\(errorId)] Invalid CVV"
        case .invalidExpiryDate:
            return "[\(errorId)] Invalid expiry date"
        case .invalidPostalCode:
            return "[\(errorId)] Invalid postal code"
        case .invalidFirstName:
            return "[\(errorId)] Invalid first name"
        case .invalidLastName:
            return "[\(errorId)] Invalid last name"
        case .invalidAddress:
            return "[\(errorId)] Invalid address"
        case .invalidState:
            return "[\(errorId)] Invalid state"
        case .invalidCountry:
            return "[\(errorId)] Invalid country"
        case .invalidRawData:
            return "[\(errorId)] Invalid raw data"
        }
    }
    
    var info: [String: String]? {
        var tmpUserInfo: [String: String] = ["createdAt": Date().toString()]
        
        switch self {
        case .invalidCardholderName(let userInfo, _),
                .invalidCardnumber(let userInfo, _),
                .invalidCvv(let userInfo, _),
                .invalidExpiryDate(let userInfo, _),
                .invalidPostalCode(let userInfo, _),
                .invalidFirstName(let userInfo, _),
                .invalidLastName(let userInfo, _),
                .invalidAddress(let userInfo, _),
                .invalidState(let userInfo, _),
                .invalidCountry(let userInfo, _),
                .invalidRawData(let userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
        }
        
        return tmpUserInfo
    }
    
    var errorUserInfo: [String : Any] {
        return info ?? [:]
    }
    
    var recoverySuggestion: String? {
        return nil
    }
    
    var exposedError: Error {
        return self
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
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .failedToEncode(let message, _, _):
            return "[\(errorId)] Failed to encode\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId)"
        case .failedToDecode(let message, _, _):
            return "[\(errorId)] Failed to decode\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId)"
        case .failedToSerialize(let message, _, _):
            return "[\(errorId)] Failed to serialize\(message == nil ? "" : " (\(message!)") (diagnosticsId: \(self.diagnosticsId)"
        case .connectivityErrors(let errors, _, _):
            return "[\(errorId)] Connectivity failure | Errors: \(errors.combinedDescription) (diagnosticsId: \(self.diagnosticsId)"
        case .invalidUrl(let url, _, _):
            return "[\(errorId)] Invalid URL \(url ?? "nil") (diagnosticsId: \(self.diagnosticsId)"
        case .invalidValue(let key, let value, _, _):
            return "[\(errorId)] Invalid value \(value ?? "nil") for key \(key) (diagnosticsId: \(self.diagnosticsId)"
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
            return "[\(errorId)] Server error [\(status)] Response: \(resStr) (diagnosticsId: \(self.diagnosticsId)"
        case .unauthorized(let url, let method, _, _):
            return "[\(errorId)] Unauthorized response for URL \(url) [\(method.rawValue)] (diagnosticsId: \(self.diagnosticsId)"
        case .underlyingErrors(let errors, _, _):
            return "[\(errorId)] Multiple errors occured | Errors \(errors.combinedDescription) (diagnosticsId: \(self.diagnosticsId)"
        }
    }
    
    var info: [String: String]? {
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
        }
    }

    var exposedError: Error {
        return PrimerError.unknown(userInfo: self.errorUserInfo as? [String: String], diagnosticsId: self.diagnosticsId).exposedError
    }
}

internal enum PrimerError: PrimerErrorProtocol {
    
    case generic(message: String, userInfo: [String: String]?, diagnosticsId: String?)
    case invalidClientToken(userInfo: [String: String]?, diagnosticsId: String?)
    case missingPrimerConfiguration(userInfo: [String: String]?, diagnosticsId: String?)
    case missingPrimerDelegate(userInfo: [String: String]?, diagnosticsId: String?)
    case missingPrimerCheckoutComponentsDelegate(userInfo: [String: String]?, diagnosticsId: String?)
    case misconfiguredPaymentMethods(userInfo: [String: String]?, diagnosticsId: String?)
    case missingPrimerInputElement(inputElementType: PrimerInputElementType, userInfo: [String: String]?, diagnosticsId: String?)
    case cancelled(paymentMethodType: String, userInfo: [String: String]?, diagnosticsId: String?)
    case failedToCreateSession(error: Error?, userInfo: [String: String]?, diagnosticsId: String?)
    case failedOnWebViewFlow(error: Error?, userInfo: [String: String]?, diagnosticsId: String?)
    case failedToPerform3DS(error: Error?, userInfo: [String: String]?, diagnosticsId: String?)
    case invalidUrl(url: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case invalid3DSKey(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidClientSessionSetting(name: String, value: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case invalidMerchantCapabilities(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidMerchantIdentifier(merchantIdentifier: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case invalidUrlScheme(urlScheme: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case invalidSetting(name: String, value: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case invalidSupportedPaymentNetworks(userInfo: [String: String]?, diagnosticsId: String?)
    case invalidValue(key: String, value: Any?, userInfo: [String: String]?, diagnosticsId: String?)
    case unableToMakePaymentsOnProvidedNetworks(userInfo: [String: String]?, diagnosticsId: String?)
    case unableToPresentPaymentMethod(paymentMethodType: String, userInfo: [String: String]?, diagnosticsId: String?)
    case unsupportedIntent(intent: PrimerSessionIntent, userInfo: [String: String]?, diagnosticsId: String?)
    case unsupportedPaymentMethod(paymentMethodType: String, userInfo: [String: String]?, diagnosticsId: String?)
    case underlyingErrors(errors: [Error], userInfo: [String: String]?, diagnosticsId: String?)
    case missingCustomUI(paymentMethod: String, userInfo: [String: String]?, diagnosticsId: String?)
    case merchantError(message: String, userInfo: [String: String]?, diagnosticsId: String?)
    case cancelledByCustomer(message: String?, userInfo: [String: String]?, diagnosticsId: String?)
    case paymentFailed(userInfo: [String: String]?, diagnosticsId: String?)
    case applePayTimedOut(userInfo: [String: String]?, diagnosticsId: String?)
    case unknown(userInfo: [String: String]?, diagnosticsId: String?)
    
    var errorId: String {
        switch self {
        case .generic:
            return "primer-generic"
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
        case .failedToPerform3DS:
            return "failed-to-perform-3ds"
        case .invalid3DSKey:
            return "invalid-3ds-key"
        case .invalidClientSessionSetting:
            return "invalid-client-session-setting"
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
        case .merchantError:
            return "merchant-error"
        case .paymentFailed:
            return PrimerPaymentErrorCode.failed.rawValue
        case .applePayTimedOut:
            return "apple-pay-timed-out"
        case .unknown:
            return "unknown"
        }
    }
    
    var diagnosticsId: String {
        switch self {
        case .generic(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidClientToken(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .missingPrimerConfiguration(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .missingPrimerDelegate(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .missingPrimerCheckoutComponentsDelegate(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .misconfiguredPaymentMethods(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .missingPrimerInputElement(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .cancelled(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .failedToCreateSession(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .failedOnWebViewFlow(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .failedToPerform3DS(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidUrl(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalid3DSKey(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidClientSessionSetting(_, _, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidMerchantCapabilities(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidMerchantIdentifier(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidUrlScheme(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidSetting(_, _, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidSupportedPaymentNetworks(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .invalidValue(_, _, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .unableToMakePaymentsOnProvidedNetworks(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .unableToPresentPaymentMethod(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .unsupportedIntent(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .unsupportedPaymentMethod(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .underlyingErrors(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .missingCustomUI(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .merchantError(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .cancelledByCustomer(_, _, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .paymentFailed(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .applePayTimedOut(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        case .unknown(_, let diagnosticsId):
            return diagnosticsId ?? UUID().uuidString
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .generic(let message, let userInfo, _):
            if let userInfo = userInfo,
                let jsonData = try? JSONSerialization.data(withJSONObject: userInfo, options: .fragmentsAllowed),
               let jsonStr = jsonData.prettyPrintedJSONString as String? {
                return "[\(errorId)] Generic error | Message: \(message) | Data: \(jsonStr)) (diagnosticsId: \(self.diagnosticsId)"
            } else {
                return "[\(errorId)] Generic error | Message: \(message) (diagnosticsId: \(self.diagnosticsId)"
            }
        case .invalidClientToken:
            return "[\(errorId)] Client token is not valid (diagnosticsId: \(self.diagnosticsId)"
        case .missingPrimerConfiguration:
            return "[\(errorId)] Missing SDK configuration (diagnosticsId: \(self.diagnosticsId)"
        case .missingPrimerDelegate:
            return "[\(errorId)] Primer delegate has not been set (diagnosticsId: \(self.diagnosticsId)"
        case .missingPrimerCheckoutComponentsDelegate:
            return "[\(errorId)] Primer Checkout Components delegate has not been set (diagnosticsId: \(self.diagnosticsId)"
        case .missingPrimerInputElement(let inputElementType, _, _):
            return "[\(errorId)] Missing primer input element for \(inputElementType) (diagnosticsId: \(self.diagnosticsId)"
        case .misconfiguredPaymentMethods:
            return "[\(errorId)] Payment methods haven't been set up correctly (diagnosticsId: \(self.diagnosticsId)"
        case .cancelled(let paymentMethodType, _, _):
            return "[\(errorId)] Payment method \(paymentMethodType) cancelled (diagnosticsId: \(self.diagnosticsId)"
        case .cancelledByCustomer(let message, _, _):
            let messageToShow = message != nil ? " with message \(message!)" : ""
            return "[\(errorId)] Payment cancelled\(messageToShow) (diagnosticsId: \(self.diagnosticsId)"
        case .failedToCreateSession(error: let error, _, _):
            return "[\(errorId)] Failed to create session with error: \(error?.localizedDescription ?? "nil") (diagnosticsId: \(self.diagnosticsId)"
        case .failedOnWebViewFlow(error: let error, _, _):
            return "[\(errorId)] Failed on webview flow with error: \(error?.localizedDescription ?? "nil") (diagnosticsId: \(self.diagnosticsId)"
        case .failedToPerform3DS(let error, _, _):
            return "[\(errorId)] Failed on perform 3DS with error: \(error?.localizedDescription ?? "nil") (diagnosticsId: \(self.diagnosticsId)"
        case .invalid3DSKey:
            return "[\(errorId)] Invalid 3DS key (diagnosticsId: \(self.diagnosticsId)"
        case .invalidClientSessionSetting(let name, let value, _, _):
            return "[\(errorId)] Invalid client session setting for '\(name)' with value '\(value ?? "nil")' (diagnosticsId: \(self.diagnosticsId)"
        case .invalidUrl(url: let url, _, _):
            return "[\(errorId)] Invalid URL: \(url ?? "nil") (diagnosticsId: \(self.diagnosticsId)"
        case .invalidMerchantCapabilities:
            return "[\(errorId)] Invalid merchant capabilities (diagnosticsId: \(self.diagnosticsId)"
        case .invalidMerchantIdentifier(let merchantIdentifier, _, _):
            return "[\(errorId)] Invalid merchant identifier: \(merchantIdentifier == nil ? "nil" : "\(merchantIdentifier!)") (diagnosticsId: \(self.diagnosticsId)"
        case .invalidUrlScheme(let urlScheme, _, _):
            return "[\(errorId)] Invalid URL scheme: \(urlScheme == nil ? "nil" : "\(urlScheme!)") (diagnosticsId: \(self.diagnosticsId)"
        case .invalidSetting(let name, let value, _, _):
            return "[\(errorId)] Invalid setting for \(name) (provided value is \(value ?? "nil")) (diagnosticsId: \(self.diagnosticsId)"
        case .invalidSupportedPaymentNetworks:
            return "[\(errorId)] Invalid supported payment networks (diagnosticsId: \(self.diagnosticsId)"
        case .invalidValue(key: let key, value: let value, _, _):
            return "[\(errorId)] Invalid value '\(value ?? "nil")' for key '\(key)' (diagnosticsId: \(self.diagnosticsId)"
        case .unableToMakePaymentsOnProvidedNetworks:
            return "[\(errorId)] Unable to make payments on provided networks (diagnosticsId: \(self.diagnosticsId)"
        case .unableToPresentPaymentMethod(let paymentMethodType, _, _):
            return "[\(errorId)] Unable to present payment method \(paymentMethodType) (diagnosticsId: \(self.diagnosticsId)"
        case .unsupportedIntent(let intent, _, _):
            return "[\(errorId)] Unsupported session intent \(intent.rawValue) (diagnosticsId: \(self.diagnosticsId)"
        case .underlyingErrors(let errors, _, _):
            return "[\(errorId)] Multiple errors occured: \(errors.combinedDescription) (diagnosticsId: \(self.diagnosticsId)"
        case .unsupportedPaymentMethod(let paymentMethodType, _, _):
            return "[\(errorId)] Unsupported payment method type \(paymentMethodType) (diagnosticsId: \(self.diagnosticsId)"
        case .missingCustomUI(let paymentMethod, _, _):
            return "[\(errorId)] Missing custom user interface for \(paymentMethod) (diagnosticsId: \(self.diagnosticsId)"
        case .merchantError(let message, _, _):
            return message
        case .paymentFailed(_, _):
            return "[\(errorId)] The payment failed, retry. (diagnosticsId: \(self.diagnosticsId)"
        case .applePayTimedOut:
            return "[\(errorId)] Apple Pay timed out (diagnosticsId: \(self.diagnosticsId)"
        case .unknown:
            return "[\(errorId)] Something went wrong (diagnosticsId: \(self.diagnosticsId)"
        }
    }
    
    var info: [String: String]? {
        var tmpUserInfo: [String: String] = ["createdAt": Date().toString()]
        
        switch self {
        case .generic(_, let userInfo, _),
                .invalidClientToken(let userInfo, _),
                .missingPrimerConfiguration(let userInfo, _),
                .missingPrimerDelegate(let userInfo, _),
                .missingPrimerCheckoutComponentsDelegate(let userInfo, _),
                .missingPrimerInputElement(_, let userInfo, _),
                .misconfiguredPaymentMethods(let userInfo, _),
                .cancelled(_, let userInfo, _),
                .failedToCreateSession(_, let userInfo, _),
                .failedOnWebViewFlow(_, let userInfo, _),
                .failedToPerform3DS(_, let userInfo, _),
                .invalidUrl(_, let userInfo, _),
                .invalid3DSKey(let userInfo, _),
                .invalidClientSessionSetting(_, _, let userInfo, _),
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
                .merchantError(_, let userInfo, _),
                .cancelledByCustomer(_, let userInfo, _),
                .paymentFailed(let userInfo, _),
                .applePayTimedOut(let userInfo, _),
                .unknown(let userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
            tmpUserInfo["diagnosticsId"] = self.diagnosticsId
        }
        
        return tmpUserInfo
    }
    
    var errorUserInfo: [String : Any] {
        return info ?? [:]
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .generic:
            return nil
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
            // We need to check all the possibilities of underlying errors, and provide a suggestion that makes sense
            return nil
        case .failedOnWebViewFlow:
            // We need to check all the possibilities of underlying errors, and provide a suggestion that makes sense
            return nil
        case .failedToPerform3DS:
            // We need to check all the possibilities of underlying errors, and provide a suggestion that makes sense
            return nil
        case .invalidUrl:
            // We need to check all the possibilities of underlying errors, and provide a suggestion that makes sense
            return nil
        case .invalid3DSKey:
            return "Contact Primer to enable 3DS on your account."
        case .invalidClientSessionSetting(let name, _, _, _):
            return "Check if you have provided a value for \(name) in your client session"
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
        case .unsupportedPaymentMethod(let paymentMethodType, _, _):
            return "Change the payment method type"
        case .underlyingErrors:
            return "Check underlying errors for more information."
        case .missingCustomUI(let paymentMethod, _, _):
            return "You have to built your UI for \(paymentMethod) and utilize PrimerCheckoutComponents.UIManager's functionality."
        case .merchantError:
            return nil
        case .paymentFailed:
            return nil
        case .applePayTimedOut:
            return "Make sure you have an active internet connection and your Apple Pay configuration is correct."
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
            return PrimerError.paymentFailed(userInfo: userInfo, diagnosticsId: nil)
        case .cancelledByCustomer:
            return PrimerError.cancelledByCustomer(message: message, userInfo: userInfo, diagnosticsId: nil)
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

#endif
