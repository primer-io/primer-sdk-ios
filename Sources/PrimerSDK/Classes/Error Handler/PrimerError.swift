//
//  PrimerError.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

// swiftlint:disable file_length
// swiftlint:disable type_body_length

import Foundation
import UIKit

enum AnalyticsContextKeys {
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
    case uninitializedSDKSession(
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case invalidClientToken(
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case missingPrimerConfiguration(
        userInfo: [String: String]?,
        diagnosticsId: String
    )
    case misconfiguredPaymentMethods(
        userInfo: [String: String]?,
        diagnosticsId: String
    )
    case missingPrimerInputElement(
        inputElementType: PrimerInputElementType,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case cancelled(
        paymentMethodType: String,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case failedToCreateSession(
        error: Error?,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case invalidUrl(
        url: String?,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case invalidArchitecture(
        description: String,
        recoverSuggestion: String?,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case invalidClientSessionValue(
        name: String,
        value: String? = nil,
        allowedValue: String?,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case invalidMerchantIdentifier(
        merchantIdentifier: String?,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case invalidValue(
        key: String,
        value: Any? = nil,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case unableToMakePaymentsOnProvidedNetworks(
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case unableToPresentPaymentMethod(
        paymentMethodType: String,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case unsupportedIntent(
        intent: PrimerSessionIntent,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case unsupportedPaymentMethod(
        paymentMethodType: String,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case unsupportedPaymentMethodForManager(
        paymentMethodType: String,
        category: String,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case underlyingErrors(
        errors: [Error],
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case missingSDK(
        paymentMethodType: String,
        sdkName: String,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case merchantError(
        message: String,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case paymentFailed(
        paymentMethodType: String?,
        paymentId: String,
        orderId: String?,
        status: String,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case failedToCreatePayment(
        paymentMethodType: String,
        description: String,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case failedToResumePayment(
        paymentMethodType: String,
        description: String,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case applePayTimedOut(
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case invalidVaultedPaymentMethodId(
        vaultedPaymentMethodId: String,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case nolError(
        code: String?,
        message: String?,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case nolSdkInitError(
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case klarnaError(
        message: String?,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case klarnaUserNotApproved(
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case stripeError(
        key: String,
        message: String?,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case unableToPresentApplePay(
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case unknown(
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )

    public var errorId: String {
        switch self {
        case .uninitializedSDKSession: "uninitialized-sdk-session"
        case .invalidClientToken: "invalid-client-token"
        case .missingPrimerConfiguration: "missing-configuration"
        case .misconfiguredPaymentMethods: "misconfigured-payment-methods"
        case .missingPrimerInputElement: "missing-primer-input-element"
        case .cancelled: "payment-cancelled"
        case .failedToCreateSession: "failed-to-create-session"
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
        case let .stripeError(key, _, _, _): key
        case .unableToPresentApplePay: "unable-to-present-apple-pay"
        case .unknown: "unknown"
        }
    }

    public var underlyingErrorCode: String? {
        switch self {
        case let .nolError(code, _, _, _):
            return String(describing: code)
        default:
            return nil
        }
    }

    public var diagnosticsId: String {
        switch self {
        case let .uninitializedSDKSession(_, diagnosticsId): diagnosticsId
        case let .invalidClientToken(_, diagnosticsId): diagnosticsId
        case let .missingPrimerConfiguration(_, diagnosticsId): diagnosticsId
        case let .misconfiguredPaymentMethods(_, diagnosticsId): diagnosticsId
        case let .missingPrimerInputElement(_, _, diagnosticsId): diagnosticsId
        case let .cancelled(_, _, diagnosticsId): diagnosticsId
        case let .failedToCreateSession(_, _, diagnosticsId): diagnosticsId
        case let .invalidUrl(_, _, diagnosticsId): diagnosticsId
        case let .invalidArchitecture(_, _, _, diagnosticsId): diagnosticsId
        case let .invalidClientSessionValue(_, _, _, _, diagnosticsId): diagnosticsId
        case let .invalidMerchantIdentifier(_, _, diagnosticsId): diagnosticsId
        case let .invalidValue(_, _, _, diagnosticsId): diagnosticsId
        case let .unableToMakePaymentsOnProvidedNetworks(_, diagnosticsId): diagnosticsId
        case let .unableToPresentPaymentMethod(_, _, diagnosticsId): diagnosticsId
        case let .unableToPresentApplePay(_, diagnosticsId): diagnosticsId
        case let .unsupportedIntent(_, _, diagnosticsId): diagnosticsId
        case let .unsupportedPaymentMethod(_, _, diagnosticsId): diagnosticsId
        case let .unsupportedPaymentMethodForManager(_, _, _, diagnosticsId): diagnosticsId
        case let .underlyingErrors(_, _, diagnosticsId): diagnosticsId
        case let .missingSDK(_, _, _, diagnosticsId): diagnosticsId
        case let .merchantError(_, _, diagnosticsId): diagnosticsId
        case let .paymentFailed(_, _, _, _, _, diagnosticsId): diagnosticsId
        case let .applePayTimedOut(_, diagnosticsId): diagnosticsId
        case let .failedToCreatePayment(_, _, _, diagnosticsId): diagnosticsId
        case let .failedToResumePayment(_, _, _, diagnosticsId): diagnosticsId
        case let .invalidVaultedPaymentMethodId(_, _, diagnosticsId): diagnosticsId
        case let .nolError(_, _, _, diagnosticsId): diagnosticsId
        case let .nolSdkInitError(_, diagnosticsId): diagnosticsId
        case let .klarnaError(_, _, diagnosticsId): diagnosticsId
        case let .klarnaUserNotApproved(_, diagnosticsId): diagnosticsId
        case let .stripeError(_, _, _, diagnosticsId): diagnosticsId
        case let .unknown(_, diagnosticsId): diagnosticsId
        }
    }

    var plainDescription: String? {
        switch self {
        case .uninitializedSDKSession:
            return "[\(errorId)] SDK session has not been initialzed (diagnosticsId: \(diagnosticsId)"
        case .invalidClientToken:
            return "Client token is not valid"
        case .missingPrimerConfiguration:
            return "Missing SDK configuration"
        case let .missingPrimerInputElement(inputElementType, _, _):
            return "Missing primer input element for \(inputElementType)"
        case let .missingSDK(paymentMethodType, sdkName, _, _):
            return "\(paymentMethodType) configuration has been found, but dependency \(sdkName) is missing"
        case .misconfiguredPaymentMethods:
            return "Payment methods haven't been set up correctly"
        case let .cancelled(paymentMethodType, _, _):
            return "Payment method \(paymentMethodType) cancelled"
        case let .failedToCreateSession(error: error, _, _):
            return "Failed to create session with error: \(error?.localizedDescription ?? "nil")"
        case let .invalidArchitecture(description, _, _, _):
            return "\(description)"
        case let .invalidClientSessionValue(name, value, _, _, _):
            return "Invalid client session value for '\(name)' with value '\(value ?? "nil")'"
        case let .invalidUrl(url: url, _, _):
            return "Invalid URL: \(url ?? "nil")"
        case let .invalidMerchantIdentifier(merchantIdentifier, _, _):
            return "Invalid merchant identifier: \(merchantIdentifier == nil ? "nil" : "\(merchantIdentifier!)")"
        case let .invalidValue(key: key, value: value, _, _):
            return "Invalid value '\(value ?? "nil")' for key '\(key)'"
        case .unableToMakePaymentsOnProvidedNetworks:
            return "Unable to make payments on provided networks"
        case let .unableToPresentPaymentMethod(paymentMethodType, _, _):
            return "Unable to present payment method \(paymentMethodType)"
        case let .unsupportedIntent(intent, _, _):
            return "Unsupported session intent \(intent.rawValue)"
        case let .underlyingErrors(errors, _, _):
            return "Multiple errors occured: \(errors.combinedDescription)"
        case let .unsupportedPaymentMethod(paymentMethodType, _, _):
            return "Unsupported payment method type \(paymentMethodType)"
        case let .unsupportedPaymentMethodForManager(paymentMethodType, category, _, _):
            return "Payment method \(paymentMethodType) is not supported on \(category) manager"
        case let .merchantError(message, _, _):
            return message
        case let .paymentFailed(_, paymentId, _, status, _, _):
            return "The payment with id \(paymentId) was created or resumed but ended up in a \(status) status."
        case .applePayTimedOut:
            return "Apple Pay timed out"
        case let .failedToCreatePayment(_, description, _, _):
            return "\(description)"
        case let .failedToResumePayment(_, description, _, _):
            return "\(description)"
        case let .invalidVaultedPaymentMethodId(vaultedPaymentMethodId, _, _):
            return "The vaulted payment method with id '\(vaultedPaymentMethodId)' doesn't exist."
        case let .nolError(code, message, _, _):
            return "Nol SDK encountered an error: \(String(describing: code)), \(String(describing: message))"
        case .nolSdkInitError:
            return "Nol SDK initialization error"
        case let .klarnaError(message, _, _):
            return "Klarna wrapper SDK encountered an error: \(String(describing: message))"
        case .klarnaUserNotApproved:
            return "User is not approved to perform Klarna payments"
        case let .stripeError(_, message, _, _):
            return "Stripe wrapper SDK encountered an error: \(String(describing: message))"
        case .unableToPresentApplePay:
            return "Unable to present Apple Pay"
        case .unknown:
            return "Something went wrong"
        }
    }

    public var errorDescription: String? {
        return "[\(errorId)] \(plainDescription ?? "") (diagnosticsId: \(errorUserInfo["diagnosticsId"] as? String ?? "nil"))"
    }

    var info: InfoType? {
        var tmpUserInfo: [String: Any] = errorUserInfo

        switch self {
        case let .uninitializedSDKSession(userInfo, _),
             let .invalidClientToken(userInfo, _),
             let .missingPrimerConfiguration(userInfo, _),
             let .missingPrimerInputElement(_, userInfo, _),
             let .misconfiguredPaymentMethods(userInfo, _),
             let .cancelled(_, userInfo, _),
             let .failedToCreateSession(_, userInfo, _),
             let .invalidUrl(_, userInfo, _),
             let .invalidArchitecture(_, _, userInfo, _),
             let .invalidClientSessionValue(_, _, _, userInfo, _),
             let .invalidMerchantIdentifier(_, userInfo, _),
             let .invalidValue(_, _, userInfo, _),
             let .unableToMakePaymentsOnProvidedNetworks(userInfo, _),
             let .unableToPresentPaymentMethod(_, userInfo, _),
             let .unsupportedIntent(_, userInfo, _),
             let .unsupportedPaymentMethod(_, userInfo, _),
             let .unsupportedPaymentMethodForManager(_, _, userInfo, _),
             let .underlyingErrors(_, userInfo, _),
             let .missingSDK(_, _, userInfo, _),
             let .merchantError(_, userInfo, _),
             let .paymentFailed(_, _, _, _, userInfo, _),
             let .applePayTimedOut(userInfo, _),
             let .failedToCreatePayment(_, _, userInfo, _),
             let .failedToResumePayment(_, _, userInfo, _),
             let .invalidVaultedPaymentMethodId(_, userInfo, _),
             let .nolError(_, _, userInfo, _),
             let .nolSdkInitError(userInfo, _),
             let .klarnaError(_, userInfo, _),
             let .klarnaUserNotApproved(userInfo, _),
             let .stripeError(_, _, userInfo, _),
             let .unableToPresentApplePay(userInfo, _),
             let .unknown(userInfo, _):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { _, new in new }
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
        case let .missingPrimerInputElement(inputElementtype, _, _):
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
        case .invalidUrl:
            return nil
        case let .invalidArchitecture(_, recoverySuggestion, _, _):
            return recoverySuggestion
        case let .invalidClientSessionValue(name, _, allowedValue, _, _):
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
        case let .unsupportedIntent(intent, _, _):
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
        case let .missingSDK(paymentMethodType, sdkName, _, _):
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
        case .unknown:
            return "Contact Primer and provide them diagnostics id \(diagnosticsId)"
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
        case let .cancelled(paymentMethodType, _, _),
             let .unableToPresentPaymentMethod(paymentMethodType, _, _),
             let .unsupportedPaymentMethod(paymentMethodType, _, _),
             let .missingSDK(paymentMethodType, _, _, _),
             let .paymentFailed(paymentMethodType?, _, _, _, _, _),
             let .failedToCreatePayment(paymentMethodType, _, _, _),
             let .failedToResumePayment(paymentMethodType, _, _, _):
            return paymentMethodType
        case .applePayTimedOut,
             .unableToMakePaymentsOnProvidedNetworks:
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
