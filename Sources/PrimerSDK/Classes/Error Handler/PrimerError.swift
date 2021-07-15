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

enum ThreeDSError: PrimerErrorProtocol {
    var shouldBePresented: Bool {
        return false
    }
    
    
    case failedToParseResponse
    
    static var errorDomain: String = "primer.3DS"
    
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
        case .failedToParseResponse:
            return NSLocalizedString("primer-3DS-error-message-failed-to-parse-response",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to parse 3DS response - Primer error message")
        }
    }
    
}

enum PrimerError: PrimerErrorProtocol {

    case generic
    case clientTokenNull
    case customerIDNull
    case tokenExpired
    case payPalSessionFailed
    case vaultFetchFailed
    case vaultDeleteFailed
    case vaultCreateFailed
    case requestFailed
    case directDebitSessionFailed
    case configFetchFailed
    case tokenizationPreRequestFailed
    case tokenizationRequestFailed
    case threeDSFailed
    case failedToLoadSession
    case missingURLScheme
    case userCancelled
    case amountShouldBeNullForPendingOrderItems
    case amountCannotBeNullForNonPendingOrderItems
    case currencyMissing
    case amountMissing
    case billingAddressMissing
    case billingAddressCityMissing
    case billingAddressAddressLine1Missing
    case billingAddressPostalCodeMissing
    case billingAddressCountryCodeMissing
    case userDetailsAddressMissing
    case userDetailsCityMissing
    case userDetailsAddressLine1Missing
    case userDetailsPostalCodeMissing
    case userDetailsCountryCodeMissing
    case orderIdMissing
    case userDetailsMissing
    case dataMissing(description: String)
    
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
        case .generic:
            return NSLocalizedString("primer-error-message-generic",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Something went wrong",
                                     comment: "Something went wrong - Primer error message")
            
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
            
        case .tokenExpired:
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
        case .threeDSFailed:
            return NSLocalizedString("primer-error-message-3ds-failed",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "3DS failed - Primer error message")
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
        case .currencyMissing:
            return NSLocalizedString("primer-error-message-currency-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Currency is missing",
                                     comment: "Currency is missing - Primer error message")
        case .amountMissing:
            return NSLocalizedString("primer-error-message-amount-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Amount is missing",
                                     comment: "Amount is missing - Primer error message")
        case .billingAddressMissing:
            return NSLocalizedString("primer-error-billing-address-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Billing address is missing",
                                     comment: "Billing address is missing - Primer error message")
        case .billingAddressCityMissing:
            return NSLocalizedString("primer-error-billing-address-city-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Billing address city is missing",
                                     comment: "Billing address city is missing - Primer error message")
        case .billingAddressPostalCodeMissing:
            return NSLocalizedString("primer-error-billing-address-postal-code-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Billing address postal code is missing",
                                     comment: "Billing address postal code is missing - Primer error message")
        case .billingAddressCountryCodeMissing:
            return NSLocalizedString("primer-error-billing-address-country-code-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Billing address country code is missing",
                                     comment: "Billing address country code is missing - Primer error message")
        case .orderIdMissing:
            return NSLocalizedString("primer-error-order-id-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Order ID is missing",
                                     comment: "Order ID is missing - Primer error message")
        case .billingAddressAddressLine1Missing:
            return NSLocalizedString("primer-error-billing-address-line1-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Address line 1 is missing",
                                     comment: "Address line 1 is missing - Primer error message")
        case .userDetailsMissing:
            return NSLocalizedString("primer-error-user-details-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "User details are missing",
                                     comment: "User details are missing - Primer error message")
        case .userDetailsAddressMissing:
            return NSLocalizedString("primer-error-user-details-address-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "User details address is missing",
                                     comment: "User details address is missing - Primer error message")
        
        case .userDetailsCityMissing:
            return NSLocalizedString("primer-error-user-details-address-city-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "User details city is missing",
                                     comment: "User details city is missing - Primer error message")
            
        case .userDetailsPostalCodeMissing:
            return NSLocalizedString("primer-error-user-details-address-postal-code-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "User details postal code is missing",
                                     comment: "User details postal code is missing - Primer error message")
            
        case .userDetailsCountryCodeMissing:
            return NSLocalizedString("primer-error-user-details-address-country-code-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "User details country code is missing",
                                     comment: "User details country code is missing - Primer error message")
            
        case .userDetailsAddressLine1Missing:
            return NSLocalizedString("primer-error-user-details-address-line1-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "User details address line 1 is missing",
                                     comment: "User details address line 1 is missing - Primer error message")
            
        case .dataMissing(let description):
            return NSLocalizedString("primer-error-data-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Data are missing: \(description)",
                                     comment: "Data are missing - Primer error message")
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
