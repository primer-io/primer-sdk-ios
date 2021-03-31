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
            return "Failed to construct URL".localized()
        case .noToken:
            return "Failed to find client token".localized()
        case .noCoreUrl:
            return "Failed to find Core Base URL".localized()
        case .failedApiCall:
            return "API request failed".localized()
        case .noAmount:
            return "Failed to find amount".localized()
        case .noCurrency:
            return "Failed to find currency".localized()
        case .noPaymentMethodConfigId:
            return "Failed to find Klarna configuration".localized()
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
            return "Invalid url".localized()
        case .unauthorised:
            return "Unauthorized request".localized()
        case .noData:
            return "No data".localized()
        case .clientError(let statusCode, let data):
            return "Request failed with status code \(statusCode)".localized()
        case .serverError(let statusCode, let data):
            return "Request failed with status code \(statusCode)".localized()
        case .parsing(let error, let data):
            let response = String(data: data, encoding: .utf8) ?? ""
            return "Parsing error: \(error.localizedDescription)\n\nResponse:\n\(response)".localized()
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
            return "Client token is missing.".localized()
        case .customerIDNull:
            return "Customer ID is missing.".localized()
        case .payPalSessionFailed:
            return "PayPal checkout session failed. Your account has not been charged.".localized()
        case .vaultFetchFailed:
            return "Failed to fetch saved payment methods.".localized()
        case .vaultDeleteFailed:
            return "Failed to delete saved payment method.".localized()
        case .vaultCreateFailed:
            return "Failed to save payment method.".localized()
        case .directDebitSessionFailed:
            return "Failed to create a direct debit mandate.\n\n Please try again.".localized()
        case .configFetchFailed:
            return "Failed to setup session.".localized()
        case .tokenizationPreRequestFailed:
            return "Failed to complete action. Your payment method was not processed.".localized()
        case .tokenizationRequestFailed:
            return "Connection error, your payment method was not saved. Please try again.".localized()
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
