//
//  AnalyticsEnvironmentProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct AnalyticsEnvironmentProvider {

  private let endpoints: [AnalyticsEnvironment: String] = [
    .dev: "https://analytics.dev.data.primer.io/v1/sdk-analytic-events",
    .staging: "https://analytics.staging.data.primer.io/v1/sdk-analytic-events",
    .sandbox: "https://analytics.sandbox.data.primer.io/v1/sdk-analytic-events",
    .production: "https://analytics.production.data.primer.io/v1/sdk-analytic-events"
  ]

  func getEndpointURL(for environment: AnalyticsEnvironment) -> URL? {
    endpoints[environment].flatMap(URL.init(string:))
  }
}
