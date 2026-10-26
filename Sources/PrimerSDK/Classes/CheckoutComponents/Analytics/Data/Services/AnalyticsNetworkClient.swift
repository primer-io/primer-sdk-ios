//
//  AnalyticsNetworkClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

protocol AnalyticsEventSending: Actor {
  func send(payload: AnalyticsPayload, fields: [String: CodableValue], to endpoint: URL, token: String?) async throws
}

actor AnalyticsNetworkClient: AnalyticsEventSending, LogReporter {

  private static let requestTimeout: TimeInterval = 10

  func send(payload: AnalyticsPayload, fields: [String: CodableValue], to endpoint: URL, token: String?) async throws {
    let request = try buildRequest(payload: payload, fields: fields, endpoint: endpoint, token: token)

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

  private func buildRequest(
    payload: AnalyticsPayload,
    fields: [String: CodableValue],
    endpoint: URL,
    token: String?
  ) throws -> URLRequest {
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.timeoutInterval = Self.requestTimeout
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let token {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    do {
      request.httpBody = try Self.body(for: payload, fields: fields)
    } catch {
      logger.error(message: "[Analytics] Failed to encode \(payload.eventName): \(error)")
      throw error
    }

    return request
  }

  static func body(for payload: AnalyticsPayload, fields: [String: CodableValue]) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.withoutEscapingSlashes]
    let body = try encoder.encode(payload)
    guard !fields.isEmpty else { return body }
    let built = try JSONDecoder().decode([String: CodableValue].self, from: body)
    return try encoder.encode(built.merging(fields) { _, field in field })
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
      throw AnalyticsError.httpStatus(httpResponse.statusCode)
    }
  }
}
