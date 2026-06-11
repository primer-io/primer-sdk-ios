//
//  ProcessApplePayPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PassKit

@available(iOS 15.0, *)
protocol ProcessApplePayPaymentInteractor {
  func execute(payment: PKPayment) async throws -> PaymentResult
}

@available(iOS 15.0, *)
final class ProcessApplePayPaymentInteractorImpl: ProcessApplePayPaymentInteractor, LogReporter {

  private let tokenizationService: TokenizationServiceProtocol
  private let createPaymentService: CreateResumePaymentServiceProtocol

  init(
    tokenizationService: TokenizationServiceProtocol,
    createPaymentService: CreateResumePaymentServiceProtocol
  ) {
    self.tokenizationService = tokenizationService
    self.createPaymentService = createPaymentService
  }

  func execute(payment: PKPayment) async throws -> PaymentResult {
    do {
      let (configId, merchantIdentifier) = try getApplePayConfiguration()

      let paymentInstrument = try buildPaymentInstrument(
        from: payment,
        configId: configId,
        merchantIdentifier: merchantIdentifier
      )

      let tokenData = try await tokenizationService.tokenize(
        requestBody: Request.Body.Tokenization(paymentInstrument: paymentInstrument)
      )

      guard let token = tokenData.token else {
        throw PrimerError.invalidValue(key: "paymentMethodTokenData.token")
      }

      let paymentRequest = Request.Body.Payment.Create(token: token)
      let paymentResponse = try await createPaymentService.createPayment(
        paymentRequest: paymentRequest)

      // createPayment only throws for hard failures (nil id / FAILED status). A PENDING payment
      // or one carrying a requiredAction (3DS / resume) is returned without throwing, so we must
      // gate it here: this native Apple Pay path has no resume/poll infrastructure wired in (unlike
      // the web/form-redirect repositories), so surfacing such a response as a success-shaped
      // PaymentResult would let a merchant fulfil an order whose payment is not yet complete.
      if let requiredAction = paymentResponse.requiredAction {
        throw PrimerError.failedToCreatePayment(
          paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
          description: "Apple Pay payment requires unsupported action: \(requiredAction.name.rawValue)"
        )
      }

      // A non-success terminal/pending status must not be consumed as success by the scope. The
      // backend may opt into success-on-pending via showSuccessCheckoutOnPendingPayment; honour it,
      // otherwise treat anything other than SUCCESS as a payment failure.
      let allowsSuccessOnPending = paymentResponse.showSuccessCheckoutOnPendingPayment == true
      guard paymentResponse.status == .success || allowsSuccessOnPending else {
        throw PrimerError.paymentFailed(
          paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
          paymentId: paymentResponse.id ?? "",
          orderId: paymentResponse.orderId,
          status: paymentResponse.status.rawValue
        )
      }

      guard let paymentId = paymentResponse.id else {
        throw PrimerError.invalidValue(key: "paymentResponse.id")
      }

      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus(from: paymentResponse.status),
        amount: paymentResponse.amount,
        currencyCode: paymentResponse.currencyCode,
        paymentMethodType: PrimerPaymentMethodType.applePay.rawValue
      )

    } catch {
      logger.error(
        message: "Apple Pay payment processing failed: \(error)",
        error: error
      )
      throw error
    }
  }

  private func getApplePayConfiguration() throws -> (configId: String, merchantIdentifier: String) {
    guard
      let applePayConfig = PrimerAPIConfiguration.current?.paymentMethods?
        .first(where: { $0.internalPaymentMethodType == .applePay })
    else {
      throw PrimerError.unsupportedPaymentMethod(
        paymentMethodType: PrimerPaymentMethodType.applePay.rawValue)
    }

    guard let configId = applePayConfig.id else {
      throw PrimerError.invalidValue(key: "applePayConfig.id")
    }

    guard
      let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions?
        .merchantIdentifier
    else {
      throw PrimerError.invalidMerchantIdentifier()
    }

    return (configId, merchantIdentifier)
  }

  private func buildPaymentInstrument(
    from payment: PKPayment,
    configId: String,
    merchantIdentifier: String
  ) throws -> ApplePayPaymentInstrument {
    var isMockedBE = false
    #if DEBUG
      if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
        isMockedBE = true
      }
      if payment.token.paymentData.isEmpty {
        isMockedBE = true
      }
    #endif

    let tokenPaymentData: ApplePayPaymentResponseTokenPaymentData = if isMockedBE {
      ApplePayPaymentResponseTokenPaymentData(
        data: "apple-pay-payment-response-mock-data",
        signature: "apple-pay-mock-signature",
        version: "apple-pay-mock-version",
        header: ApplePayTokenPaymentDataHeader(
          ephemeralPublicKey: "apple-pay-mock-ephemeral-key",
          publicKeyHash: "apple-pay-mock-public-key-hash",
          transactionId: "apple-pay-mock-transaction-id"
        )
      )
    } else {
      try JSONDecoder().decode(
        ApplePayPaymentResponseTokenPaymentData.self,
        from: payment.token.paymentData
      )
    }

    return ApplePayPaymentInstrument(
      paymentMethodConfigId: configId,
      sourceConfig: ApplePayPaymentInstrument.SourceConfig(
        source: "IN_APP",
        merchantId: merchantIdentifier
      ),
      token: ApplePayPaymentInstrument.PaymentResponseToken(
        paymentMethod: ApplePayPaymentResponsePaymentMethod(
          displayName: payment.token.paymentMethod.displayName,
          network: payment.token.paymentMethod.network?.rawValue,
          type: payment.token.paymentMethod.type.primerValue
        ),
        transactionIdentifier: payment.token.transactionIdentifier,
        paymentData: tokenPaymentData
      )
    )
  }
}
