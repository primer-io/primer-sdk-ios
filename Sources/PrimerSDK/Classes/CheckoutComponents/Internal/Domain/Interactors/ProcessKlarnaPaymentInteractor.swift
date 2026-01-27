//
//  ProcessKlarnaPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

/// Interactor protocol for processing Klarna payments.
@available(iOS 15.0, *)
protocol ProcessKlarnaPaymentInteractor {
    /// Creates a Klarna payment session and returns available categories.
    /// - Returns: The session result with categories.
    /// - Throws: Error if session creation fails.
    func createSession() async throws -> KlarnaSessionResult

    /// Configures the Klarna SDK for a selected category and loads the payment view.
    /// - Parameters:
    ///   - clientToken: The Klarna client token.
    ///   - categoryId: The selected category identifier.
    /// - Returns: The Klarna SDK payment view, or nil for test flows.
    /// - Throws: Error if configuration fails.
    func configureForCategory(clientToken: String, categoryId: String) async throws -> UIView?

    /// Authorizes the Klarna payment.
    /// - Returns: The authorization result.
    /// - Throws: Error if authorization fails.
    func authorize() async throws -> KlarnaAuthorizationResult

    /// Finalizes the Klarna payment after authorization requires finalization.
    /// - Returns: The finalization result.
    /// - Throws: Error if finalization fails.
    func finalize() async throws -> KlarnaAuthorizationResult

    /// Tokenizes and processes the Klarna payment.
    /// - Parameter authToken: The authorization token.
    /// - Returns: The payment result.
    /// - Throws: Error if tokenization or payment fails.
    func tokenize(authToken: String) async throws -> PaymentResult
}

/// Implementation of ProcessKlarnaPaymentInteractor that delegates to KlarnaRepository.
@available(iOS 15.0, *)
final class ProcessKlarnaPaymentInteractorImpl: ProcessKlarnaPaymentInteractor, LogReporter {

    private let repository: KlarnaRepository

    init(repository: KlarnaRepository) {
        self.repository = repository
    }

    func createSession() async throws -> KlarnaSessionResult {
        logger.debug(message: "Starting Klarna session creation")

        do {
            let result = try await repository.createSession()
            logger.debug(message: "Klarna session created with \(result.categories.count) categories")
            return result
        } catch {
            logger.error(message: "Klarna session creation failed: \(error)", error: error)
            throw error
        }
    }

    func configureForCategory(clientToken: String, categoryId: String) async throws -> UIView? {
        logger.debug(message: "Configuring Klarna for category: \(categoryId)")

        do {
            let view = try await repository.configureForCategory(clientToken: clientToken, categoryId: categoryId)
            logger.debug(message: "Klarna payment view loaded for category: \(categoryId)")
            return view
        } catch {
            logger.error(message: "Klarna category configuration failed: \(error)", error: error)
            throw error
        }
    }

    func authorize() async throws -> KlarnaAuthorizationResult {
        logger.debug(message: "Authorizing Klarna payment")

        do {
            let result = try await repository.authorize()
            logger.debug(message: "Klarna authorization result: \(result)")
            return result
        } catch {
            logger.error(message: "Klarna authorization failed: \(error)", error: error)
            throw error
        }
    }

    func finalize() async throws -> KlarnaAuthorizationResult {
        logger.debug(message: "Finalizing Klarna payment")

        do {
            let result = try await repository.finalize()
            logger.debug(message: "Klarna finalization result: \(result)")
            return result
        } catch {
            logger.error(message: "Klarna finalization failed: \(error)", error: error)
            throw error
        }
    }

    func tokenize(authToken: String) async throws -> PaymentResult {
        logger.debug(message: "Tokenizing Klarna payment")

        do {
            let result = try await repository.tokenize(authToken: authToken)
            logger.debug(message: "Klarna payment completed successfully")
            return result
        } catch {
            logger.error(message: "Klarna tokenization failed: \(error)", error: error)
            throw error
        }
    }
}
