//
//  NetworkServiceError.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

extension NetworkServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid url"
        case .unauthorised:
            return "Unauthorized request"
        case .noData:
            return "No data"
        case .clientError(let statusCode, let data):
            return "Request failed with status code \(statusCode)"
        case .serverError(let statusCode, let data):
            return "Request failed with status code \(statusCode)"
        case .parsing(let error, let data):
            let response = String(data: data, encoding: .utf8) ?? ""
            return "Parsing error: \(error.localizedDescription)\n\nResponse:\n\(response)"
        case .underlyingError(let error):
            return error.localizedDescription
        }
    }
}
