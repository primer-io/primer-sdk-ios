//
//  Error.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

// swiftlint:disable file_length
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
    var errorId: String { get }
    var exposedError: Error { get }
    var info: [String: Any]? { get }
    var diagnosticsId: String { get }
    var analyticsContext: [String: Any] { get }
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
    case failedToPerform3DS(paymentMethodType: String, error: Error?, userInfo: [String: String]?, diagnosticsId: String)
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
    case failedToProcessPayment(paymentMethodType: String?, paymentId: String, status: String, userInfo: [String: String]?, diagnosticsId: String)
    case invalidVaultedPaymentMethodId(vaultedPaymentMethodId: String, userInfo: [String: String]?, diagnosticsId: String)
    case nolError(code: String?, message: String?, userInfo: [String: String]?, diagnosticsId: String)
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
        case .nolError:
            return "nol-pay-sdk-error"
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
        case .failedToPerform3DS(_, _, _, let diagnosticsId):
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
        case .failedToProcessPayment(_, _, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidVaultedPaymentMethodId(_, _, let diagnosticsId):
            return diagnosticsId
        case .nolError(_, _, _, let diagnosticsId):
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
        case .failedToImport3DS:
            return "Failed on import Primer3DS"
        case .failedToPerform3DS(_, let error, _, _):
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
        case .failedToProcessPayment(_, let paymentId, let status, _, _):
            return "The payment with id \(paymentId) was created but ended up in a \(status) status."
        case .invalidVaultedPaymentMethodId(let vaultedPaymentMethodId, _, _):
            return "The vaulted payment method with id '\(vaultedPaymentMethodId)' doesn't exist."
        case .nolError(let code, let message, _, _):
            return "Nol SDK encountered an error: \(String(describing: code)), \(String(describing: message))"
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
                .failedToPerform3DS(_, _, let userInfo, _),
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
                .failedToProcessPayment(_, _, _, let userInfo, _),
                .invalidVaultedPaymentMethodId(_, let userInfo, _),
                .nolError(_, _, let userInfo, _),
                .unknown(let userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }

        case .sdkDismissed:
            break
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
        case .unsupportedPaymentMethod:
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
        case .nolError:
            return nil
        case .unknown:
            return "Contact Primer and provide them diagnostics id \(self.diagnosticsId)"
        }
    }

    var exposedError: Error {
        return self
    }
    
    var analyticsContext: [String : Any] {
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
                .unsupportedPaymentMethod(let paymentMethodType, _ , _),
                .missingCustomUI(let paymentMethodType, _, _),
                .missingSDK(let paymentMethodType, _, _, _),
                .failedToProcessPayment(let paymentMethodType?, _, _, _, _),
                .failedToPerform3DS(let paymentMethodType, _, _, _):
            return paymentMethodType
        case .applePayTimedOut:
            return PrimerPaymentMethodType.applePay.rawValue
        case .nolError:
            return PrimerPaymentMethodType.nolPay.rawValue
        default: return nil
        }
    }
}

// TODO: Review custom initializer for simplified payment error
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
