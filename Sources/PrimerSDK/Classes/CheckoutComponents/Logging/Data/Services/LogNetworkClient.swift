//
//  LogNetworkClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

actor LogNetworkClient {
  // MARK: - JSON Encoder

  private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
    return encoder
  }()

  // MARK: - Public Methods

  func send(payload: LogPayload, to endpoint: URL, token: String?) async throws {
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let token {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let jsonData = try encoder.encode(payload)
    request.httpBody = jsonData

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw LoggingError.networkError
    }
  }
}
