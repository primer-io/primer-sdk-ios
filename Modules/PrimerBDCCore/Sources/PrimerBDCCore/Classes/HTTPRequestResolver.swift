//
//  HTTPRequestResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

final class HTTPRequestResolver: StepResolver {

    private let logger = Logger()

    func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
        let params = try data.casted(to: Params.self)

        guard let url = URL(string: params.url) else {
            logger.error("http.request: invalid url '\(params.url)'")
            return StepResolutionResult(outcome: .error)
        }

        var request = URLRequest(url: url)
        request.httpMethod = params.method
        params.headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        if let body = params.body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("http.request: \(params.method) \(params.url) failed with status \(status)")
            return StepResolutionResult(outcome: .error)
        }

        let bodyValue = (try? JSONDecoder().decode(CodableValue.self, from: responseData)) ?? .null
        return StepResolutionResult(outcome: .success, data: .object(["body": bodyValue]))
    }
}

private extension HTTPRequestResolver {
    struct Params: Decodable {
        let url: String
        let method: String
        let headers: [String: String]?
        let body: CodableValue?
    }
}
