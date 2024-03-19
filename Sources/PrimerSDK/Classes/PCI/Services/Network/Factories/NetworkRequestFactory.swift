//
//  NetworkRequestFactory.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 14/03/2024.
//

import Foundation

protocol NetworkRequestFactory {
    func request(for endpoint: Endpoint) throws -> URLRequest
}

class DefaultNetworkRequestFactory: NetworkRequestFactory {

    func request(for endpoint: Endpoint) throws -> URLRequest {
        var request = try baseRequest(from: endpoint)
        
        request.httpMethod = endpoint.method.rawValue

        if let headers = endpoint.headers {
            add(headers: headers, toRequest: &request)
        }

        if endpoint.method != .get, let body = endpoint.body {
            request.httpBody = body
        }

        if let timeout = endpoint.timeout {
            request.timeoutInterval = timeout
        }

        return request
    }

    private func baseRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard let baseURL = endpoint.baseURL,
              let url = URL(string: "\(baseURL)\(endpoint.path)")
        else {
            // TODO: fix error
            throw InternalError.invalidUrl(url: nil, userInfo: nil, diagnosticsId: nil)
        }

        return URLRequest(url: url)
    }

    private func add(headers: [String: String], toRequest request: inout URLRequest) {
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
    }
}
