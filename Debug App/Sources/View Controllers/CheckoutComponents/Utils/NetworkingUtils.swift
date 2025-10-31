//
//  NetworkingUtils.swift
//  Debug App
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

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
        return try await withCheckedThrowingContinuation { continuation in
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

    /// Request a client session with Result type for more flexible error handling
    /// - Parameters:
    ///   - body: The client session request configuration
    ///   - apiVersion: The API version to use for the request
    /// - Returns: Result containing either the client token or an error
    static func requestClientSessionResult(
        body: ClientSessionRequestBody,
        apiVersion: PrimerApiVersion
    ) async -> Result<String, Error> {
        do {
            let token = try await requestClientSession(body: body, apiVersion: apiVersion)
            return .success(token)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Convenience Methods

    /// Request a client session from an optional ClientSessionRequestBody
    /// Common pattern in demo files where clientSession might be nil
    /// - Parameters:
    ///   - body: Optional client session request configuration
    ///   - apiVersion: The API version to use for the request
    /// - Returns: The client token string if successful, nil if body was nil
    /// - Throws: Network errors or invalid response errors
    static func requestClientSessionIfAvailable(
        body: ClientSessionRequestBody?,
        apiVersion: PrimerApiVersion
    ) async throws -> String? {
        guard let body = body else {
            return nil
        }
        return try await requestClientSession(body: body, apiVersion: apiVersion)
    }

    /// Create a session with standard demo configuration
    /// Helper method for demos that modify the base session
    /// - Parameters:
    ///   - baseSession: The base session to clone and modify
    ///   - orderId: Optional order ID override
    ///   - apiVersion: The API version to use
    /// - Returns: The client token string
    /// - Throws: Network errors or invalid response errors
    static func createDemoSession(
        from baseSession: ClientSessionRequestBody,
        orderId: String? = nil,
        apiVersion: PrimerApiVersion
    ) async throws -> String {
        let sessionBody = ClientSessionRequestBody(
            customerId: baseSession.customerId,
            orderId: orderId ?? baseSession.orderId ?? "demo-\(UUID().uuidString)",
            currencyCode: baseSession.currencyCode,
            amount: baseSession.amount,
            metadata: baseSession.metadata,
            customer: baseSession.customer,
            order: baseSession.order,
            paymentMethod: baseSession.paymentMethod
        )

        return try await requestClientSession(body: sessionBody, apiVersion: apiVersion)
    }
}
