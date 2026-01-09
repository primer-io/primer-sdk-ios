//
//  RetryHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public final class RetryHandler {
    public let request: URLRequest
    public let retryConfig: RetryConfig
    public let completion: DispatcherCompletion
    public let urlSession: URLSessionProtocol

    public var retries = 0
    public var currentTask: URLSessionDataTask?

    public init(
        request: URLRequest,
        retryConfig: RetryConfig,
        completion: @escaping DispatcherCompletion,
        urlSession: URLSessionProtocol
    ) {
        self.request = request
        self.retryConfig = retryConfig
        self.completion = completion
        self.urlSession = urlSession
    }

    public func calculateBackoffWithJitter(baseDelay: TimeInterval, retryCount: Int, maxJitter: TimeInterval) -> TimeInterval {
        let exponentialPart = baseDelay * pow(2.0, Double(retryCount - 1))
        let jitterPart = Double.random(in: 0...maxJitter)
        return exponentialPart + jitterPart
    }
}
