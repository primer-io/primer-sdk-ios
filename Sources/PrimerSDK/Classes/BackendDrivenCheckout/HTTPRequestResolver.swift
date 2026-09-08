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
    private let dispatcher: any RequestDispatcher

    init(
        requestFactory: NetworkRequestFactory = DefaultNetworkRequestFactory(),
        dispatcher: any RequestDispatcher = DefaultRequestDispatcher()
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
            let policy = params.retry ?? RetryPolicy()
            var attempt = 1
            while true {
                let response = try await dispatcher.dispatch(request: request)
                let code = response.metadata.statusCode

                guard attempt < policy.maxAttempts, policy.shouldRetry(status: code) else { return result(from: response) }

                logger.warn(message: "http.request: \(code) on attempt \(attempt)/\(policy.maxAttempts), retrying")
                let delay = policy.delay(after: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                attempt += 1
            }
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

extension HTTPRequestResolver {
    struct Params: Decodable {
        let url: String
        let method: String
        let headers: [String: String]?
        let body: CodableValue?
        let timeoutMs: Int?
        let retry: RetryPolicy?
    }
    
    struct RetryPolicy {
        enum Backoff: String, Decodable {
            case exponential
            case fixed
        }
        
        private enum CodingKeys: String, CodingKey {
            case maxAttempts
            case backoff
            case baseDelayMs
            case retryOn
        }

        /// Attempts in total, the first one included — so `1` means no retry.
        /// Note this is the inverse of `RetryConfig.maxRetries`, which counts
        /// the attempts _in addition_ to the first attempt.
        var maxAttempts = 1
        var backoff = Backoff.exponential
        var baseDelay: TimeInterval = 0.25
        var retryOn: Set<Int> = []

        func delay(after failedAttempts: Int) -> TimeInterval {
            let growth = backoff == .exponential ? pow(2, Double(failedAttempts - 1)) : 1
            let maxDelay: TimeInterval = 30
            let maxWait = min(baseDelay * growth, maxDelay)
            return (maxWait / 2) + (.random(in: 0 ... maxWait / 2))
        }

        func shouldRetry(status: Int) -> Bool {
            retryOn.contains(status)
        }
    }
}

extension HTTPRequestResolver.RetryPolicy: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        try container.decodeIfPresent(Int.self, forKey: .maxAttempts).map { maxAttempts = max($0, 1) }
        try container.decodeIfPresent(Backoff.self, forKey: .backoff).map { backoff = $0 }
        try container.decodeIfPresent(Int.self, forKey: .baseDelayMs).map { baseDelay = TimeInterval(max($0, 0)) / 1000 }
        try container.decodeIfPresent([Int].self, forKey: .retryOn).map { retryOn = Set($0) }
    }
}
