//
//  DefaultQRCodeScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

@available(iOS 15.0, *)
@MainActor
public final class DefaultQRCodeScope: PrimerQRCodeScope, ObservableObject, LogReporter {

  // MARK: - Public Properties

  public private(set) var presentationContext: PresentationContext
  public var screen: QRCodeScreenComponent?

  public var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  public var state: AsyncStream<PrimerQRCodeState> {
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

  public func start() {
    logger.debug(message: "QR code scope started")
    Task { [self] in
      await performPayment()
    }
  }

  // No-op: QR code payments auto-submit via start()
  public func submit() {}

  public func cancel() {
    logger.debug(message: "QR code payment cancelled")
    interactor.cancelPolling()
    checkoutScope?.onDismiss()
  }

  // MARK: - Navigation Methods

  public func onBack() {
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
      logger.error(message: "QR code payment failed: \(error.localizedDescription)")
      internalState.status = .failure(error.localizedDescription)

      let primerError =
        error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
      checkoutScope?.handlePaymentError(primerError)
    }
  }
}
