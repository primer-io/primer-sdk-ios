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
    var isReportable: Bool { get }
}

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

/// Errors that can occur during payment processing with the Primer SDK.
///
/// `PrimerError` provides detailed error information for debugging and user feedback.
/// Each error includes:
/// - A unique `errorId` for categorization
/// - A `diagnosticsId` for support requests
/// - Descriptive messages and recovery suggestions
///
/// Errors are organized into categories:
/// - **Configuration errors**: SDK not initialized, invalid tokens, missing configuration
/// - **Payment errors**: Payment failed, cancelled, or requires action
/// - **Payment method errors**: Unsupported methods, presentation failures
/// - **Provider-specific errors**: Apple Pay, Klarna, Stripe, etc.
///
/// Example usage:
/// ```swift
/// func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?) {
///     if let primerError = error as? PrimerError {
///         print("Error ID: \(primerError.errorId)")
///         print("Diagnostics ID: \(primerError.diagnosticsId)")
///         print("Recovery suggestion: \(primerError.recoverySuggestion ?? "None")")
///     }
/// }
/// ```
public enum PrimerError: PrimerErrorProtocol {
    typealias InfoType = [String: Any]

    /// The SDK session has not been initialized with a client token.
    case uninitializedSDKSession(diagnosticsId: String = .uuid)

    /// The provided client token is invalid or expired.
    case invalidClientToken(reason: String? = nil, diagnosticsId: String = .uuid)

    /// SDK configuration is missing (no API response received).
    case missingPrimerConfiguration(diagnosticsId: String = .uuid)

    /// Payment methods are not configured correctly in the dashboard.
    case misconfiguredPaymentMethods(diagnosticsId: String = .uuid)

    /// A required input element is missing from the form.
    case missingPrimerInputElement(inputElementType: PrimerInputElementType, diagnosticsId: String = .uuid)

    /// The user cancelled the payment flow.
    case cancelled(paymentMethodType: String, diagnosticsId: String = .uuid)

    /// Failed to create a client session.
    case failedToCreateSession(error: Error?, diagnosticsId: String = .uuid)

    /// An invalid URL was provided or constructed.
    case invalidUrl(url: String? = nil, diagnosticsId: String = .uuid)

    /// The current architecture or configuration is invalid.
    case invalidArchitecture(description: String, recoverSuggestion: String?, diagnosticsId: String = .uuid)

    /// A value in the client session is invalid.
    case invalidClientSessionValue(name: String, value: String? = nil, allowedValue: String? = nil, diagnosticsId: String = .uuid)

    /// The Apple Pay merchant identifier is invalid.
    case invalidMerchantIdentifier(merchantIdentifier: String? = nil, diagnosticsId: String = .uuid)

    /// A provided value is invalid for the given key.
    case invalidValue(key: String, value: Any? = nil, reason: String? = nil, diagnosticsId: String = .uuid)

    /// The device cannot make payments on the provided card networks.
    case unableToMakePaymentsOnProvidedNetworks(diagnosticsId: String = .uuid)

    /// Unable to present the specified payment method UI.
    case unableToPresentPaymentMethod(paymentMethodType: String, reason: String? = nil, diagnosticsId: String = .uuid)

    /// The current session intent is not supported for this operation.
    case unsupportedIntent(intent: PrimerSessionIntent, diagnosticsId: String = .uuid)

    /// The payment method type is not supported.
    case unsupportedPaymentMethod(paymentMethodType: String, reason: String? = nil, diagnosticsId: String = .uuid)

    /// The payment method is not supported by the specified manager.
    case unsupportedPaymentMethodForManager(paymentMethodType: String, category: String, diagnosticsId: String = .uuid)

    /// Multiple errors occurred during the operation.
    case underlyingErrors(errors: [Error], diagnosticsId: String = .uuid)

    /// A required SDK dependency is missing.
    case missingSDK(paymentMethodType: String, sdkName: String, diagnosticsId: String = .uuid)

    /// An error returned by merchant-side logic.
    case merchantError(message: String, diagnosticsId: String = .uuid)

    /// The payment was created but failed or ended in an unexpected status.
    case paymentFailed(
        paymentMethodType: String?,
        paymentId: String,
        orderId: String?,
        status: String,
        diagnosticsId: String = .uuid
    )

    /// Failed to redirect to the required URL.
    case failedToRedirect(url: String, diagnosticsId: String = .uuid)

    /// Failed to create the payment after tokenization.
    case failedToCreatePayment(paymentMethodType: String, description: String, diagnosticsId: String = .uuid)

    /// Failed to resume the payment after additional action.
    case failedToResumePayment(paymentMethodType: String, description: String, diagnosticsId: String = .uuid)

    /// Apple Pay authorization timed out.
    case applePayTimedOut(diagnosticsId: String = .uuid)

    /// The specified vaulted payment method ID does not exist.
    case invalidVaultedPaymentMethodId(vaultedPaymentMethodId: String, diagnosticsId: String = .uuid)

    /// An error from the NOL Pay SDK.
    case nolError(code: String?, message: String?, diagnosticsId: String = .uuid)

    /// NOL Pay SDK initialization failed.
    case nolSdkInitError(diagnosticsId: String = .uuid)

    /// An error from the Klarna SDK.
    case klarnaError(message: String?, diagnosticsId: String = .uuid)

    /// The user is not approved for Klarna payments.
    case klarnaUserNotApproved(diagnosticsId: String = .uuid)

    /// An error from the Stripe SDK.
    case stripeError(key: String, message: String?, diagnosticsId: String = .uuid)

    /// Unable to present Apple Pay (PassKit unavailable).
    case unableToPresentApplePay(diagnosticsId: String = .uuid)

    /// Apple Pay has no cards configured in the wallet.
    case applePayNoCardsInWallet(diagnosticsId: String = .uuid)

    /// The device does not support Apple Pay.
    case applePayDeviceNotSupported(diagnosticsId: String = .uuid)

    /// Apple Pay configuration error (merchant identifier issue).
    case applePayConfigurationError(merchantIdentifier: String?, diagnosticsId: String = .uuid)

    /// Apple Pay sheet could not be presented.
    case applePayPresentationFailed(reason: String?, diagnosticsId: String = .uuid)

    /// Failed to load design tokens from the bundle.
    case failedToLoadDesignTokens(fileName: String, diagnosticsId: String = .uuid)

    /// An unknown error occurred.
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
        case .failedToLoadDesignTokens: "failed-to-load-design-tokens"
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
             let .failedToLoadDesignTokens(_, id),
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
        case let .failedToLoadDesignTokens(fileName, _):
            return "Failed to load design tokens from file: \(fileName).json"
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
        case let .unableToPresentPaymentMethod(paymentMethodType, reason, _):
            var message = """
            The payment method '\(paymentMethodType)' is not available for this session. \
            In HEADLESS mode, only render payment methods that are returned in the 'availablePaymentMethods' \
            from the start() completion handler or 'listAvailablePaymentMethodsForCheckout()'.
            """
            if let reason = reason {
                message += " Reason: \(reason)."
            }
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
        case .failedToLoadDesignTokens:
            return "Check if the design tokens JSON file exists in the bundle and is properly formatted."
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

    var isReportable: Bool {
        switch self {
        case .nolError, .nolSdkInitError, .klarnaError, .stripeError,
             .failedToCreateSession, .failedToCreatePayment, .failedToResumePayment,
             .applePayConfigurationError, .applePayPresentationFailed,
             .unknown:
            true
        default:
            false
        }
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
