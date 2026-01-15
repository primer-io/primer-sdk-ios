//
//  PrimerError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable type_body_length
import Foundation

enum AnalyticsContextKeys {
    static let createdAt = "createdAt"
    static let paymentMethodType = "paymentMethodType"
    static let reasonCode = "reasonCode"
    static let reasonText = "reasonText"
    static let errorId = "errorId"
}

protocol PrimerErrorProtocol: CustomNSError, LocalizedError {
    var errorId: String { get }
    var exposedError: Error { get }
    var diagnosticsId: String { get }
    var analyticsContext: [String: Any] { get }
}
import PrimerFoundation

func handled<E: Error>(
    error: E,
    file: String = #file,
    line: Int = #line,
    function: String = #function
) -> E {
    ErrorHandler.handle(error: error, file: file, line: line, function: function)
    return error
}

func handled(
    primerError: PrimerError,
    file: String = #file,
    line: Int = #line,
    function: String = #function
) -> PrimerError {
    handled(error: primerError, file: file, line: line, function: function)
}

func handled(
    internalError: InternalError,
    file: String = #file,
    line: Int = #line,
    function: String = #function
) -> InternalError {
    handled(error: internalError, file: file, line: line, function: function)
}

func handled(
    primerValidationError: PrimerValidationError,
    file: String = #file,
    line: Int = #line,
    function: String = #function
) -> PrimerValidationError {
    handled(error: primerValidationError, file: file, line: line, function: function)
}

public enum PrimerError: PrimerErrorProtocol {
    typealias InfoType = [String: Any]
    case uninitializedSDKSession(diagnosticsId: String = .uuid)
    case invalidClientToken(reason: String? = nil, diagnosticsId: String = .uuid)
    case missingPrimerConfiguration(diagnosticsId: String = .uuid)
    case misconfiguredPaymentMethods(diagnosticsId: String = .uuid)
    case missingPrimerInputElement(inputElementType: PrimerInputElementType, diagnosticsId: String = .uuid)
    case cancelled(paymentMethodType: String, diagnosticsId: String = .uuid)
    case failedToCreateSession(error: Error?, diagnosticsId: String = .uuid)
    case invalidUrl(url: String? = nil, diagnosticsId: String = .uuid)
    case invalidArchitecture(description: String, recoverSuggestion: String?, diagnosticsId: String = .uuid)
    case invalidClientSessionValue(name: String, value: String? = nil, allowedValue: String? = nil, diagnosticsId: String = .uuid)
    case invalidMerchantIdentifier(merchantIdentifier: String? = nil, diagnosticsId: String = .uuid)
    case invalidValue(key: String, value: Any? = nil, reason: String? = nil, diagnosticsId: String = .uuid)
    case unableToMakePaymentsOnProvidedNetworks(diagnosticsId: String = .uuid)
    case unableToPresentPaymentMethod(paymentMethodType: String, reason: String? = nil, diagnosticsId: String = .uuid)
    case unsupportedIntent(intent: PrimerSessionIntent, diagnosticsId: String = .uuid)
    case unsupportedPaymentMethod(paymentMethodType: String, reason: String? = nil, diagnosticsId: String = .uuid)
    case unsupportedPaymentMethodForManager(paymentMethodType: String, category: String, diagnosticsId: String = .uuid)
    case underlyingErrors(errors: [Error], diagnosticsId: String = .uuid)
    case missingSDK(paymentMethodType: String, sdkName: String, diagnosticsId: String = .uuid)
    case merchantError(message: String, diagnosticsId: String = .uuid)
    case paymentFailed(
        paymentMethodType: String?,
        paymentId: String,
        orderId: String?,
        status: String,
        diagnosticsId: String = .uuid
    )
    case failedToRedirect(url: String, diagnosticsId: String = .uuid)
    case failedToCreatePayment(paymentMethodType: String, description: String, diagnosticsId: String = .uuid)
    case failedToResumePayment(paymentMethodType: String, description: String, diagnosticsId: String = .uuid)
    case applePayTimedOut(diagnosticsId: String = .uuid)
    case invalidVaultedPaymentMethodId(vaultedPaymentMethodId: String, diagnosticsId: String = .uuid)
    case nolError(code: String?, message: String?, diagnosticsId: String = .uuid)
    case nolSdkInitError(diagnosticsId: String = .uuid)
    case klarnaError(message: String?, diagnosticsId: String = .uuid)
    case klarnaUserNotApproved(diagnosticsId: String = .uuid)
    case stripeError(key: String, message: String?, diagnosticsId: String = .uuid)
    case unableToPresentApplePay(diagnosticsId: String = .uuid)
    case applePayNoCardsInWallet(diagnosticsId: String = .uuid)
    case applePayDeviceNotSupported(diagnosticsId: String = .uuid)
    case applePayConfigurationError(merchantIdentifier: String?, diagnosticsId: String = .uuid)
    case applePayPresentationFailed(reason: String?, diagnosticsId: String = .uuid)
    case unknown(message: String? = nil, diagnosticsId: String = .uuid)

    public var errorId: String {
        switch self {
        case .uninitializedSDKSession: "uninitialized-sdk-session"
        case .invalidClientToken: "invalid-client-token"
        case .missingPrimerConfiguration: "missing-configuration"
        case .misconfiguredPaymentMethods: "misconfigured-payment-methods"
        case .missingPrimerInputElement: "missing-primer-input-element"
        case .cancelled: "payment-cancelled"
        case .failedToCreateSession: "failed-to-create-session"
        case .failedToRedirect: "failed-to-redirect"
        case .invalidArchitecture: "invalid-architecture"
        case .invalidClientSessionValue: "invalid-client-session-value"
        case .invalidUrl: "invalid-url"
        case .invalidMerchantIdentifier: "invalid-merchant-identifier"
        case .invalidValue: "invalid-value"
        case .unableToMakePaymentsOnProvidedNetworks: "unable-to-make-payments-on-provided-networks"
        case .unableToPresentPaymentMethod: "unable-to-present-payment-method"
        case .unsupportedIntent: "unsupported-session-intent"
        case .unsupportedPaymentMethod: "unsupported-payment-method-type"
        case .unsupportedPaymentMethodForManager: "unsupported-payment-method-for-manager"
        case .underlyingErrors: "generic-underlying-errors"
        case .missingSDK: "missing-sdk-dependency"
        case .merchantError: "merchant-error"
        case .paymentFailed: PrimerPaymentErrorCode.failed.rawValue
        case .applePayTimedOut: "apple-pay-timed-out"
        case .failedToCreatePayment: "failed-to-create-payment"
        case .failedToResumePayment: "failed-to-resume-payment"
        case .invalidVaultedPaymentMethodId: "invalid-vaulted-payment-method-id"
        case .nolError: "nol-pay-sdk-error"
        case .nolSdkInitError: "nol-pay-sdk-init-error"
        case .klarnaError: "klarna-sdk-error"
        case .klarnaUserNotApproved: "klarna-user-not-approved"
        case let .stripeError(key, _, _): key
        case .unableToPresentApplePay: "unable-to-present-apple-pay"
        case .applePayNoCardsInWallet: "apple-pay-no-cards-in-wallet"
        case .applePayDeviceNotSupported: "apple-pay-device-not-supported"
        case .applePayConfigurationError: "apple-pay-configuration-error"
        case .applePayPresentationFailed: "apple-pay-presentation-failed"
        case .unknown: "unknown"
        }
    }

    public var underlyingErrorCode: String? {
        switch self {
        case let .nolError(code, _, _):
            return String(describing: code)
        default:
            return nil
        }
    }

    public var diagnosticsId: String {
        switch self {
        case let .uninitializedSDKSession(id),
             let .invalidClientToken(_, id),
             let .missingPrimerConfiguration(id),
             let .misconfiguredPaymentMethods(id),
             let .missingPrimerInputElement(_, id),
             let .cancelled(_, id),
             let .failedToCreateSession(_, id),
             let .failedToRedirect(_, id),
             let .invalidUrl(_, id),
             let .invalidArchitecture(_, _, id),
             let .invalidClientSessionValue(_, _, _, id),
             let .invalidMerchantIdentifier(_, id),
             let .invalidValue(_, _, _, id),
             let .unableToMakePaymentsOnProvidedNetworks(id),
             let .unableToPresentPaymentMethod(_, _, id),
             let .unableToPresentApplePay(id),
             let .applePayNoCardsInWallet(id),
             let .applePayDeviceNotSupported(id),
             let .applePayConfigurationError(_, id),
             let .applePayPresentationFailed(_, id),
             let .unsupportedIntent(_, id),
             let .unsupportedPaymentMethod(_, _, id),
             let .unsupportedPaymentMethodForManager(_, _, id),
             let .underlyingErrors(_, id),
             let .missingSDK(_, _, id),
             let .merchantError(_, id),
             let .paymentFailed(_, _, _, _, id),
             let .applePayTimedOut(id),
             let .failedToCreatePayment(_, _, id),
             let .failedToResumePayment(_, _, id),
             let .invalidVaultedPaymentMethodId(_, id),
             let .nolError(_, _, id),
             let .nolSdkInitError(id),
             let .klarnaError(_, id),
             let .klarnaUserNotApproved(id),
             let .stripeError(_, _, id),
             let .unknown(_, id):
            return id
        }
    }

    var plainDescription: String? {
        switch self {
        case .uninitializedSDKSession:
            return "[\(errorId)] SDK session has not been initialzed (diagnosticsId: \(diagnosticsId)"
        case let .invalidClientToken(reason, _):
            return "Client token is not valid: \(reason ?? "")"
        case .missingPrimerConfiguration:
            return "Missing SDK configuration"
        case let .missingPrimerInputElement(inputElementType, _):
            return "Missing primer input element for \(inputElementType)"
        case let .missingSDK(paymentMethodType, sdkName, _):
            return "\(paymentMethodType) configuration has been found, but dependency \(sdkName) is missing"
        case .misconfiguredPaymentMethods:
            return "Payment methods haven't been set up correctly"
        case let .cancelled(paymentMethodType, _):
            return "Payment method \(paymentMethodType) cancelled"
        case let .failedToCreateSession(error: error, _):
            return "Failed to create session with error: \(error?.localizedDescription ?? "nil")"
        case let .failedToRedirect(url, _):
            return "Failed to redirect to \(url)"
        case let .invalidArchitecture(description, _, _):
            return "\(description)"
        case let .invalidClientSessionValue(name, value, _, _):
            return "Invalid client session value for '\(name)' with value '\(value ?? "nil")'"
        case let .invalidUrl(url: url, _):
            return "Invalid URL: \(url ?? "nil")"
        case let .invalidMerchantIdentifier(merchantIdentifier, _):
            return "Invalid merchant identifier: \(merchantIdentifier == nil ? "nil" : "\(merchantIdentifier!)")"
        case let .invalidValue(key: key, value: value, reason, _):
            let reasonString = reason.map { "(\($0))" } ?? ""
            return "Invalid value '\(value ?? "nil")' for key '\(key)'\(reasonString)"
        case .unableToMakePaymentsOnProvidedNetworks:
            return "Unable to make payments on provided networks"
        case let .unableToPresentPaymentMethod(paymentMethodType, reason, _):
            let reasonString = reason.map { "(\($0))" } ?? ""
            return "Unable to present payment method \(paymentMethodType) \(reasonString)"
        case let .unsupportedIntent(intent, _):
            return "Unsupported session intent \(intent.rawValue)"
        case let .underlyingErrors(errors, _):
            return "Multiple errors occured: \(errors.combinedDescription)"
        case let .unsupportedPaymentMethod(paymentMethodType, reason, _):
            let reasonString = reason.map { "(\($0))" } ?? ""
            return "Unsupported payment method type \(paymentMethodType) \(reasonString)"
        case let .unsupportedPaymentMethodForManager(paymentMethodType, category, _):
            return "Payment method \(paymentMethodType) is not supported on \(category) manager"
        case let .merchantError(message, _):
            return message
        case let .paymentFailed(_, paymentId, _, status, _):
            return "The payment with id \(paymentId) was created or resumed but ended up in a \(status) status."
        case .applePayTimedOut:
            return "Apple Pay timed out"
        case let .failedToCreatePayment(_, description, _):
            return "\(description)"
        case let .failedToResumePayment(_, description, _):
            return "\(description)"
        case let .invalidVaultedPaymentMethodId(vaultedPaymentMethodId, _):
            return "The vaulted payment method with id '\(vaultedPaymentMethodId)' doesn't exist."
        case let .nolError(code, message, _):
            return "Nol SDK encountered an error: \(String(describing: code)), \(String(describing: message))"
        case .nolSdkInitError:
            return "Nol SDK initialization error"
        case let .klarnaError(message, _):
            return "Klarna wrapper SDK encountered an error: \(String(describing: message))"
        case .klarnaUserNotApproved:
            return "User is not approved to perform Klarna payments"
        case let .stripeError(_, message, _):
            return "Stripe wrapper SDK encountered an error: \(String(describing: message))"
        case .unableToPresentApplePay:
            return "Unable to present Apple Pay"
        case .applePayNoCardsInWallet:
            return "Apple Pay has no cards in wallet"
        case .applePayDeviceNotSupported:
            return "Device does not support Apple Pay"
        case let .applePayConfigurationError(merchantIdentifier, _):
            return "Apple Pay configuration error: merchant identifier '\(merchantIdentifier ?? "nil")' may be invalid"
        case let .applePayPresentationFailed(reason, _):
            return "Apple Pay presentation failed: \(reason ?? "unknown reason")"
        case let .unknown(reason, _):
            return "Something went wrong\(reason ?? "")"
        }
    }

    public var errorDescription: String? {
        "[\(errorId)] \(plainDescription ?? "") (diagnosticsId: \(errorUserInfo["diagnosticsId"] as? String ?? "nil"))"
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
        case let .missingPrimerInputElement(inputElementtype, _):
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
        case .failedToRedirect:
            return nil
        case .invalidUrl:
            return nil
        case let .invalidArchitecture(_, recoverySuggestion, _):
            return recoverySuggestion
        case let .invalidClientSessionValue(name, _, allowedValue, _):
            var str = "Check if you have provided a valid value for \"\(name)\" in your client session."
            if let allowedValue {
                str += " Allowed values are [\(allowedValue)]."
            }
            return str
        case .invalidMerchantIdentifier:
            return "Check if you have provided a valid merchant identifier in the SDK settings."
        case let .invalidValue(key, value, _, _):
            return "Check if value \(value ?? "nil") is valid for key \(key)"
        case .unableToMakePaymentsOnProvidedNetworks:
            return nil
        case .unableToPresentPaymentMethod:
            let message = """
            Check if all necessary values have been provided on your client session.\
             You can find the necessary values on our documentation (website).
            """
            return message
        case let .unsupportedIntent(intent, _):
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
        case let .missingSDK(paymentMethodType, sdkName, _):
            return "Add \(sdkName) in your project so you can perform payments with \(paymentMethodType)"
        case .merchantError:
            return nil
        case .paymentFailed:
            return nil
        case .applePayTimedOut:
            return "Make sure you have an active internet connection and your Apple Pay configuration is correct."
        case .failedToCreatePayment, .failedToResumePayment:
            return nil
        case .invalidVaultedPaymentMethodId:
            return "Please provide the id of one of the vaulted payment methods that have been returned by the 'fetchVaultedPaymentMethods' function."
        case .nolError:
            return nil
        case .nolSdkInitError:
            return nil
        case .klarnaError:
            return nil
        case .klarnaUserNotApproved:
            return nil
        case .stripeError:
            return nil
        case .unableToPresentApplePay:
            let message = """
            PassKit was unable to present the Apple Pay UI. Check merchantIdentifier \
            and other parameters are set correctly for the current environment.
            """
            return message
        case .applePayNoCardsInWallet:
            return "The user needs to add cards to their Apple Wallet to use Apple Pay."
        case .applePayDeviceNotSupported:
            return "This device does not support Apple Pay. Apple Pay requires compatible hardware and iOS version."
        case .applePayConfigurationError:
            return """
            Check that the merchant identifier matches your Apple Developer configuration and \
            is valid for the current environment (sandbox/production).
            """
        case .applePayPresentationFailed:
            return "Unable to display Apple Pay sheet. This may be due to system restrictions or temporary issues. Try again later."
        case .unknown:
            return "Contact Primer and provide them diagnostics id \(diagnosticsId)"
        }
    }

    var exposedError: Error {
        self
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
        case let .cancelled(paymentMethodType, _),
             let .unableToPresentPaymentMethod(paymentMethodType, _, _),
             let .unsupportedPaymentMethod(paymentMethodType, _, _),
             let .missingSDK(paymentMethodType, _, _),
             let .paymentFailed(paymentMethodType?, _, _, _, _),
             let .failedToCreatePayment(paymentMethodType, _, _),
             let .failedToResumePayment(paymentMethodType, _, _):
            return paymentMethodType
        case .applePayTimedOut,
             .unableToMakePaymentsOnProvidedNetworks,
             .unableToPresentApplePay,
             .applePayNoCardsInWallet,
             .applePayDeviceNotSupported,
             .applePayConfigurationError,
             .applePayPresentationFailed:
            return PrimerPaymentMethodType.applePay.rawValue
        case .nolError,
             .nolSdkInitError:
            return PrimerPaymentMethodType.nolPay.rawValue
        default: return nil
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable file_length
