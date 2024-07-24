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
    let maxJitter: TimeInterval

    init(enabled: Bool = false, maxRetries: Int = 8, initialBackoff: TimeInterval = 0.1, maxJitter: TimeInterval = 0.1) {
        self.enabled = enabled
        self.maxRetries = maxRetries
        self.initialBackoff = initialBackoff
        self.maxJitter = maxJitter
    }
}
