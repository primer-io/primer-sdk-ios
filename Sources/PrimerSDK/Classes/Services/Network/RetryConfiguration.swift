//
//  RetryConfiguration.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct RetryConfig {
    let enabled: Bool
    let maxRetries: Int
    let initialBackoff: TimeInterval
    let retryNetworkErrors: Bool
    let retry500Errors: Bool
    let maxJitter: TimeInterval

    init(enabled: Bool = false,
         maxRetries: Int = 8,
         initialBackoff: TimeInterval = 0.1,
         retryNetworkErrors: Bool = true,
         retry500Errors: Bool = false,
         maxJitter: TimeInterval = 0.1) {
        self.enabled = enabled
        self.maxRetries = maxRetries
        self.initialBackoff = initialBackoff
        self.retryNetworkErrors = retryNetworkErrors
        self.retry500Errors = retry500Errors
        self.maxJitter = maxJitter
    }
}
