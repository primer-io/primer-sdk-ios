//
//  Error.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

// swiftlint:disable file_length
// swiftlint:disable type_body_length

import Foundation
import UIKit

struct AnalyticsContextKeys {
    static let createdAt = "createdAt"
    static let paymentMethodType = "paymentMethodType"
    static let reasonCode = "reasonCode"
    static let reasonText = "reasonText"
    static let errorId = "errorId"
}

protocol PrimerErrorProtocol: CustomNSError, LocalizedError {
    associatedtype InfoType
    var errorId: String { get }
    var exposedError: Error { get }
    var info: InfoType? { get }
    var diagnosticsId: String { get }
    var analyticsContext: [String: Any] { get }
}

public enum PrimerError: PrimerErrorProtocol {
    typealias InfoType = [String: Any]
    case uninitializedSDKSession(userInfo: [String: String]?, diagnosticsId: String)
    case invalidClientToken(userInfo: [String: String]?, diagnosticsId: String)
    case missingPrimerConfiguration(userInfo: [String: String]?, diagnosticsId: String)
    case misconfiguredPaymentMethods(userInfo: [String: String]?, diagnosticsId: String)
    case missingPrimerInputElement(inputElementType: PrimerInputElementType,
                                   userInfo: [String: String]?,
                                   diagnosticsId: String)
    case cancelled(paymentMethodType: String, userInfo: [String: String]?, diagnosticsId: String)
    case failedToCreateSession(error: Error?, userInfo: [String: String]?, diagnosticsId: String)
    case failedToPerform3DS(paymentMethodType: String, error: Error?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidUrl(url: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidArchitecture(description: String, recoverSuggestion: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidClientSessionValue(name: String, value: String?, allowedValue: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidMerchantIdentifier(merchantIdentifier: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidUrlScheme(urlScheme: String?, userInfo: [String: String]?, diagnosticsId: String)
    case invalidValue(key: String, value: Any?, userInfo: [String: String]?, diagnosticsId: String)
    case unableToMakePaymentsOnProvidedNetworks(userInfo: [String: String]?, diagnosticsId: String)
    case unableToPresentPaymentMethod(paymentMethodType: String, userInfo: [String: String]?, diagnosticsId: String)
    case unsupportedIntent(intent: PrimerSessionIntent, userInfo: [String: String]?, diagnosticsId: String)
    case unsupportedPaymentMethod(paymentMethodType: String, userInfo: [String: String]?, diagnosticsId: String)
    case unsupportedPaymentMethodForManager(paymentMethodType: String,
                                            category: String,
                                            userInfo: [String: String]?,
                                            diagnosticsId: String)
    case underlyingErrors(errors: [Error], userInfo: [String: String]?, diagnosticsId: String)
    case missingSDK(paymentMethodType: String, sdkName: String, userInfo: [String: String]?, diagnosticsId: String)
    case merchantError(message: String, userInfo: [String: String]?, diagnosticsId: String)
    case paymentFailed(paymentMethodType: String,
                       description: String,
                       userInfo: [String: String]?,
                       diagnosticsId: String)
    case failedToProcessPayment(paymentMethodType: String?,
                                paymentId: String,
                                status: String,
                                userInfo: [String: String]?,
                                diagnosticsId: String)
    case applePayTimedOut(userInfo: [String: String]?, diagnosticsId: String)
    case invalidVaultedPaymentMethodId(vaultedPaymentMethodId: String, userInfo: [String: String]?, diagnosticsId: String)
    case nolError(code: String?, message: String?, userInfo: [String: String]?, diagnosticsId: String)
    case klarnaWrapperError(message: String?, userInfo: [String: String]?, diagnosticsId: String)
    case unableToPresentApplePay(userInfo: [String: String]?, diagnosticsId: String)
    case unknown(userInfo: [String: String]?, diagnosticsId: String)

    public var errorId: String {
        switch self {
        case .uninitializedSDKSession:
            return "uninitialized-sdk-session"
        case .invalidClientToken:
            return "invalid-client-token"
        case .missingPrimerConfiguration:
            return "missing-configuration"
        case .misconfiguredPaymentMethods:
            return "misconfigured-payment-methods"
        case .missingPrimerInputElement:
            return "missing-primer-input-element"
        case .cancelled:
            return "payment-cancelled"
        case .failedToCreateSession:
            return "failed-to-create-session"
        case .failedToPerform3DS:
            return "failed-to-perform-3ds"
        case .invalidArchitecture:
            return "invalid-architecture"
        case .invalidClientSessionValue:
            return "invalid-client-session-value"
        case .invalidUrl:
            return "invalid-url"
        case .invalidMerchantIdentifier:
            return "invalid-merchant-identifier"
        case .invalidUrlScheme:
            return "invalid-url-scheme"
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
        case .unsupportedPaymentMethodForManager:
            return "unsupported-payment-method-for-manager"
        case .underlyingErrors:
            return "generic-underlying-errors"
        case .missingSDK:
            return "missing-sdk-dependency"
        case .merchantError:
            return "merchant-error"
        case .paymentFailed:
            return PrimerPaymentErrorCode.failed.rawValue
        case .applePayTimedOut:
            return "apple-pay-timed-out"
        case .failedToProcessPayment:
            return "failed-to-process-payment"
        case .invalidVaultedPaymentMethodId:
            return "invalid-vaulted-payment-method-id"
        case .nolError:
            return "nol-pay-sdk-error"
        case .klarnaWrapperError:
            return "klarna-wrapper-sdk-error"
        case .unableToPresentApplePay:
            return "unable-to-present-apple-pay"
        case .unknown:
            return "unknown"
        }
    }

    public var underlyingErrorCode: String? {
        switch self {
        case .nolError(let code, _, _, _):
            return String(describing: code)
        default:
            return nil
        }
    }

    public var diagnosticsId: String {
        switch self {
        case .uninitializedSDKSession(_, let diagnosticsId):
            return diagnosticsId
        case .invalidClientToken(_, let diagnosticsId):
            return diagnosticsId
        case .missingPrimerConfiguration(_, let diagnosticsId):
            return diagnosticsId
        case .misconfiguredPaymentMethods(_, let diagnosticsId):
            return diagnosticsId
        case .missingPrimerInputElement(_, _, let diagnosticsId):
            return diagnosticsId
        case .cancelled(_, _, let diagnosticsId):
            return diagnosticsId
        case .failedToCreateSession(_, _, let diagnosticsId):
            return diagnosticsId
        case .failedToPerform3DS(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidUrl(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidArchitecture(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidClientSessionValue(_, _, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidMerchantIdentifier(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidUrlScheme(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidValue(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .unableToMakePaymentsOnProvidedNetworks(_, let diagnosticsId):
            return diagnosticsId
        case .unableToPresentPaymentMethod(_, _, let diagnosticsId):
            return diagnosticsId
        case .unableToPresentApplePay(_, let diagnosticsId):
            return diagnosticsId
        case .unsupportedIntent(_, _, let diagnosticsId):
            return diagnosticsId
        case .unsupportedPaymentMethod(_, _, let diagnosticsId):
            return diagnosticsId
        case .unsupportedPaymentMethodForManager(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .underlyingErrors(_, _, let diagnosticsId):
            return diagnosticsId
        case .missingSDK(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .merchantError(_, _, let diagnosticsId):
            return diagnosticsId
        case .paymentFailed(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .applePayTimedOut(_, let diagnosticsId):
            return diagnosticsId
        case .failedToProcessPayment(_, _, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidVaultedPaymentMethodId(_, _, let diagnosticsId):
            return diagnosticsId
        case .nolError(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .klarnaWrapperError(_, _, let diagnosticsId):
            return diagnosticsId
        case .unknown(_, let diagnosticsId):
            return diagnosticsId
        }
    }

    var plainDescription: String? {
        switch self {
        case .uninitializedSDKSession:
            return "[\(errorId)] SDK session has not been initialzed (diagnosticsId: \(self.diagnosticsId)"
        case .invalidClientToken:
            return "Client token is not valid"
        case .missingPrimerConfiguration:
            return "Missing SDK configuration"
        case .missingPrimerInputElement(let inputElementType, _, _):
            return "Missing primer input element for \(inputElementType)"
        case .missingSDK(let paymentMethodType, let sdkName, _, _):
            return "\(paymentMethodType) configuration has been found, but dependency \(sdkName) is missing"
        case .misconfiguredPaymentMethods:
            return "Payment methods haven't been set up correctly"
        case .cancelled(let paymentMethodType, _, _):
            return "Payment method \(paymentMethodType) cancelled"
        case .failedToCreateSession(error: let error, _, _):
            return "Failed to create session with error: \(error?.localizedDescription ?? "nil")"
        case .failedToPerform3DS(_, let error, _, _):
            return "Failed on perform 3DS with error: \(error?.localizedDescription ?? "nil")"
        case .invalidArchitecture(let description, _, _, _):
            return "\(description)"
        case .invalidClientSessionValue(let name, let value, _, _, _):
            return "Invalid client session value for '\(name)' with value '\(value ?? "nil")'"
        case .invalidUrl(url: let url, _, _):
            return "Invalid URL: \(url ?? "nil")"
        case .invalidMerchantIdentifier(let merchantIdentifier, _, _):
            return "Invalid merchant identifier: \(merchantIdentifier == nil ? "nil" : "\(merchantIdentifier!)")"
        case .invalidUrlScheme(let urlScheme, _, _):
            return "Invalid URL scheme: \(urlScheme == nil ? "nil" : "\(urlScheme!)")"
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
        case .unsupportedPaymentMethodForManager(let paymentMethodType, let category, _, _):
            return "Payment method \(paymentMethodType) is not supported on \(category) manager"
        case .merchantError(let message, _, _):
            return message
        case .paymentFailed(_, let description, _, _):
            return "\(description)"
        case .applePayTimedOut:
            return "Apple Pay timed out"
        case .failedToProcessPayment(_, let paymentId, let status, _, _):
            return "The payment with id \(paymentId) was created but ended up in a \(status) status."
        case .invalidVaultedPaymentMethodId(let vaultedPaymentMethodId, _, _):
            return "The vaulted payment method with id '\(vaultedPaymentMethodId)' doesn't exist."
        case .nolError(let code, let message, _, _):
            return "Nol SDK encountered an error: \(String(describing: code)), \(String(describing: message))"
        case .klarnaWrapperError(let message, _, _):
            return "Klarna wrapper SDK encountered an error: \(String(describing: message))"
        case .unableToPresentApplePay:
            return "Unable to present Apple Pay"
        case .unknown:
            return "Something went wrong"
        }
    }

    public var errorDescription: String? {
        return "[\(errorId)] \(plainDescription ?? "") (diagnosticsId: \(self.errorUserInfo["diagnosticsId"] as? String ?? "nil"))"
    }

    var info: InfoType? {
        var tmpUserInfo: [String: Any] = errorUserInfo

        switch self {
        case .uninitializedSDKSession(let userInfo, _),
             .invalidClientToken(let userInfo, _),
             .missingPrimerConfiguration(let userInfo, _),
             .missingPrimerInputElement(_, let userInfo, _),
             .misconfiguredPaymentMethods(let userInfo, _),
             .cancelled(_, let userInfo, _),
             .failedToCreateSession(_, let userInfo, _),
             .failedToPerform3DS(_, _, let userInfo, _),
             .invalidUrl(_, let userInfo, _),
             .invalidArchitecture(_, _, let userInfo, _),
             .invalidClientSessionValue(_, _, _, let userInfo, _),
             .invalidMerchantIdentifier(_, let userInfo, _),
             .invalidUrlScheme(_, let userInfo, _),
             .invalidValue(_, _, let userInfo, _),
             .unableToMakePaymentsOnProvidedNetworks(let userInfo, _),
             .unableToPresentPaymentMethod(_, let userInfo, _),
             .unsupportedIntent(_, let userInfo, _),
             .unsupportedPaymentMethod(_, let userInfo, _),
             .unsupportedPaymentMethodForManager(_, _, let userInfo, _),
             .underlyingErrors(_, let userInfo, _),
             .missingSDK(_, _, let userInfo, _),
             .merchantError(_, let userInfo, _),
             .paymentFailed(_, _, let userInfo, _),
             .applePayTimedOut(let userInfo, _),
             .failedToProcessPayment(_, _, _, let userInfo, _),
             .invalidVaultedPaymentMethodId(_, let userInfo, _),
             .nolError(_, _, let userInfo, _),
             .klarnaWrapperError(_, let userInfo, _),
             .unableToPresentApplePay(let userInfo, _),
             .unknown(let userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
        }

        return tmpUserInfo
    }

    public var errorUserInfo: [String: Any] {
        let tmpUserInfo: [String: Any] = [
            "createdAt": Date().toString(),
            "diagnosticsId": diagnosticsId
        ]

        return tmpUserInfo
    }

    public var recoverySuggestion: String? {
        switch self {
        case .uninitializedSDKSession:
            return "Make sure you have provided the SDK with a client token."
        case .invalidClientToken:
            return "Check if the token you have provided is a valid token (not nil and not expired)."
        case .missingPrimerConfiguration:
            return "Check if you have an active internet connection."
        case .missingPrimerInputElement(let inputElementtype, _, _):
            return "A PrimerInputElement for \(inputElementtype) has to be provided."
        case .misconfiguredPaymentMethods:
            let message =
                """
Payment Methods are not configured correctly. \
Ensure that you have configured them in the Connection, \
and/or that they are set up for the specified conditions \
on your dashboard https://dashboard.primer.io/
"""
            return message
        case .cancelled:
            return nil
        case .failedToCreateSession:
            return nil
        case .failedToPerform3DS:
            return nil
        case .invalidUrl:
            return nil
        case .invalidArchitecture(_, let recoverySuggestion, _, _):
            return recoverySuggestion
        case .invalidClientSessionValue(let name, _, let allowedValue, _, _):
            var str = "Check if you have provided a valid value for \"\(name)\" in your client session."
            if let allowedValue {
                str +=  " Allowed values are [\(allowedValue)]."
            }
            return str
        case .invalidMerchantIdentifier:
            return "Check if you have provided a valid merchant identifier in the SDK settings."
        case .invalidUrlScheme:
            return "Check if you have provided a valid URL scheme in the SDK settings."
        case .invalidValue(let key, let value, _, _):
            return "Check if value \(value ?? "nil") is valid for key \(key)"
        case .unableToMakePaymentsOnProvidedNetworks:
            return nil
        case .unableToPresentPaymentMethod:
            let message = """
Check if all necessary values have been provided on your client session.\
 You can find the necessary values on our documentation (website).
"""
            return message
        case .unsupportedIntent(let intent, _, _):
            if intent == .checkout {
                return "Change the intent to .vault"
            } else {
                return "Change the intent to .checkout"
            }
        case .unsupportedPaymentMethod:
            return "Change the payment method type"
        case .unsupportedPaymentMethodForManager:
            return "Use a method that supports this manager, or use the correct manager for the method. See PrimerPaymentMethodManagerCategory."
        case .underlyingErrors:
            return "Check underlying errors for more information."
        case .missingSDK(let paymentMethodType, let sdkName, _, _):
            return "Add \(sdkName) in your project so you can perform payments with \(paymentMethodType)"
        case .merchantError:
            return nil
        case .paymentFailed:
            return nil
        case .applePayTimedOut:
            return "Make sure you have an active internet connection and your Apple Pay configuration is correct."
        case .failedToProcessPayment:
            return nil
        case .invalidVaultedPaymentMethodId:
            return "Please provide the id of one of the vaulted payment methods that have been returned by the 'fetchVaultedPaymentMethods' function."
        case .nolError:
            return nil
        case .klarnaWrapperError:
            return nil
        case .unableToPresentApplePay:
            let message = """
PassKit was unable to present the Apple Pay UI. Check merchantIdentifier \
and other parameters are set correctly for the current environment.
"""
            return message
        case .unknown:
            return "Contact Primer and provide them diagnostics id \(self.diagnosticsId)"
        }
    }

    var exposedError: Error {
        return self
    }

    var analyticsContext: [String: Any] {
        var context: [String: Any] = [:]
        if let paymentMethodType = paymentMethodType {
            context[AnalyticsContextKeys.paymentMethodType] = paymentMethodType
        }
        context[AnalyticsContextKeys.errorId] = errorId
        return context
    }

    private var paymentMethodType: String? {
        switch self {
        case .cancelled(let paymentMethodType, _, _),
             .unableToPresentPaymentMethod(let paymentMethodType, _, _),
             .unsupportedPaymentMethod(let paymentMethodType, _, _),
             .missingSDK(let paymentMethodType, _, _, _),
             .failedToProcessPayment(let paymentMethodType?, _, _, _, _),
             .failedToPerform3DS(let paymentMethodType, _, _, _):
            return paymentMethodType
        case .applePayTimedOut,
             .unableToMakePaymentsOnProvidedNetworks:
            return PrimerPaymentMethodType.applePay.rawValue
        case .nolError:
            return PrimerPaymentMethodType.nolPay.rawValue
        default: return nil
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable file_length
