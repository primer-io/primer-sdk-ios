//
//  BankSelectorRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Implementation of BankSelectorRepository that wraps PrimerAPIClient for bank
/// fetching and TokenizationService for payment processing.
@available(iOS 15.0, *)
final class BankSelectorRepositoryImpl: BankSelectorRepository, LogReporter {

  private let apiClient: PrimerAPIClientBanksProtocol
  private let tokenizationService: TokenizationServiceProtocol

  init(
    apiClient: PrimerAPIClientBanksProtocol = PrimerAPIClient(),
    tokenizationService: TokenizationServiceProtocol = TokenizationService()
  ) {
    self.apiClient = apiClient
    self.tokenizationService = tokenizationService
  }

  func fetchBanks(
    paymentMethodConfigId: String,
    paymentMethod: String
  ) async throws -> [AdyenBank] {
    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
      throw PrimerError.invalidClientToken()
    }

    let request = Request.Body.Adyen.BanksList(
      paymentMethodConfigId: paymentMethodConfigId,
      parameters: BankTokenizationSessionRequestParameters(paymentMethod: paymentMethod)
    )

    let response = try await apiClient.listAdyenBanks(
      clientToken: decodedJWTToken,
      request: request
    )

    logger.debug(message: "Fetched \(response.result.count) banks for \(paymentMethod)")
    return response.result
  }

  func tokenize(
    paymentMethodConfigId: String,
    paymentMethodType: String,
    bankId: String
  ) async throws -> PaymentResult {
    let instrument = OffSessionPaymentInstrument(
      paymentMethodConfigId: paymentMethodConfigId,
      paymentMethodType: paymentMethodType,
      sessionInfo: BankSelectorSessionInfo(issuer: bankId)
    )

    let requestBody = Request.Body.Tokenization(paymentInstrument: instrument)
    let tokenData = try await tokenizationService.tokenize(requestBody: requestBody)

    logger.debug(message: "Bank selector tokenization completed for \(paymentMethodType)")

    return PaymentResult(
      paymentId: tokenData.id ?? UUID().uuidString,
      status: .success,
      token: tokenData.token,
      paymentMethodType: paymentMethodType
    )
  }
}
