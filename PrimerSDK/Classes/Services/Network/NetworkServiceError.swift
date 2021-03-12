//
//  NetworkServiceError.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

enum NetworkServiceError: Error {
    case invalidURL
    case noData
    case parsing(_ error: Error, _ data: Data)
    case error(_ error: Error)
}

extension NetworkServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid url"
        case .noData:
            return "No data"
        case .parsing(let error, let data):
            let response = String(data: data, encoding: .utf8) ?? ""
            return "Parsing error: \(error.localizedDescription)\n\nResponse:\n\(response)"
        case .error(let error):
            return error.localizedDescription
        }
    }
}
