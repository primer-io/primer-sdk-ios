//
//  Error.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

#if canImport(UIKit)

import Foundation

internal protocol PrimerErrorProtocol: CustomNSError, LocalizedError {
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
    case orderItemMissesAmount

    static var errorDomain: String = "primer.klarna"

    var errorCode: Int {
        switch self {
        case .invalidUrl:
            return 4000
        case .noToken:
            return 4001
        case .undefinedSessionType:
            return 4002
        case .noCoreUrl:
            return 4003
        case .failedApiCall:
            return 4003
        case .noAmount:
            return 4004
        case .noCurrency:
            return 4005
        case .noCountryCode:
            return 4006
        case .noPaymentMethodConfigId:
            return 4006
        case .missingOrderItems:
            return 4007
        case .orderItemMissesAmount:
            return 4008
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
                                     value: "Failed to find country code",
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
            
        case .orderItemMissesAmount:
            return NSLocalizedString("primer-klarna-error-message-missing-order-item-amount",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to find amount for an order item",
                                     comment: "Failed to find amount for an order item - Error message")
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

    case generic
    case containerError(errors: [Error])
    case delegateNotSet
    case userCancelled
    
    case clientTokenNull
    case clientTokenExpirationMissing
    case clientTokenExpired
    
    case customerIDNull
    
    case missingURLScheme
    
    case amountMissing
    case amountShouldBeNullForPendingOrderItems
    case amountCannotBeNullForNonPendingOrderItems
    case currencyMissing
    
    case requestFailed
    case configFetchFailed
    case tokenizationPreRequestFailed
    case tokenizationRequestFailed
    case vaultFetchFailed
    case vaultCreateFailed
    case vaultDeleteFailed
    case payPalSessionFailed
    case directDebitSessionFailed
    case failedToLoadSession
    
    case invalidCardnumber, invalidExpiryDate, invalidCVV, invalidCardholderName

    static var errorDomain: String = "primer"

    var errorCode: Int {
        switch self {
        case .generic:
            return 0
        case .containerError:
            return 1
        case .delegateNotSet:
            return 500
        case .userCancelled:
            return 1500
            
        // Settings
        case .clientTokenNull:
            return 2001
        case .clientTokenExpirationMissing:
            return 2002
        case .clientTokenExpired:
            return 2003
            
        case .customerIDNull:
            return 1400
        
        case .missingURLScheme:
            return 1600
            
        case .amountMissing:
            return 1700
        case .amountShouldBeNullForPendingOrderItems:
            return 1710
        case .amountCannotBeNullForNonPendingOrderItems:
            return 1720
        case .currencyMissing:
            return 1800
            
        // Network
        case .requestFailed:
            return 2000
        case .configFetchFailed:
            return 2100
        case .tokenizationPreRequestFailed:
            return 2101
        case .tokenizationRequestFailed:
            return 2102
        case .vaultFetchFailed:
            return 2200
        case .vaultCreateFailed:
            return 2201
        case .vaultDeleteFailed:
            return 2202
        case .payPalSessionFailed:
            return 2300
        case .directDebitSessionFailed:
            return 2400
        case .failedToLoadSession:
            return 2500
            
        // Validation
        case .invalidCardnumber:
            return 3100
        case .invalidExpiryDate:
            return 3101
        case .invalidCVV:
            return 3102
        case .invalidCardholderName:
            return 3103
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
        case .generic:
            return NSLocalizedString("primer-error-message-generic",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Something went wrong",
                                     comment: "Something went wrong - Primer error message")
            
        case .containerError:
            return NSLocalizedString("primer-error-message-multiple-errors",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Multiple errors occured",
                                     comment: "Multiple errors occured - Primer error message")
            
        case .delegateNotSet:
            return NSLocalizedString("primer-error-message-delegate-not-set",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Delegate has not been set",
                                     comment: "Delegate has not been set - Primer error message")
            
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
            
        case .clientTokenExpired:
            return NSLocalizedString("primer-error-message-token-expired",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Token has expired",
                                     comment: "Token has expired - DX error message")

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
        case .failedToLoadSession:
            return NSLocalizedString("primer-error-message-failed-to-load-session",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to load session, please close and try again.",
                                     comment: "Failed to load session, please close and try again. - Primer error message")
            
        case .missingURLScheme:
            return NSLocalizedString("primer-error-message-missing-url-scheme",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "URL scheme & scheme identifier are missing from the settings.",
                                     comment: "URL scheme & scheme identifier are missing from the settings. - Primer error message")
        case .requestFailed:
            return NSLocalizedString("primer-error-message-request-failed",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Failed to make request",
                                     comment: "Failed to make request, please close and try again. - Primer error message")
        case .userCancelled:
            return NSLocalizedString("primer-error-message-user-cancelled",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "User cancelled",
                                     comment: "User cancelled. - Primer error message")
            
        case .amountShouldBeNullForPendingOrderItems:
            return NSLocalizedString("primer-error-message-amount-should-be-null-for-pending-order-items",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Amount should be null for order items with isPending == true",
                                     comment: "Amount should be null for order items with isPending == true - Primer error message")
            
        case .amountCannotBeNullForNonPendingOrderItems:
            return NSLocalizedString("primer-error-message-amount-cannot-be-null-for-non-pending-order-items",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Amount cannot be null for order items with isPending == false",
                                     comment: "Amount cannot be null for order items with isPending == false - Primer error message")
        case .clientTokenExpirationMissing:
            return NSLocalizedString("primer-error-message-client-token-expiration-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Client token expiration missing",
                                     comment: "Client token expiration missing - Primer error message")
        case .amountMissing:
            return NSLocalizedString("primer-error-message-amount-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Amount missing",
                                     comment: "Amount missing - Primer error message")
        case .currencyMissing:
            return NSLocalizedString("primer-error-message-currency-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Currency missing",
                                     comment: "Currency missing - Primer error message")
        case .invalidCardnumber:
            return NSLocalizedString("primer-error-message-invalid-cardnumber",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Invalid cardnumber",
                                     comment: "Invalid cardnumber - Primer error message")
        case .invalidExpiryDate:
            return NSLocalizedString("primer-error-message-invalid-expiry-date",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Invalid expiry",
                                     comment: "Invalid expiry - Primer error message")
            
        case .invalidCVV:
            return NSLocalizedString("primer-error-message-invalid-cvv",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Invalid cvv",
                                     comment: "Invalid cvv - Primer error message")
            
        case .invalidCardholderName:
            return NSLocalizedString("primer-error-message-invalid-cardholder-name",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Invalid cardholder name",
                                     comment: "Invalid cardholder name - Primer error message")
            
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
