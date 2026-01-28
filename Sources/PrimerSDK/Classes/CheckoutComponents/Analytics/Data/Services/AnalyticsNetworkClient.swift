//
//  AnalyticsNetworkClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Responsible for sending analytics payloads via HTTP to the analytics service.
/// Handles request construction, authorization, and response validation.
actor AnalyticsNetworkClient: LogReporter {

    // MARK: - Public Methods

    /// Send an analytics payload to the specified endpoint
    /// - Parameters:
    ///   - payload: The analytics payload to send
    ///   - endpoint: The target analytics endpoint URL
    ///   - token: Optional client session token for authorization
    /// - Throws: `AnalyticsError.requestFailed` if the request fails
    func send(payload: AnalyticsPayload, to endpoint: URL, token: String?) async throws {
        let request = buildRequest(payload: payload, endpoint: endpoint, token: token)

        logger.info(message: "📊 [Analytics] Dispatching \(payload.eventName) -> \(endpoint.absoluteString)")
        logger.debug(message: "📊 [Analytics] Event context - id: \(payload.id), timestamp: \(payload.timestamp), sdkType: \(payload.sdkType)")

        if request.value(forHTTPHeaderField: "Authorization") == nil {
            logger.warn(message: "⚠️ [Analytics] No authorization token provided")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateResponse(response: response, data: data)

        logger.info(message: "✅ [Analytics] \(payload.eventName) acknowledged")
    }

    // MARK: - Private Methods

    private func buildRequest(payload: AnalyticsPayload, endpoint: URL, token: String?) -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add Authorization header if token is available
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode payload (no pretty printing to match Android behavior)
        let encoder = JSONEncoder()

        // IMPORTANT: Disable forward slash escaping - server may reject escaped slashes
        if #available(iOS 13.0, *) {
            encoder.outputFormatting = [.withoutEscapingSlashes]
        }

        do {
            let jsonData = try encoder.encode(payload)
            request.httpBody = jsonData
        } catch {
            logger.error(message: "❌ [Analytics] Failed to encode payload: \(error)")
        }

        return request
    }

    private func validateResponse(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error(message: "❌ [Analytics] Invalid response type")
            throw AnalyticsError.requestFailed
        }

        logger.debug(message: "📊 [Analytics] Response status code: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                logger.error(message: "❌ [Analytics] Request failed with status \(httpResponse.statusCode) - \(responseString)")
            } else {
                logger.error(message: "❌ [Analytics] Request failed with status \(httpResponse.statusCode)")
            }
            throw AnalyticsError.requestFailed
        }
    }
}
