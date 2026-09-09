//
//  AnalyticsNetworkClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

actor AnalyticsNetworkClient: LogReporter {

  // Some analytics events are awaited on the payment hot path, so bound the request to keep a
  // stalled endpoint from delaying payment progression (URLSession's default is ~60s).
  private static let requestTimeout: TimeInterval = 10

  func send(payload: AnalyticsPayload, to endpoint: URL, token: String?) async throws {
    let request = try buildRequest(payload: payload, endpoint: endpoint, token: token)

    logger.info(
      message: "[Analytics] Dispatching \(payload.eventName) -> \(endpoint.absoluteString)")
    logger.debug(
      message:
        "[Analytics] Event context - id: \(payload.id), timestamp: \(payload.timestamp), sdkType: \(payload.sdkType)"
    )

    if request.value(forHTTPHeaderField: "Authorization") == nil {
      logger.warn(message: "[Analytics] No authorization token provided")
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    try validateResponse(response: response, data: data)

    logger.info(message: "[Analytics] \(payload.eventName) acknowledged")
  }

  private func buildRequest(payload: AnalyticsPayload, endpoint: URL, token: String?) throws -> URLRequest {
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.timeoutInterval = Self.requestTimeout
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let token {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.withoutEscapingSlashes]

    do {
      request.httpBody = try encoder.encode(payload)
    } catch {
      logger.error(message: "[Analytics] Failed to encode \(payload.eventName): \(error)")
      throw error
    }

    return request
  }

  private func validateResponse(response: URLResponse, data: Data) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      logger.error(message: "[Analytics] Invalid response type")
      throw AnalyticsError.requestFailed
    }

    logger.debug(message: "[Analytics] Response status code: \(httpResponse.statusCode)")

    guard (200...299).contains(httpResponse.statusCode) else {
      if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
        logger.error(
          message:
            "[Analytics] Request failed with status \(httpResponse.statusCode) - \(responseString)"
        )
      } else {
        logger.error(message: "[Analytics] Request failed with status \(httpResponse.statusCode)")
      }
      throw AnalyticsError.requestFailed
    }
  }
}
