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
    case noCoreUrl
    case failedApiCall
    case noAmount
    case noCurrency
    case noPaymentMethodConfigId

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
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to construct URL - Error message")
        case .noToken:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-client-token",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to find client token - Error message")
            
        case .noCoreUrl:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-base-url",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to find Core Base URL - Error message")
            
        case .failedApiCall:
            return NSLocalizedString("primer-klarna-error-message-api-request-failed",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "API request failed - Error message")
            
        case .noAmount:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-amount",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to find amount - Error message")
            
        case .noCurrency:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-currency",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to find currency - Error message")
            
        case .noPaymentMethodConfigId:
            return NSLocalizedString("primer-klarna-error-message-failed-to-find-klarna-configuration",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to find Klarna configuration - Error message")
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
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Invalid url - Network error message")
            
        case .unauthorised:
            return NSLocalizedString("primer-network-error-message-unauthorized-request",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Unauthorized request - Network error message")
            
        case .noData:
            return NSLocalizedString("primer-network-error-message-no-data",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "No data - Network error message")
            
        case .clientError(let statusCode, _):
            return NSLocalizedString("primer-network-error-message-request-failed-status-code",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Request failed with status code - Network error message") + " \(statusCode)"
            
        case .serverError(let statusCode, _):
            return NSLocalizedString("primer-network-error-message-request-failed-status-code",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
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
    case threeDSFailed

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
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Client token is missing - Primer error message")
            
        case .customerIDNull:
            return NSLocalizedString("primer-error-message-customer-id-missing",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Customer ID is missing - Primer error message")
            
        case .payPalSessionFailed:
            return NSLocalizedString("primer-error-message-paypal-needs-recharge",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "PayPal checkout session failed. Your account has not been charged. - Primer error message")
            
        case .vaultFetchFailed:
            return NSLocalizedString("primer-error-message-failed-to-fetch-saved-payment-methods",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to fetch saved payment methods - Primer error message")
            
        case .vaultDeleteFailed:
            return NSLocalizedString("primer-error-message-failed-to-delete-saved-payment-method",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to delete saved payment method - Primer error message")
            
        case .vaultCreateFailed:
            return NSLocalizedString("primer-error-message-failed-to-save-payment-method",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to save payment method - Primer error message")
            
        case .directDebitSessionFailed:
            return NSLocalizedString("primer-error-message-failed-to-create-direct-debit-mandate",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to create a direct debit mandate.\n\n Please try again. - Primer error message")
            
        case .configFetchFailed:
            return NSLocalizedString("primer-error-message-failed-to-setup-session",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to setup session - Primer error message")
            
        case .tokenizationPreRequestFailed:
            return NSLocalizedString("primer-error-message-failed-to-complete-action",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Failed to complete action. Your payment method was not processed. - Primer error message")
            
        case .tokenizationRequestFailed:
            return NSLocalizedString("primer-error-message-failed-to-save-payment",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Connection error, your payment method was not saved. Please try again. - Primer error message")
        case .threeDSFailed:
            return NSLocalizedString("primer-error-message-3ds-failed",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "3DS failed - Primer error message")
        }
    }

    var shouldBePresented: Bool {
        switch self {
        default:
            return true
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
