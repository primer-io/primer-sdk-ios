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
  func startPaymentAndGetStripeData() async throws -> AchStripeData
  func createBankCollector(
    firstName: String,
    lastName: String,
    emailAddress: String,
    clientSecret: String,
    delegate: AchBankCollectorDelegate
  ) async throws -> UIViewController
  func getMandateData() async throws -> AchMandateResult
  func tokenize() async throws -> PrimerPaymentMethodTokenData
  func createPayment(tokenData: PrimerPaymentMethodTokenData) async throws -> PaymentResult
  func completePayment(stripeData: AchStripeData) async throws -> PaymentResult
}

@available(iOS 15.0, *)
final class ProcessAchPaymentInteractorImpl: ProcessAchPaymentInteractor, LogReporter {

  private let repository: AchRepository

  init(repository: AchRepository) {
    self.repository = repository
  }

  func loadUserDetails() async throws -> AchUserDetailsResult {
    do {
      return try await repository.loadUserDetails()
    } catch {
      logger.error(message: "ACH user details loading failed: \(error)", error: error)
      throw error
    }
  }

  func patchUserDetails(firstName: String, lastName: String, emailAddress: String) async throws {
    do {
      try await repository.patchUserDetails(
        firstName: firstName,
        lastName: lastName,
        emailAddress: emailAddress
      )
    } catch {
      logger.error(message: "ACH user details patch failed: \(error)", error: error)
      throw error
    }
  }

  func validate() async throws {
    do {
      try await repository.validate()
    } catch {
      logger.error(message: "ACH validation failed: \(error)", error: error)
      throw error
    }
  }

  func startPaymentAndGetStripeData() async throws -> AchStripeData {
    do {
      return try await repository.startPaymentAndGetStripeData()
    } catch {
      logger.error(message: "ACH Stripe data retrieval failed: \(error)", error: error)
      throw error
    }
  }

  func createBankCollector(
    firstName: String,
    lastName: String,
    emailAddress: String,
    clientSecret: String,
    delegate: AchBankCollectorDelegate
  ) async throws -> UIViewController {
    do {
      return try await repository.createBankCollector(
        firstName: firstName,
        lastName: lastName,
        emailAddress: emailAddress,
        clientSecret: clientSecret,
        delegate: delegate
      )
    } catch {
      logger.error(message: "ACH bank collector creation failed: \(error)", error: error)
      throw error
    }
  }

  func getMandateData() async throws -> AchMandateResult {
    do {
      return try await repository.getMandateData()
    } catch {
      logger.error(message: "ACH mandate data retrieval failed: \(error)", error: error)
      throw error
    }
  }

  func tokenize() async throws -> PrimerPaymentMethodTokenData {
    do {
      return try await repository.tokenize()
    } catch {
      logger.error(message: "ACH tokenization failed: \(error)", error: error)
      throw error
    }
  }

  func createPayment(tokenData: PrimerPaymentMethodTokenData) async throws -> PaymentResult {
    do {
      return try await repository.createPayment(tokenData: tokenData)
    } catch {
      logger.error(message: "ACH payment creation failed: \(error)", error: error)
      throw error
    }
  }

  func completePayment(stripeData: AchStripeData) async throws -> PaymentResult {
    do {
      return try await repository.completePayment(stripeData: stripeData)
    } catch {
      logger.error(message: "ACH payment completion failed: \(error)", error: error)
      throw error
    }
  }
}
