//
//  HTTPRequestResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking
@_spi(PrimerInternal) import PrimerStepResolver

struct HTTPRequestResolver: StepResolver, LogReporter {

    private let requestFactory: NetworkRequestFactory
    private let dispatcher: DefaultRequestDispatcher

    init(
        requestFactory: NetworkRequestFactory = DefaultNetworkRequestFactory(),
        dispatcher: DefaultRequestDispatcher = DefaultRequestDispatcher()
    ) {
        self.requestFactory = requestFactory
        self.dispatcher = dispatcher
    }

    func resolve(_ step: CodableValue) async throws -> StepResolutionResult {
        guard let params = try? step.casted(to: Params.self),
              let method = HTTPMethod(rawValue: params.method.uppercased()) else {
            logger.error(message: "http.request: invalid params")
            return StepResolutionResult(outcome: .error)
        }

        let endpoint = BDCHTTPRequestEndpoint(
            url: params.url,
            method: method,
            schemaHeaders: params.headers,
            body: params.body.flatMap { try? JSONEncoder().encode($0) },
            timeout: params.timeoutMs.map { TimeInterval($0) / 1000 }
        )

        do {
            let request = try requestFactory.request(for: endpoint, identifier: nil)
            let response = try await dispatcher.dispatch(request: request)
            return result(from: response)
        } catch {
            logger.error(message: "http.request: \(method.rawValue) \(params.url) failed: \(error)")
            return StepResolutionResult(outcome: .error)
        }
    }
    
    private func result(from response: DispatcherResponse) -> StepResolutionResult {
        let status = response.metadata.statusCode
        let ok = (200..<300).contains(status)

        var payload: [String: CodableValue] = ["status": .int(status), "ok": .bool(ok)]

        if let headers = response.metadata.headers {
            payload["headers"] = .object(headers.mapValues(CodableValue.string))
        }

        if let data = response.data, !data.isEmpty,
           let body = try? JSONDecoder().decode(CodableValue.self, from: data) {
            payload["body"] = body
        }

        return StepResolutionResult(outcome: ok ? .success : .error, data: .object(payload))
    }
}

private extension HTTPRequestResolver {
    struct Params: Decodable {
        let url: String
        let method: String
        let headers: [String: String]?
        let body: CodableValue?
        let timeoutMs: Int?
    }
}
