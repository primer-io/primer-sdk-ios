//
//  AnalyticsSessionConfig.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Configuration for an analytics session, initialized once per checkout flow.
/// All fields are extracted from the client token JWT or generated at checkout start.
public struct AnalyticsSessionConfig {
    /// The analytics environment (extracted from client token)
    public let environment: AnalyticsEnvironment

    /// Session ID linking all events in a single checkout flow (generated once per checkout)
    public let checkoutSessionId: String

    /// Client session identifier (extracted from JWT payload)
    public let clientSessionId: String

    /// Primer account identifier for the merchant (extracted from JWT payload)
    public let primerAccountId: String

    /// SDK semantic version (e.g., "2.46.7")
    public let sdkVersion: String

    /// Full JWT client session token for Authorization header
    public let clientSessionToken: String?

    public init(
        environment: AnalyticsEnvironment,
        checkoutSessionId: String,
        clientSessionId: String,
        primerAccountId: String,
        sdkVersion: String,
        clientSessionToken: String? = nil
    ) {
        self.environment = environment
        self.checkoutSessionId = checkoutSessionId
        self.clientSessionId = clientSessionId
        self.primerAccountId = primerAccountId
        self.sdkVersion = sdkVersion
        self.clientSessionToken = clientSessionToken
    }
}
