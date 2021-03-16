//
//  Error.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

import Foundation

enum KlarnaException: Error {
    case invalidUrl
    case noToken
    case noCoreUrl
    case failedApiCall
    case noAmount
    case noCurrency
    case noPaymentMethodConfigId
}

//enum OAuthError: Error {
//    case invalidURL
//}

//enum NetworkError: Error {
//    case missingParams
//    case unauthorised
//    case timeout
//    case serverError
//    case invalidResponse
//    case serializationError
//}

//enum APIError: Error {
//    case nullResponse
//    case statusError
//    case postError
//}

enum NetworkServiceError: Error {
    case invalidURL
    case unauthorised(_ info: PrimerErrorResponse?)
    case clientError(_ statusCode: Int, info: PrimerErrorResponse?)
    case serverError(_ statusCode: Int, info: PrimerErrorResponse?)
    case noData
    case parsing(_ error: Error, _ data: Data)
    case underlyingError(_ error: Error)            // Use this error when we have received an error JSON from the backend.
}

enum PrimerError: String, Error {
    case ClientTokenNull = "Client token is missing."
    case CustomerIDNull = "Customer ID is missing."
    case PayPalSessionFailed = "PayPal checkout session failed. Your account has not been charged."
    case VaultFetchFailed = "Failed to fetch saved payment methods."
    case VaultDeleteFailed = "Failed to delete saved payment method."
    case VaultCreateFailed = "Failed to save payment method."
    case DirectDebitSessionFailed = "Failed to create a direct debit mandate.\n\n Please try again."
    case ConfigFetchFailed = "Failed to setup session."
    case TokenizationPreRequestFailed = "Failed to complete action. Your payment method was not processed."
    case TokenizationRequestFailed = "Connection error, your payment method was not saved. Please try again."
}

enum PrimerAPIError: String, LocalizedError {
    case userEmailAlreadyExists = "UserEmailAlreadyExists"
    case ClientTokenNull = "Client token is missing."
    case CustomerIDNull = "Customer ID is missing."
    case PayPalSessionFailed = "PayPal checkout session failed. Your account has not been charged."
    case VaultFetchFailed = "Failed to fetch saved payment methods."
    case VaultDeleteFailed = "Failed to delete saved payment method."
    case VaultCreateFailed = "Failed to save payment method."
    case DirectDebitSessionFailed = "Failed to create a direct debit mandate.\n\n Please try again."
    case ConfigFetchFailed = "Failed to setup session."
    case TokenizationPreRequestFailed = "Failed to complete action. Your payment method was not processed."
    case TokenizationRequestFailed = "Connection error, your payment method was not saved. Please try again."
}

struct PrimerErrorResponse: Codable {
    var errorId: String
    var `description`: String
    var diagnosticsId: String
    var validationErrors: [String]
}
