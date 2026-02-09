//
//  RetryHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import PrimerNetworking

// TODO: Revisit access control once methods have been brought in here
public final class RetryHandler {
    
    public var currentTask: URLSessionDataTask?
    
    public let request: URLRequest
    public let retryConfig: RetryConfig
    public let completion: DispatcherCompletion
    public let urlSession: URLSessionProtocol
    
    public var retries = 0
    
    public var backoffWithJitter: TimeInterval {
        let exponentialPart = retryConfig.initialBackoff * pow(2.0, Double(retries - 1))
        let jitterPart = Double.random(in: 0...retryConfig.maxJitter)
        return exponentialPart + jitterPart
    }
    
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
    
}
