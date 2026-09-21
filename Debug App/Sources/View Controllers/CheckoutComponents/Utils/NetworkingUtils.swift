//
//  NetworkingUtils.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerSDK

/// Unified networking utilities for CheckoutComponents demos
/// Provides modern async/await interface with consistent error handling
@available(iOS 15.0, *)
enum NetworkingUtils {

    // MARK: - Error Types

    enum NetworkingError: LocalizedError {
        case invalidResponse
        case noToken

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                "Invalid response from server"
            case .noToken:
                "No client token received"
            }
        }
    }

    // MARK: - Client Session Request

    /// Request a client session with async/await interface
    /// - Parameters:
    ///   - body: The client session request configuration
    ///   - apiVersion: The API version to use for the request
    /// - Returns: The client token string
    /// - Throws: Network errors or invalid response errors
    static func requestClientSession(
        body: ClientSessionRequestBody,
        apiVersion: PrimerApiVersion
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Networking.requestClientSession(
                requestBody: body,
                apiVersion: apiVersion
            ) { clientToken, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let clientToken {
                    continuation.resume(returning: clientToken)
                } else {
                    continuation.resume(throwing: NetworkingError.noToken)
                }
            }
        }
    }

    // MARK: - Shipping Commit

    /// Commits an Express Checkout shipping option onto the live client session.
    ///
    /// A real merchant does this from its own backend with a secret API key; the demo backend accepts
    /// the client token so the flow can be exercised from the app. No top-level `amount` is sent —
    /// Primer recomputes the total from line items plus shipping, and a top-level amount would
    /// override that recompute and undercharge.
    static func patchClientSessionShipping(
        clientToken: String,
        methodId: String,
        methodName: String,
        methodDescription: String,
        amount: Int
    ) async throws {
        let body = ClientSessionRequestBody(
            order: ClientSessionRequestBody.Order(
                shipping: ClientSessionRequestBody.Order.Shipping(
                    methodId: methodId,
                    methodName: methodName,
                    methodDescription: methodDescription,
                    amount: amount
                )
            )
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Networking.patchClientSession(clientToken: clientToken, requestBody: body) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
