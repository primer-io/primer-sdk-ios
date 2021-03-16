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
    case noData
    case parsing(_ error: Error, _ data: Data)
    case underlyingError(_ error: Error)
}
