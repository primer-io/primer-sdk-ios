//
//  AnalyticsEnvironmentProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct AnalyticsEnvironmentProvider {

  private static let path = "/v1/sdk-analytic-events"

  func getEndpointURL(for environment: AnalyticsEnvironment) -> URL? {
    URL(string: "\(environment.baseURL)\(Self.path)")
  }
}
