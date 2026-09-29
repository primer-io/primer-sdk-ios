//
//  DefaultQRCodeScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class DefaultQRCodeScope: PrimerQRCodeScope, ObservableObject, LogReporter {

  private(set) var presentationContext: PresentationContext
  var screen: QRCodeScreenComponent?

  var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  var state: AsyncStream<PrimerQRCodeState> {
    AsyncStream { continuation in
      let task = Task { @MainActor in
        for await _ in $internalState.values {
          continuation.yield(internalState)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  // MARK: - Private Properties

  private weak var checkoutScope: DefaultCheckoutScope?
  private let interactor: ProcessQRCodePaymentInteractor
  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
  private let paymentMethodType: String

  @Published private var internalState = PrimerQRCodeState()

  private var hasStarted = false

  // MARK: - Initialization

  init(
    checkoutScope: DefaultCheckoutScope,
    presentationContext: PresentationContext = .fromPaymentSelection,
    interactor: ProcessQRCodePaymentInteractor,
    analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil,
    paymentMethodType: String
  ) {
    self.checkoutScope = checkoutScope
    self.presentationContext = presentationContext
    self.interactor = interactor
    self.analyticsInteractor = analyticsInteractor
    self.paymentMethodType = paymentMethodType
  }

  // MARK: - PrimerPaymentMethodScope Methods

  func start() {
    guard !hasStarted else { return }
    hasStarted = true
    logger.debug(message: "QR code scope started")
    Task { [self] in
      await performPayment()
    }
  }

  func prepareForReentry() {
    hasStarted = false
  }

  // No-op: QR code payments auto-submit via start()
  func submit() {}

  func cancel() {
    logger.debug(message: "QR code payment cancelled")
    interactor.cancelPolling()
    checkoutScope?.cancelActivePaymentMethod(returnToSelection: presentationContext.shouldShowBackButton)
  }

  // MARK: - Navigation Methods

  func onBack() {
    if presentationContext.shouldShowBackButton {
      interactor.cancelPolling()
      checkoutScope?.checkoutNavigator.navigateBack()
    }
  }

  // MARK: - Private Methods

  private func performPayment() async {
    internalState.status = .loading

    let metadata: AnalyticsEventMetadata = .payment(PaymentEvent(paymentMethod: paymentMethodType))
    await analyticsInteractor?.trackEvent(.paymentSubmitted, metadata: metadata)
    await analyticsInteractor?.trackEvent(.paymentProcessingStarted, metadata: metadata)

    do {
      try await checkoutScope?.invokeBeforePaymentCreate(
        paymentMethodType: paymentMethodType
      )

      let paymentData = try await interactor.startPayment()
      internalState.qrCodeImageData = paymentData.qrCodeImageData
      internalState.status = .displaying

      let result = try await interactor.pollAndComplete(
        statusUrl: paymentData.statusUrl,
        paymentId: paymentData.paymentId
      )

      internalState.status = .success
      checkoutScope?.handlePaymentSuccess(result)
    } catch {
      let primerError =
        error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
      if case .cancelled = primerError {
        logger.debug(message: "QR code payment cancelled by user")
        checkoutScope?.cancelActivePaymentMethod(returnToSelection: presentationContext.shouldShowBackButton)
        return
      }
      logger.error(message: "QR code payment failed: \(error.localizedDescription)")
      internalState.status = .failure(error.localizedDescription)
      checkoutScope?.handlePaymentError(primerError)
    }
  }
}
