//
//  AnalyticsEnvironmentProvider.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Provides analytics endpoint URLs for each environment
struct AnalyticsEnvironmentProvider {
    /// Get the analytics endpoint URL for a given environment
    /// - Parameter environment: The analytics environment
    /// - Returns: Full URL for the analytics endpoint
    func getEndpointURL(for environment: AnalyticsEnvironment) -> URL? {
        guard let urlString = endpoints[environment] else {
            return nil
        }
        return URL(string: urlString)
    }

    // MARK: - Private

    private let endpoints: [AnalyticsEnvironment: String] = [
        .dev: "https://analytics.dev.data.primer.io/v1/sdk-analytic-events",
        .staging: "https://analytics.staging.data.primer.io/v1/sdk-analytic-events",
        .sandbox: "https://analytics.sandbox.data.primer.io/v1/sdk-analytic-events",
        .production: "https://analytics.production.data.primer.io/v1/sdk-analytic-events",
    ]
}
