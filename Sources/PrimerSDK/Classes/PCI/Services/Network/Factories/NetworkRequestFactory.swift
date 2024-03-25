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

class DefaultNetworkRequestFactory: NetworkRequestFactory, LogReporter {

    func request(for endpoint: Endpoint) throws -> URLRequest {
        var request = try baseRequest(from: endpoint)
        
        request.httpMethod = endpoint.method.rawValue

        if let headers = endpoint.headers {
            request.allHTTPHeaderFields = headers
        }

        if endpoint.method != .get, let body = endpoint.body {
            request.httpBody = body
        }

        if let timeout = endpoint.timeout {
            request.timeoutInterval = timeout
        }

        log(request: request)

        return request
    }

    private func baseRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard let url = url(for: endpoint)
        else {
            // TODO: fix error
            throw InternalError.invalidUrl(url: nil, userInfo: nil, diagnosticsId: nil)
        }

        return URLRequest(url: url)
    }

    private func url(for endpoint: Endpoint) -> URL? {
        guard let urlStr = endpoint.baseURL else { return nil }
        guard let baseUrl = URL(string: urlStr) else { return nil }
        var url = baseUrl

        if endpoint.path != "" {
            url = baseUrl.appendingPathComponent(endpoint.path)
        }

        if let queryParameters = endpoint.queryParameters, !queryParameters.keys.isEmpty {
            var urlComponents = URLComponents(string: url.absoluteString)!
            var urlQueryItems: [URLQueryItem] = []

            for (key, val) in queryParameters {
                let urlQueryItem = URLQueryItem(name: key, value: val)
                urlQueryItems.append(urlQueryItem)
            }

            if !urlQueryItems.isEmpty {
                urlComponents.queryItems = urlQueryItems
            }

            let tmpUrl = urlComponents.url ?? url
            return tmpUrl
        }

        return url
    }

    private func log(request: URLRequest) {
        let method = request.httpMethod?.uppercased() ?? "Unknown Method"
        let url = request.url?.absoluteString ?? "Unknown URL"
        let headersDescription = request.allHTTPHeaderFields?.map { (key, value) in
            "  ► \(key): \(value)"
        } ?? ["No headers found"]
        let body = {
            guard let body = request.httpBody else { return "N/A" }
            return String(data: body, encoding: .utf8) ?? "N/A"
        }()

        logger.debug(message: """

🌎 [Request: \(method)] 👉 \(url)
Headers:
\(headersDescription.joined(separator: "\n"))
Body:
\(body)
""")
    }
}
