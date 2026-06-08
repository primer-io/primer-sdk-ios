//
//  AnalyticsEnvironment.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Analytics environment enumeration matching Primer backend environments
public enum AnalyticsEnvironment: String, Codable, Sendable {
  case dev = "DEV"
  case staging = "STAGING"
  case sandbox = "SANDBOX"
  case production = "PRODUCTION"

  /// Base host shared by analytics and logs endpoints for this environment.
  var baseURL: String {
    switch self {
    case .dev: "https://analytics.dev.data.primer.io"
    case .staging: "https://analytics.staging.data.primer.io"
    case .sandbox: "https://analytics.sandbox.data.primer.io"
    case .production: "https://analytics.production.data.primer.io"
    }
  }
}
