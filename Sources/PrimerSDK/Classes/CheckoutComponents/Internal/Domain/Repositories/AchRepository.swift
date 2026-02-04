//
//  AchRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
struct AchUserDetailsResult {
  let firstName: String
  let lastName: String
  let emailAddress: String
}

@available(iOS 15.0, *)
struct AchMandateResult {
  let fullMandateText: String?
  let templateMandateText: String?
}

/// Result of tokenization and payment creation, containing Stripe-specific data needed for bank collection
@available(iOS 15.0, *)
struct AchStripeData {
  let stripeClientSecret: String
  let sdkCompleteUrl: URL
  let paymentId: String
  let decodedJWTToken: DecodedJWTToken
}

@available(iOS 15.0, *)
@MainActor
protocol AchRepository {

  func loadUserDetails() async throws -> AchUserDetailsResult

  func patchUserDetails(firstName: String, lastName: String, emailAddress: String) async throws

  func validate() async throws

  /// Tokenizes, creates payment, and extracts Stripe data from the requiredAction response
  func startPaymentAndGetStripeData() async throws -> AchStripeData

  /// Creates the bank collector with the provided Stripe client secret
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

  /// Completes the payment after mandate acceptance by calling the sdkCompleteUrl
  func completePayment(stripeData: AchStripeData) async throws -> PaymentResult
}

@available(iOS 15.0, *)
protocol AchBankCollectorDelegate: AnyObject {
  func achBankCollectorDidSucceed(paymentId: String)
  func achBankCollectorDidCancel()
  func achBankCollectorDidFail(error: PrimerError)
}
