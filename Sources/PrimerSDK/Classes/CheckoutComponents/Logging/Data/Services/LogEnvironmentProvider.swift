//
//  LogEnvironmentProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum LogEnvironmentProvider {
  private enum Constants {
    static let devBaseURL = "https://analytics.dev.data.primer.io"
    static let stagingBaseURL = "https://analytics.staging.data.primer.io"
    static let sandboxBaseURL = "https://analytics.sandbox.data.primer.io"
    static let productionBaseURL = "https://analytics.production.data.primer.io"
    static let logsPath = "/v1/sdk-logs"
  }

  static func getEndpointURL(for environment: AnalyticsEnvironment) -> URL {
    let baseURL =
      switch environment {
      case .dev: Constants.devBaseURL
      case .staging: Constants.stagingBaseURL
      case .sandbox: Constants.sandboxBaseURL
      case .production: Constants.productionBaseURL
      }
    guard let url = URL(string: "\(baseURL)\(Constants.logsPath)") else {
      preconditionFailure("Invalid hardcoded URL for environment: \(environment)")
    }
    return url
  }
}
