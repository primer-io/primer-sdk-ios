//
//  NetworkingUtils.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
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
                return "Invalid response from server"
            case .noToken:
                return "No client token received"
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
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let clientToken = clientToken {
                    continuation.resume(returning: clientToken)
                } else {
                    continuation.resume(throwing: NetworkingError.noToken)
                }
            }
        }
    }

//    /// Request a client session with Result type for more flexible error handling
//    /// - Parameters:
//    ///   - body: The client session request configuration
//    ///   - apiVersion: The API version to use for the request
//    /// - Returns: Result containing either the client token or an error
//    static func requestClientSessionResult(
//        body: ClientSessionRequestBody,
//        apiVersion: PrimerApiVersion
//    ) async -> Result<String, Error> {
//        do {
//            let token = try await requestClientSession(body: body, apiVersion: apiVersion)
//            return .success(token)
//        } catch {
//            return .failure(error)
//        }
//    }
}
