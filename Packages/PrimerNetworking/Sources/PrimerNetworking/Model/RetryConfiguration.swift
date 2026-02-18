//
//  RetryConfiguration.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct RetryConfig {
    public let enabled: Bool
    public let maxRetries: Int
    public let initialBackoff: TimeInterval
    public let retryNetworkErrors: Bool
    public let retry500Errors: Bool
    public let maxJitter: TimeInterval

    public init(
        enabled: Bool = false,
        maxRetries: Int = 8,
        initialBackoff: TimeInterval = 0.1,
        retryNetworkErrors: Bool = true,
        retry500Errors: Bool = false,
        maxJitter: TimeInterval = 0.1
    ) {
        self.enabled = enabled
        self.maxRetries = maxRetries
        self.initialBackoff = initialBackoff
        self.retryNetworkErrors = retryNetworkErrors
        self.retry500Errors = retry500Errors
        self.maxJitter = maxJitter
    }
}
