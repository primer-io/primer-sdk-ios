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

@available(iOS 15.0, *)
@MainActor
protocol AchRepository {

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
protocol AchBankCollectorDelegate: AnyObject {
  func achBankCollectorDidSucceed(paymentId: String)
  func achBankCollectorDidCancel()
  func achBankCollectorDidFail(error: PrimerError)
}
