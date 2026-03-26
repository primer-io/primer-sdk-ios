//
//  ProcessWebRedirectPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import UIKit

@available(iOS 15.0, *)
protocol ProcessWebRedirectPaymentInteractor {
  func execute(paymentMethodType: String) async throws -> PaymentResult
}

@available(iOS 15.0, *)
final class ProcessWebRedirectPaymentInteractorImpl: ProcessWebRedirectPaymentInteractor, LogReporter {

  // See: https://developer.vippsmobilepay.com/docs/knowledge-base/user-flow/#deep-link-flow
  // If changing these values, they must also be updated in `Info.plist` `LSApplicationQueriesSchemes` of the host app.
  #if DEBUG
  private static let adyenVippsDeeplinkUrl = "vippsmt://"
  #else
  private static let adyenVippsDeeplinkUrl = "vipps://"
  #endif

  private let repository: WebRedirectRepository
  private let clientSessionActionsFactory: () -> ClientSessionActionsProtocol
  private let deeplinkAbilityProvider: DeeplinkAbilityProviding

  init(
    repository: WebRedirectRepository,
    clientSessionActionsFactory: @escaping () -> ClientSessionActionsProtocol = { ClientSessionActionsModule() },
    deeplinkAbilityProvider: DeeplinkAbilityProviding = UIApplication.shared
  ) {
    self.repository = repository
    self.clientSessionActionsFactory = clientSessionActionsFactory
    self.deeplinkAbilityProvider = deeplinkAbilityProvider
  }

  func execute(paymentMethodType: String) async throws -> PaymentResult {
    do {
      logger.debug(message: "[WebRedirect] Starting payment for: \(paymentMethodType)")

      let clientSessionActions = clientSessionActionsFactory()
      try await clientSessionActions.selectPaymentMethodIfNeeded(paymentMethodType, cardNetwork: nil)

      try await handlePrimerWillCreatePaymentEvent(paymentMethodType: paymentMethodType)

      let sessionInfo = createSessionInfo(for: paymentMethodType)

      let (redirectUrl, statusUrl) = try await repository.tokenize(
        paymentMethodType: paymentMethodType,
        sessionInfo: sessionInfo
      )

      _ = try await repository.openWebAuthentication(
        paymentMethodType: paymentMethodType,
        url: redirectUrl
      )

      let resumeToken = try await repository.pollForCompletion(statusUrl: statusUrl)

      let result = try await repository.resumePayment(
        paymentMethodType: paymentMethodType,
        resumeToken: resumeToken
      )

      logger.debug(message: "[WebRedirect] Payment completed: \(result.status)")
      return result
    } catch {
      throw handled(error: error)
    }
  }

  private func createSessionInfo(for paymentMethodType: String) -> WebRedirectSessionInfo {
    let localeCode = PrimerSettings.current.localeData.localeCode

    if paymentMethodType == PrimerPaymentMethodType.adyenVipps.rawValue {
      let vippsAppInstalled = isVippsAppInstalled()
      if !vippsAppInstalled {
        return WebRedirectSessionInfo(locale: localeCode, platform: "WEB")
      }
    }

    return WebRedirectSessionInfo(locale: localeCode)
  }

  private func isVippsAppInstalled() -> Bool {
    guard let url = URL(string: Self.adyenVippsDeeplinkUrl) else {
      return false
    }
    return deeplinkAbilityProvider.canOpenURL(url)
  }

  private func handlePrimerWillCreatePaymentEvent(paymentMethodType: String) async throws {
    guard PrimerInternal.shared.intent != .vault else { return }

    let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodType)
    let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)

    let decision = await PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData)

    switch decision.type {
    case let .abort(errorMessage):
      throw PrimerError.merchantError(message: errorMessage ?? "")
    case .continue:
      return
    }
  }
}
