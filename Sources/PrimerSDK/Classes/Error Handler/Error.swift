//
//  Error.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

#if canImport(UIKit)

import Foundation

protocol PrimerErrorProtocol: CustomNSError, LocalizedError {
    var shouldBePresented: Bool { get }
}

enum KlarnaException: PrimerErrorProtocol {

    case invalidUrl
    case noToken
    case undefinedSessionType
    case noCoreUrl
    case failedApiCall
    case noAmount
    case noCurrency
    case noCountryCode
    case noPaymentMethodConfigId
    case missingOrderItems

    static var errorDomain: String = "primer.klarna"

    var errorCode: Int {
        switch self {
        default:
            // Define API error codes with Android & Web
            return 100
        }
    }

    var errorUserInfo: [String: Any] {
        switch self {
        default:
            // Do we want more information on the errors? E.g. timestamps?
            return [:]
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return NSLocalizedString("primer-klarna-error-message-failed-url-construction",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to construct URL",
                                     comment: "Failed to construct URL - Error message")
        case .noToken:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-client-token",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to find client token",
                                     comment: "Failed to find client token - Error message")
            
        case .undefinedSessionType:
            return NSLocalizedString("primer-klarna-error-message-undefined-session-type",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Undefined session type",
                                     comment: "Undefined Klarna session type - Error message")

        case .noCoreUrl:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-base-url",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to find Core Base URL",
                                     comment: "Failed to find Core Base URL - Error message")

        case .failedApiCall:
            return NSLocalizedString("primer-klarna-error-message-api-request-failed",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "API request failed",
                                     comment: "API request failed - Error message")

        case .noAmount:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-amount",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to find amount",
                                     comment: "Failed to find amount - Error message")

        case .noCurrency:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-currency",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to find currency",
                                     comment: "Failed to find currency - Error message")
            
        case .noCountryCode:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-country-code",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to find currency",
                                     comment: "Failed to find country code - Error message")

        case .noPaymentMethodConfigId:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-klarna-configuration",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to find Klarna configuration",
                                     comment: "Failed to find Klarna configuration - Error message")
            
        case .missingOrderItems:
            return NSLocalizedString("primer-klarna-error-message-missing-order-items",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to find Klarna order items",
                                     comment: "Failed to find Klarna order items - Error message")
        }
    }

    var shouldBePresented: Bool {
        switch self {
        default:
            return true
        }
    }

}

enum NetworkServiceError: PrimerErrorProtocol {

    case invalidURL
    case unauthorised(_ info: PrimerErrorResponse?)
    case clientError(_ statusCode: Int, info: PrimerErrorResponse?)
    case serverError(_ statusCode: Int, info: PrimerErrorResponse?)
    case noData
    case parsing(_ error: Error, _ data: Data)
    case underlyingError(_ error: Error)            // Use this error when we have received an error JSON from the backend.

    static var errorDomain: String = "primer.network"

    var errorCode: Int {
        switch self {
        default:
            // Define API error codes with Android & Web
            return 100
        }
    }

    var errorUserInfo: [String: Any] {
        switch self {
        default:
            // Do we want more information on the errors? E.g. timestamps?
            return [:]
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("primer-network-error-message-invalid-url",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Invalid url",
                                     comment: "Invalid url - Network error message")

        case .unauthorised:
            return NSLocalizedString("primer-network-error-message-unauthorized-request",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Unauthorized request",
                                     comment: "Unauthorized request - Network error message")

        case .noData:
            return NSLocalizedString("primer-network-error-message-no-data",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "No data",
                                     comment: "No data - Network error message")

        case .clientError(let statusCode, _):
            return NSLocalizedString("primer-network-error-message-request-failed-status-code",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Request failed with status code",
                                     comment: "Request failed with status code - Network error message") + " \(statusCode)"

        case .serverError(let statusCode, _):
            return NSLocalizedString("primer-network-error-message-request-failed-status-code",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Request failed with status code",
                                     comment: "Request failed with status code - Network error message") + " \(statusCode)"

        case .parsing(let error, let data):
            let response = String(data: data, encoding: .utf8) ?? ""
            return "Parsing error: \(error.localizedDescription)\n\nResponse:\n\(response)"

        case .underlyingError(let error):
            return error.localizedDescription
        }
    }

    var shouldBePresented: Bool {
        switch self {
        default:
            return true
        }
    }

}

enum PrimerError: PrimerErrorProtocol {

    case clientTokenNull
    case customerIDNull
    case payPalSessionFailed
    case vaultFetchFailed
    case vaultDeleteFailed
    case vaultCreateFailed
    case directDebitSessionFailed
    case configFetchFailed
    case tokenizationPreRequestFailed
    case tokenizationRequestFailed

    static var errorDomain: String = "primer"

    var errorCode: Int {
        switch self {
        default:
            // Define API error codes with Android & Web
            return 100
        }
    }

    var errorUserInfo: [String: Any] {
        switch self {
        default:
            // Do we want more information on the errors? E.g. timestamps?
            return [:]
        }
    }

    var errorDescription: String? {
        switch self {
        case .clientTokenNull:
            return NSLocalizedString("primer-error-message-client-token-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Client token is missing",
                                     comment: "Client token is missing - Primer error message")

        case .customerIDNull:
            return NSLocalizedString("primer-error-message-customer-id-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Customer ID is missing",
                                     comment: "Customer ID is missing - Primer error message")

        case .payPalSessionFailed:
            return NSLocalizedString("primer-error-message-paypal-needs-recharge",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "PayPal checkout session failed. Your account has not been charged.",
                                     comment: "PayPal checkout session failed. Your account has not been charged. - Primer error message")

        case .vaultFetchFailed:
            return NSLocalizedString("primer-error-message-failed-to-fetch-saved-payment-methods",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to fetch saved payment methods",
                                     comment: "Failed to fetch saved payment methods - Primer error message")

        case .vaultDeleteFailed:
            return NSLocalizedString("primer-error-message-failed-to-delete-saved-payment-method",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to delete saved payment method",
                                     comment: "Failed to delete saved payment method - Primer error message")

        case .vaultCreateFailed:
            return NSLocalizedString("primer-error-message-failed-to-save-payment-method",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to save payment method",
                                     comment: "Failed to save payment method - Primer error message")

        case .directDebitSessionFailed:
            return NSLocalizedString("primer-error-message-failed-to-create-direct-debit-mandate",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to create a direct debit mandate.\n\n Please try again.",
                                     comment: "Failed to create a direct debit mandate.\n\n Please try again. - Primer error message")

        case .configFetchFailed:
            return NSLocalizedString("primer-error-message-failed-to-setup-session",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to setup session",
                                     comment: "Failed to setup session - Primer error message")

        case .tokenizationPreRequestFailed:
            return NSLocalizedString("primer-error-message-failed-to-complete-action",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to complete action. Your payment method was not processed.",
                                     comment: "Failed to complete action. Your payment method was not processed. - Primer error message")

        case .tokenizationRequestFailed:
            return NSLocalizedString("primer-error-message-failed-to-save-payment",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Connection error, your payment method was not saved. Please try again.",
                                     comment: "Connection error, your payment method was not saved. Please try again. - Primer error message")
        }
    }

    var shouldBePresented: Bool {
        switch self {
        default:
            return true
        }
    }

}

enum PaymentException: PrimerErrorProtocol {
    
    case missingConfigurationId
    case missingClientToken
    case missingCountryCode
    case missingCurrency
    case missingAmount
    case missingOrderItems
    case missingPrimerDelegate
    
    var shouldBePresented: Bool {
        return false
    }
    
    static var errorDomain: String = "primer.payments"

    var errorCode: Int {
        switch self {
        default:
            // Define API error codes with Android & Web
            return 100
        }
    }

    var errorUserInfo: [String: Any] {
        switch self {
        default:
            // Do we want more information on the errors? E.g. timestamps?
            return [:]
        }
    }

    var errorDescription: String? {
        switch self {
        case .missingConfigurationId:
            return NSLocalizedString("primer-payments-error-message-missing-config-id",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Configuration ID is missing from settings. Please provide a configuration ID.",
                                     comment: "Configuration ID is missing from settings. Please provide a configuration ID. - Error message")
            
        case .missingClientToken:
            return NSLocalizedString("primer-payments-error-message-missing-client-token",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Client token is missing. Please provide a client token from your backend.",
                                     comment: "Client token is missing. Please provide a client token from your backend. - Error message")
            
        case .missingCountryCode:
            return NSLocalizedString("primer-payments-error-message-missing-country-code",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Country code is missing. Please provide a country code in settings.",
                                     comment: "Country code is missing. Please provide a country code in settings. - Error message")
            
        case .missingCurrency:
            return NSLocalizedString("primer-payments-error-message-missing-currency",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Currency is missing. Please provide currency in settings.",
                                     comment: "Currency is missing. Please provide currency in settings. - Error message")
            
        case .missingAmount:
            return NSLocalizedString("primer-payments-error-message-missing-amount",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Amount is missing. Please provide an amount in settings.",
                                     comment: "Amount is missing. Please provide an amount in settings. - Error message")
            
        case .missingOrderItems:
            return NSLocalizedString("primer-payments-error-message-missing-order-items",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Order items are missing. Please provide some order items in settings.",
                                     comment: "Order items are missing. Please provide some order items in settings. - Error message")
        case .missingPrimerDelegate:
            return NSLocalizedString("primer-payments-error-message-missing-primer-delegate",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Primer delegate is missing. Please set the delegate of Primer.",
                                     comment: "Primer delegate is missing. Please set the delegate of Primer. - Error message")
        }
    }
    
}

enum AppleException: PrimerErrorProtocol {
    
    case cancelled
    case missingSupportedPaymentNetworks
    case missingMerchantCapabilities
    case missingMerchantIdentifier
    case unableToMakePaymentsOnProvidedNetworks
    case unableToPresentApplePay
    
    var shouldBePresented: Bool {
        return false
    }
    
    static var errorDomain: String = "primer.apple"

    var errorCode: Int {
        switch self {
        default:
            // Define API error codes with Android & Web
            return 100
        }
    }

    var errorUserInfo: [String: Any] {
        switch self {
        default:
            // Do we want more information on the errors? E.g. timestamps?
            return [:]
        }
    }

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return NSLocalizedString("primer-apple-error-message-cancelled",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Apple Pay was cancelled",
                                     comment: "Apple Pay was cancelled. - Error message")
            
        case .missingSupportedPaymentNetworks:
            return NSLocalizedString("primer-apple-error-message-missing-supported-payment-networks",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Supported networks are missing from settings. Please provide some supported payment networks.",
                                     comment: "Supported networks are missing from settings. Please provide some supported payment networks. - Error message")
            
        case .missingMerchantCapabilities:
            return NSLocalizedString("primer-apple-error-message-missing-merchant-capabilities",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Merchant capabilities are missing from settings. Please provide some merchant capabilities.",
                                     comment: "Merchant capabilities are missing from settings. Please provide some merchant capabilities. - Error message")
            
        case .missingMerchantIdentifier:
            return NSLocalizedString("primer-apple-error-message-missing-merchant-identifier",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Merchant identifier is missing from settings. Please provide a merchant identifier that is also included in your entitlements.",
                                     comment: "Merchant identifier is missing from settings. Please provide a merchant identifier that is also included in your entitlements. - Error message")
            
        case .unableToMakePaymentsOnProvidedNetworks:
            return NSLocalizedString("primer-apple-error-message-unable-to-make-payment-on-payment-networks",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Unable to make payments on provided payment networks.",
                                     comment: "Unable to make payments on provided payment networks. - Error message")
        case .unableToPresentApplePay:
            return NSLocalizedString("primer-apple-error-message-unable-to-present-apple-pay",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Unable to present Apple Pay.",
                                     comment: "Unable to present Apple Pay. - Error message")
        }
    }
    
}

struct PrimerErrorResponse: Codable {
    var errorId: String
    var `description`: String
    var diagnosticsId: String
    var validationErrors: [String]
}

#endif
