//
//  RetryConfiguration.swift
//  PrimerSDK
//
//  Created by Boris on 23.7.24..
//

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
