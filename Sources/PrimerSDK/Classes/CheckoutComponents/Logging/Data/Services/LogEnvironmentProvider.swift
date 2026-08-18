//
//  LogEnvironmentProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

enum LogEnvironmentProvider {
  private static let logsPath = "/v1/sdk-logs"

  static func getEndpointURL(for environment: AnalyticsEnvironment) -> URL {
    guard let url = URL(string: "\(environment.baseURL)\(logsPath)") else {
      preconditionFailure("Invalid hardcoded URL for environment: \(environment)")
    }
    return url
  }
}
