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
    
    var errorUserInfo: [String : Any] {
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
    
    var errorUserInfo: [String : Any] {
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
    
    case ClientTokenNull
    case CustomerIDNull
    case PayPalSessionFailed
    case VaultFetchFailed
    case VaultDeleteFailed
    case VaultCreateFailed
    case DirectDebitSessionFailed
    case ConfigFetchFailed
    case TokenizationPreRequestFailed
    case TokenizationRequestFailed
    
    static var errorDomain: String = "primer"
    
    var errorCode: Int {
        switch self {
        default:
            // Define API error codes with Android & Web
            return 100
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        default:
            // Do we want more information on the errors? E.g. timestamps?
            return [:]
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .ClientTokenNull:
            return "Client token is missing.".localized()
        case .CustomerIDNull:
            return "Customer ID is missing.".localized()
        case .PayPalSessionFailed:
            return "PayPal checkout session failed. Your account has not been charged.".localized()
        case .VaultFetchFailed:
            return "Failed to fetch saved payment methods.".localized()
        case .VaultDeleteFailed:
            return "Failed to delete saved payment method.".localized()
        case .VaultCreateFailed:
            return "Failed to save payment method.".localized()
        case .DirectDebitSessionFailed:
            return "Failed to create a direct debit mandate.\n\n Please try again.".localized()
        case .ConfigFetchFailed:
            return "Failed to setup session.".localized()
        case .TokenizationPreRequestFailed:
            return "Failed to complete action. Your payment method was not processed.".localized()
        case .TokenizationRequestFailed:
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
