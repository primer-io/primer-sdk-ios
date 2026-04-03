//
//  ProcessKlarnaPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
protocol ProcessKlarnaPaymentInteractor {
  func createSession() async throws -> KlarnaSessionResult
  func configureForCategory(clientToken: String, categoryId: String) async throws -> UIView?
  func authorize() async throws -> KlarnaAuthorizationResult
  func finalize() async throws -> KlarnaAuthorizationResult
  func tokenize(authToken: String) async throws -> PaymentResult
}

@available(iOS 15.0, *)
final class ProcessKlarnaPaymentInteractorImpl: ProcessKlarnaPaymentInteractor, LogReporter {

  private let repository: KlarnaRepository

  init(repository: KlarnaRepository) {
    self.repository = repository
  }

  func createSession() async throws -> KlarnaSessionResult {
    do {
      return try await repository.createSession()
    } catch {
      logger.error(message: "Klarna session creation failed: \(error)", error: error)
      throw error
    }
  }

  func configureForCategory(clientToken: String, categoryId: String) async throws -> UIView? {
    do {
      return try await repository.configureForCategory(
        clientToken: clientToken, categoryId: categoryId
      )
    } catch {
      logger.error(message: "Klarna category configuration failed: \(error)", error: error)
      throw error
    }
  }

  func authorize() async throws -> KlarnaAuthorizationResult {
    do {
      return try await repository.authorize()
    } catch {
      logger.error(message: "Klarna authorization failed: \(error)", error: error)
      throw error
    }
  }

  func finalize() async throws -> KlarnaAuthorizationResult {
    do {
      return try await repository.finalize()
    } catch {
      logger.error(message: "Klarna finalization failed: \(error)", error: error)
      throw error
    }
  }

  func tokenize(authToken: String) async throws -> PaymentResult {
    do {
      return try await repository.tokenize(authToken: authToken)
    } catch {
      logger.error(message: "Klarna tokenization failed: \(error)", error: error)
      throw error
    }
  }
}
