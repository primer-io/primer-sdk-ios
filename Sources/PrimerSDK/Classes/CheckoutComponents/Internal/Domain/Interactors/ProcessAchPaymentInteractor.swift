//
//  ProcessAchPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
protocol ProcessAchPaymentInteractor {
  func loadUserDetails() async throws -> AchUserDetailsResult
  func patchUserDetails(firstName: String, lastName: String, emailAddress: String) async throws
  func validate() async throws
  func createBankCollector(
    firstName: String,
    lastName: String,
    emailAddress: String,
    delegate: AchBankCollectorDelegate
  ) async throws -> UIViewController
  func getMandateData() async throws -> AchMandateResult
  func tokenize() async throws -> PrimerPaymentMethodTokenData
  func createPayment(tokenData: PrimerPaymentMethodTokenData) async throws -> PaymentResult
}

@available(iOS 15.0, *)
final class ProcessAchPaymentInteractorImpl: ProcessAchPaymentInteractor, LogReporter {

  private let repository: AchRepository

  init(repository: AchRepository) {
    self.repository = repository
  }

  func loadUserDetails() async throws -> AchUserDetailsResult {
    logger.debug(message: "Loading ACH user details")

    do {
      let result = try await repository.loadUserDetails()
      logger.debug(message: "ACH user details loaded successfully")
      return result
    } catch {
      logger.error(message: "ACH user details loading failed: \(error)", error: error)
      throw error
    }
  }

  func patchUserDetails(firstName: String, lastName: String, emailAddress: String) async throws {
    logger.debug(message: "Patching ACH user details")

    do {
      try await repository.patchUserDetails(
        firstName: firstName,
        lastName: lastName,
        emailAddress: emailAddress
      )
      logger.debug(message: "ACH user details patched successfully")
    } catch {
      logger.error(message: "ACH user details patch failed: \(error)", error: error)
      throw error
    }
  }

  func validate() async throws {
    logger.debug(message: "Validating ACH payment configuration")

    do {
      try await repository.validate()
      logger.debug(message: "ACH payment configuration validated successfully")
    } catch {
      logger.error(message: "ACH validation failed: \(error)", error: error)
      throw error
    }
  }

  func createBankCollector(
    firstName: String,
    lastName: String,
    emailAddress: String,
    delegate: AchBankCollectorDelegate
  ) async throws -> UIViewController {
    logger.debug(message: "Creating ACH bank collector")

    do {
      let viewController = try await repository.createBankCollector(
        firstName: firstName,
        lastName: lastName,
        emailAddress: emailAddress,
        delegate: delegate
      )
      logger.debug(message: "ACH bank collector created successfully")
      return viewController
    } catch {
      logger.error(message: "ACH bank collector creation failed: \(error)", error: error)
      throw error
    }
  }

  func getMandateData() async throws -> AchMandateResult {
    logger.debug(message: "Getting ACH mandate data")

    do {
      let result = try await repository.getMandateData()
      logger.debug(message: "ACH mandate data retrieved successfully")
      return result
    } catch {
      logger.error(message: "ACH mandate data retrieval failed: \(error)", error: error)
      throw error
    }
  }

  func tokenize() async throws -> PrimerPaymentMethodTokenData {
    logger.debug(message: "Starting ACH tokenization")

    do {
      let result = try await repository.tokenize()
      logger.debug(message: "ACH tokenization completed successfully")
      return result
    } catch {
      logger.error(message: "ACH tokenization failed: \(error)", error: error)
      throw error
    }
  }

  func createPayment(tokenData: PrimerPaymentMethodTokenData) async throws -> PaymentResult {
    logger.debug(message: "Creating ACH payment")

    do {
      let result = try await repository.createPayment(tokenData: tokenData)
      logger.debug(message: "ACH payment completed successfully")
      return result
    } catch {
      logger.error(message: "ACH payment creation failed: \(error)", error: error)
      throw error
    }
  }
}
