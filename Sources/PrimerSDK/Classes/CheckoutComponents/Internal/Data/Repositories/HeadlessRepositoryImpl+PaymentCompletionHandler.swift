//
//  HeadlessRepositoryImpl+PaymentCompletionHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Payment completion handler that implements delegate callbacks for async payment processing
@available(iOS 15.0, *)
@MainActor
final class PaymentCompletionHandler: NSObject,
  @preconcurrency PrimerHeadlessUniversalCheckoutDelegate,
  @preconcurrency PrimerHeadlessUniversalCheckoutRawDataManagerDelegate,
  LogReporter {

  private let completion: (Result<PaymentResult, Error>) -> Void
  private var hasCompleted = false
  private weak var repository: HeadlessRepositoryImpl?
  private var validationCompletion: ((Bool, [Error]?) -> Void)?
  private let paymentMethodType: String

  init(
    repository: HeadlessRepositoryImpl,
    paymentMethodType: String = "PAYMENT_CARD",
    completion: @escaping (Result<PaymentResult, Error>) -> Void
  ) {
    self.repository = repository
    self.paymentMethodType = paymentMethodType
    self.completion = completion
    super.init()
  }

  func setValidationCompletion(_ validationCompletion: @escaping (Bool, [Error]?) -> Void) {
    self.validationCompletion = validationCompletion
  }

  // MARK: - PrimerHeadlessUniversalCheckoutDelegate (Payment Completion)

  func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
    guard !hasCompleted else {
      return
    }
    hasCompleted = true

    let result = PaymentResult(
      paymentId: data.payment?.id ?? UUID().uuidString,
      status: .success,
      token: data.payment?.id,
      amount: nil,
      paymentMethodType: paymentMethodType
    )
    completion(.success(result))
  }

  func primerHeadlessUniversalCheckoutDidFail(
    withError err: Error, checkoutData: PrimerCheckoutData?
  ) {
    guard !hasCompleted else {
      return
    }
    hasCompleted = true

    completion(.failure(err))
  }

  func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(
    _ data: PrimerCheckoutPaymentMethodData,
    decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void
  ) {
    decisionHandler(.continuePaymentCreation())
  }

  // MARK: - 3DS Support

  func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(
    _ paymentMethodTokenData: PrimerPaymentMethodTokenData,
    decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void
  ) {
    repository?.trackThreeDSChallengeIfNeeded(from: paymentMethodTokenData)

    // For CheckoutComponents, we simply complete the tokenization
    // 3DS handling will be done at the payment creation level, not here
    decisionHandler(.complete())
  }

  func primerHeadlessUniversalCheckoutDidResumeWith(
    _ resumeToken: String,
    decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void
  ) {
    decisionHandler(.complete())
  }

  func primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo(
    _ additionalInfo: PrimerCheckoutAdditionalInfo?
  ) {
    repository?.trackRedirectToThirdPartyIfNeeded(from: additionalInfo, paymentMethodType: paymentMethodType)
  }

  func primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(
    _ additionalInfo: PrimerCheckoutAdditionalInfo?
  ) {
    repository?.trackRedirectToThirdPartyIfNeeded(from: additionalInfo, paymentMethodType: paymentMethodType)
  }

  // MARK: - PrimerHeadlessUniversalCheckoutRawDataManagerDelegate (Validation)

  func primerRawDataManager(
    _ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
    dataIsValid isValid: Bool,
    errors: [Error]?
  ) {
    // Notify validation completion handler - continuation is resumed in submitPaymentWithValidation
    if let validationCompletion {
      self.validationCompletion = nil
      validationCompletion(isValid, errors)
    }
  }

  func primerRawDataManager(
    _ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
    didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
    forState state: PrimerValidationState
  ) {}
}
