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
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidClientToken(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case missingPrimerConfiguration(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case misconfiguredPaymentMethods(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case missingPrimerInputElement(
        inputElementType: PrimerInputElementType,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case cancelled(
        paymentMethodType: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case failedToCreateSession(
        error: Error?,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidUrl(
        url: String?,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
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
        allowedValue: String? = nil,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidMerchantIdentifier(
        merchantIdentifier: String? = nil,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidValue(
        key: String,
        value: Any? = nil,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case unableToMakePaymentsOnProvidedNetworks(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case unableToPresentPaymentMethod(
        paymentMethodType: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case unsupportedIntent(
        intent: PrimerSessionIntent,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case unsupportedPaymentMethod(
        paymentMethodType: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case unsupportedPaymentMethodForManager(
        paymentMethodType: String,
        category: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case underlyingErrors(
        errors: [Error],
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case missingSDK(
        paymentMethodType: String,
        sdkName: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case merchantError(
        message: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case paymentFailed(
        paymentMethodType: String?,
        paymentId: String,
        orderId: String?,
        status: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case failedToCreatePayment(
        paymentMethodType: String,
        description: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case failedToResumePayment(
        paymentMethodType: String,
        description: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case applePayTimedOut(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case invalidVaultedPaymentMethodId(
        vaultedPaymentMethodId: String,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case nolError(
        code: String?,
        message: String?,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case nolSdkInitError(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case klarnaError(
        message: String?,
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case klarnaUserNotApproved(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case stripeError(
        key: String,
        message: String?,
        userInfo: [String: String]?,
        diagnosticsId: String = .uuid
    )
    case unableToPresentApplePay(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )
    case unknown(
        userInfo: [String: String]? = .errorUserInfoDictionary(),
        diagnosticsId: String = .uuid
    )

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
        case .invalidArchitecture:
            return "invalid-architecture"
        case .invalidClientSessionValue:
            return "invalid-client-session-value"
        case .invalidUrl:
            return "invalid-url"
        case .invalidMerchantIdentifier:
            return "invalid-merchant-identifier"
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
        case .failedToCreatePayment:
            return "failed-to-create-payment"
        case .failedToResumePayment:
            return "failed-to-resume-payment"
        case .invalidVaultedPaymentMethodId:
            return "invalid-vaulted-payment-method-id"
        case .nolError:
            return "nol-pay-sdk-error"
        case .nolSdkInitError:
            return "nol-pay-sdk-init-error"
        case .klarnaError:
            return "klarna-sdk-error"
        case .klarnaUserNotApproved:
            return "klarna-user-not-approved"
        case .stripeError(let key, _, _, _):
            return key
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
        case .invalidUrl(_, _, let diagnosticsId):
            return diagnosticsId
        case .invalidArchitecture(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidClientSessionValue(_, _, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidMerchantIdentifier(_, _, let diagnosticsId):
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
        case .paymentFailed(_, _, _, _, _, let diagnosticsId):
            return diagnosticsId
        case .applePayTimedOut(_, let diagnosticsId):
            return diagnosticsId
        case .failedToCreatePayment(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .failedToResumePayment(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .invalidVaultedPaymentMethodId(_, _, let diagnosticsId):
            return diagnosticsId
        case .nolError(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .nolSdkInitError(_, let diagnosticsId):
            return diagnosticsId
        case .klarnaError(_, _, let diagnosticsId):
            return diagnosticsId
        case .klarnaUserNotApproved(_, let diagnosticsId):
            return diagnosticsId
        case .stripeError(_, _, _, let diagnosticsId):
            return diagnosticsId
        case .unknown(_, let diagnosticsId):
            return diagnosticsId
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
        case .invalidArchitecture(let description, _, _, _):
            return "\(description)"
        case .invalidClientSessionValue(let name, let value, _, _, _):
            return "Invalid client session value for '\(name)' with value '\(value ?? "nil")'"
        case .invalidUrl(url: let url, _, _):
            return "Invalid URL: \(url ?? "nil")"
        case .invalidMerchantIdentifier(let merchantIdentifier, _, _):
            return "Invalid merchant identifier: \(merchantIdentifier == nil ? "nil" : "\(merchantIdentifier!)")"
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
        case .paymentFailed(_, let paymentId, _, let status, _, _):
            return "The payment with id \(paymentId) was created or resumed but ended up in a \(status) status."
        case .applePayTimedOut:
            return "Apple Pay timed out"
        case .failedToCreatePayment(_, let description, _, _):
            return "\(description)"
        case .failedToResumePayment(_, let description, _, _):
            return "\(description)"
        case .invalidVaultedPaymentMethodId(let vaultedPaymentMethodId, _, _):
            return "The vaulted payment method with id '\(vaultedPaymentMethodId)' doesn't exist."
        case .nolError(let code, let message, _, _):
            return "Nol SDK encountered an error: \(String(describing: code)), \(String(describing: message))"
        case .nolSdkInitError:
            return "Nol SDK initialization error"
        case .klarnaError(let message, _, _):
            return "Klarna wrapper SDK encountered an error: \(String(describing: message))"
        case .klarnaUserNotApproved:
            return "User is not approved to perform Klarna payments"
        case .stripeError(_, let message, _, _):
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
        case .uninitializedSDKSession(let userInfo, _),
             .invalidClientToken(let userInfo, _),
             .missingPrimerConfiguration(let userInfo, _),
             .missingPrimerInputElement(_, let userInfo, _),
             .misconfiguredPaymentMethods(let userInfo, _),
             .cancelled(_, let userInfo, _),
             .failedToCreateSession(_, let userInfo, _),
             .invalidUrl(_, let userInfo, _),
             .invalidArchitecture(_, _, let userInfo, _),
             .invalidClientSessionValue(_, _, _, let userInfo, _),
             .invalidMerchantIdentifier(_, let userInfo, _),
             .invalidValue(_, _, let userInfo, _),
             .unableToMakePaymentsOnProvidedNetworks(let userInfo, _),
             .unableToPresentPaymentMethod(_, let userInfo, _),
             .unsupportedIntent(_, let userInfo, _),
             .unsupportedPaymentMethod(_, let userInfo, _),
             .unsupportedPaymentMethodForManager(_, _, let userInfo, _),
             .underlyingErrors(_, let userInfo, _),
             .missingSDK(_, _, let userInfo, _),
             .merchantError(_, let userInfo, _),
             .paymentFailed(_, _, _, _, let userInfo, _),
             .applePayTimedOut(let userInfo, _),
             .failedToCreatePayment(_, _, let userInfo, _),
             .failedToResumePayment(_, _, let userInfo, _),
             .invalidVaultedPaymentMethodId(_, let userInfo, _),
             .nolError(_, _, let userInfo, _),
             .nolSdkInitError(let userInfo, _),
             .klarnaError(_, let userInfo, _),
             .klarnaUserNotApproved(let userInfo, _),
             .stripeError(_, _, let userInfo, _),
             .unableToPresentApplePay(let userInfo, _),
             .unknown(let userInfo, _):
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
        case .invalidUrl:
            return nil
        case .invalidArchitecture(_, let recoverySuggestion, _, _):
            return recoverySuggestion
        case .invalidClientSessionValue(let name, _, let allowedValue, _, _):
            var str = "Check if you have provided a valid value for \"\(name)\" in your client session."
            if let allowedValue {
                str += " Allowed values are [\(allowedValue)]."
            }
            return str
        case .invalidMerchantIdentifier:
            return "Check if you have provided a valid merchant identifier in the SDK settings."
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
        case .cancelled(let paymentMethodType, _, _),
             .unableToPresentPaymentMethod(let paymentMethodType, _, _),
             .unsupportedPaymentMethod(let paymentMethodType, _, _),
             .missingSDK(let paymentMethodType, _, _, _),
             .paymentFailed(let paymentMethodType?, _, _, _, _, _),
             .failedToCreatePayment(let paymentMethodType, _, _, _),
             .failedToResumePayment(let paymentMethodType, _, _, _):
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
