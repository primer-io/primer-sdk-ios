//
//  AchRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

#if canImport(PrimerStripeSDK)
import PrimerStripeSDK
#endif

@available(iOS 15.0, *)
@MainActor
final class AchRepositoryImpl: AchRepository, LogReporter {

  private let achClientSessionService: ACHClientSessionService
  private var achTokenizationService: ACHTokenizationService?
  private let settings: PrimerSettingsProtocol

  private weak var bankCollectorDelegate: AchBankCollectorDelegate?

  nonisolated init(
    achClientSessionService: ACHClientSessionService = ACHClientSessionService(),
    settings: PrimerSettingsProtocol = DependencyContainer.resolve()
  ) {
    self.achClientSessionService = achClientSessionService
    self.settings = settings
  }

  func loadUserDetails() async throws -> AchUserDetailsResult {
    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
      decodedJWTToken.isValid
    else {
      throw ACHHelpers.getInvalidTokenError()
    }

    let userDetails = achClientSessionService.getClientSessionUserDetails()

    return AchUserDetailsResult(
      firstName: userDetails.firstName,
      lastName: userDetails.lastName,
      emailAddress: userDetails.emailAddress
    )
  }

  func patchUserDetails(firstName: String, lastName: String, emailAddress: String) async throws {
    let params: [String: Any] = [
      "paymentMethodType": PrimerPaymentMethodType.stripeAch.rawValue
    ]

    let actions = [
      ClientSession.Action.selectPaymentMethodActionWithParameters(params),
      ClientSession.Action.setCustomerFirstName(firstName),
      ClientSession.Action.setCustomerLastName(lastName),
      ClientSession.Action.setCustomerEmailAddress(emailAddress)
    ]

    let updateRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
    try await achClientSessionService.patchClientSession(with: updateRequest)
  }

  func validate() async throws {
    let tokenizationService = try getOrCreateTokenizationService()
    try tokenizationService.validate()
  }

  func createBankCollector(
    firstName: String,
    lastName: String,
    emailAddress: String,
    delegate: AchBankCollectorDelegate
  ) async throws -> UIViewController {
    #if canImport(PrimerStripeSDK)
    guard let publishableKey = PrimerSettings.current.paymentMethodOptions.stripeOptions?.publishableKey,
      !publishableKey.isEmpty
    else {
      throw ACHHelpers.getInvalidValueError(key: "stripeOptions.publishableKey")
    }

    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
      let clientSecret = decodedJWTToken.stripeClientSecret
    else {
      throw ACHHelpers.getInvalidTokenError()
    }

    let urlScheme = try PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme().absoluteString

    self.bankCollectorDelegate = delegate

    let fullName = "\(firstName) \(lastName)"
    let stripeParams = PrimerStripeParams(
      publishableKey: publishableKey,
      clientSecret: clientSecret,
      returnUrl: urlScheme,
      fullName: fullName,
      emailAddress: emailAddress
    )

    let collectorViewController = await PrimerStripeCollectorViewController.getCollectorViewController(
      params: stripeParams,
      delegate: self
    )

    return collectorViewController
    #else
    throw ACHHelpers.getMissingSDKError(sdk: "PrimerStripeSDK")
    #endif
  }

  func getMandateData() async throws -> AchMandateResult {
    guard let mandateData = PrimerSettings.current.paymentMethodOptions.stripeOptions?.mandateData else {
      throw PrimerError.merchantError(
        message: "Required value for PrimerSettings.current.paymentMethodOptions.stripeOptions?.mandateData was nil or empty."
      )
    }

    switch mandateData {
    case let .fullMandate(text):
      return AchMandateResult(fullMandateText: text, templateMandateText: nil)
    case let .templateMandate(merchantName):
      return AchMandateResult(fullMandateText: nil, templateMandateText: merchantName)
    }
  }

  func tokenize() async throws -> PrimerPaymentMethodTokenData {
    let tokenizationService = try getOrCreateTokenizationService()
    return try await tokenizationService.tokenize()
  }

  func createPayment(tokenData: PrimerPaymentMethodTokenData) async throws -> PaymentResult {
    guard let token = tokenData.token else {
      throw ACHHelpers.getInvalidTokenError()
    }

    let createResumePaymentService = CreateResumePaymentService(
      paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue
    )

    let paymentRequest = Request.Body.Payment.Create(token: token)
    let paymentResponse = try await createResumePaymentService.createPayment(paymentRequest: paymentRequest)

    return PaymentResult(
      paymentId: paymentResponse.id ?? UUID().uuidString,
      status: .success,
      token: tokenData.token,
      amount: paymentResponse.amount,
      paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue
    )
  }

  // MARK: - Private Helpers

  private func getOrCreateTokenizationService() throws -> ACHTokenizationService {
    if let existingService = achTokenizationService {
      return existingService
    }

    guard let paymentMethod = findAchPaymentMethod() else {
      throw ACHHelpers.getInvalidValueError(key: "paymentMethod", value: nil)
    }

    let service = ACHTokenizationService(paymentMethod: paymentMethod)
    achTokenizationService = service
    return service
  }

  private func findAchPaymentMethod() -> PrimerPaymentMethod? {
    PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?
      .first(where: { $0.type == PrimerPaymentMethodType.stripeAch.rawValue })
  }
}

// MARK: - PrimerStripeCollectorViewControllerDelegate

#if canImport(PrimerStripeSDK)
@available(iOS 15.0, *)
extension AchRepositoryImpl: PrimerStripeCollectorViewControllerDelegate {

  nonisolated func primerStripeCollected(_ stripeStatus: PrimerStripeStatus) {
    Task { @MainActor in
      switch stripeStatus {
      case let .succeeded(paymentId):
        bankCollectorDelegate?.achBankCollectorDidSucceed(paymentId: paymentId)
      case .canceled:
        bankCollectorDelegate?.achBankCollectorDidCancel()
      case let .failed(error):
        let primerError = PrimerError.stripeError(
          key: error.errorId,
          message: error.errorDescription,
          diagnosticsId: error.diagnosticsId
        )
        bankCollectorDelegate?.achBankCollectorDidFail(error: primerError)
      @unknown default:
        let primerError = PrimerError.unknown(message: "Unknown Stripe status received")
        bankCollectorDelegate?.achBankCollectorDidFail(error: primerError)
      }
    }
  }
}
#endif
