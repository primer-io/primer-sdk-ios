//
//  DefaultKlarnaScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI
import UIKit

@available(iOS 15.0, *)
@MainActor
public final class DefaultKlarnaScope: PrimerKlarnaScope, ObservableObject, LogReporter {

  // MARK: - Public Properties

  public private(set) var presentationContext: PresentationContext

  public var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  public private(set) var paymentView: UIView?

  public var state: AsyncStream<PrimerKlarnaState> {
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

  // MARK: - UI Customization Properties

  public var screen: KlarnaScreenComponent?
  public var authorizeButton: KlarnaButtonComponent?
  public var finalizeButton: KlarnaButtonComponent?

  // MARK: - Private Properties

  private weak var checkoutScope: DefaultCheckoutScope?
  private let processKlarnaInteractor: ProcessKlarnaPaymentInteractor
  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

  @Published private var internalState = PrimerKlarnaState()

  private var klarnaClientToken: String?

  private var authorizationToken: String?

  // MARK: - Initialization

  init(
    checkoutScope: DefaultCheckoutScope,
    presentationContext: PresentationContext = .fromPaymentSelection,
    processKlarnaInteractor: ProcessKlarnaPaymentInteractor,
    analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
  ) {
    self.checkoutScope = checkoutScope
    self.presentationContext = presentationContext
    self.processKlarnaInteractor = processKlarnaInteractor
    self.analyticsInteractor = analyticsInteractor
  }

  // MARK: - PrimerPaymentMethodScope Methods

  public func start() {
    logger.debug(message: "Klarna scope started")
    Task { [self] in
      await createSession()
    }
  }

  public func submit() {
    authorizePayment()
  }

  public func cancel() {
    logger.debug(message: "Klarna payment cancelled")
    guard let checkoutScope else {
      logger.warn(message: "Klarna checkout scope was deallocated during cancel")
      return
    }
    checkoutScope.onDismiss()
  }

  // MARK: - Klarna Flow Actions

  public func selectPaymentCategory(_ categoryId: String) {
    guard internalState.categories.contains(where: { $0.id == categoryId }) else {
      logger.warn(message: "Invalid category ID: \(categoryId)")
      return
    }

    internalState = PrimerKlarnaState(
      step: .categorySelection,
      categories: internalState.categories,
      selectedCategoryId: categoryId
    )
    paymentView = nil

    Task { [self] in
      await loadPaymentView(for: categoryId)
    }
  }

  public func authorizePayment() {
    guard internalState.step == .viewReady || internalState.step == .categorySelection else {
      logger.warn(message: "Cannot authorize in current step: \(internalState.step)")
      return
    }

    internalState = PrimerKlarnaState(
      step: .authorizationStarted,
      categories: internalState.categories,
      selectedCategoryId: internalState.selectedCategoryId
    )

    Task { [self] in
      await performAuthorization()
    }
  }

  public func finalizePayment() {
    guard internalState.step == .awaitingFinalization else {
      logger.warn(message: "Cannot finalize in current step: \(internalState.step)")
      return
    }

    Task { [self] in
      await performFinalization()
    }
  }

  // MARK: - Navigation Methods

  public func onBack() {
    guard presentationContext.shouldShowBackButton else { return }
    guard let checkoutScope else {
      logger.warn(message: "Klarna checkout scope was deallocated during navigation back")
      return
    }
    checkoutScope.checkoutNavigator.navigateBack()
  }

  public func onCancel() {
    guard let checkoutScope else {
      logger.warn(message: "Klarna checkout scope was deallocated during cancel")
      return
    }
    checkoutScope.onDismiss()
  }

  // MARK: - Private Flow Methods

  private func handleError(_ error: Error, context: String) {
    logger.error(message: "Klarna \(context) failed: \(error.localizedDescription)")
    let primerError =
      error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
    guard let checkoutScope else {
      logger.error(message: "Klarna checkout scope was deallocated during \(context)")
      return
    }
    checkoutScope.handlePaymentError(primerError)
  }

  private func createSession() async {
    internalState = PrimerKlarnaState(step: .loading)

    do {
      let sessionResult = try await processKlarnaInteractor.createSession()
      klarnaClientToken = sessionResult.clientToken

      internalState = PrimerKlarnaState(
        step: .categorySelection,
        categories: sessionResult.categories
      )

      logger.debug(
        message: "Klarna session created with \(sessionResult.categories.count) categories")
    } catch {
      handleError(error, context: "session creation")
    }
  }

  private func loadPaymentView(for categoryId: String) async {
    guard let klarnaClientToken else {
      logger.error(message: "Klarna client token not available")
      handleError(
        PrimerError.klarnaError(
          message: "Payment session not properly initialized",
          diagnosticsId: UUID().uuidString
        ),
        context: "view loading"
      )
      return
    }

    do {
      let view = try await processKlarnaInteractor.configureForCategory(
        clientToken: klarnaClientToken,
        categoryId: categoryId
      )

      // Guard against race condition: user may have switched categories while loading
      guard internalState.selectedCategoryId == categoryId else { return }

      paymentView = view
      internalState = PrimerKlarnaState(
        step: .viewReady,
        categories: internalState.categories,
        selectedCategoryId: internalState.selectedCategoryId
      )
    } catch {
      logger.error(message: "Failed to load Klarna payment view: \(error.localizedDescription)")
      guard internalState.selectedCategoryId == categoryId else { return }
      handleError(error, context: "view loading")
    }
  }

  private func performAuthorization() async {
    guard let checkoutScope else {
      logger.warn(message: "Klarna checkout scope was deallocated before authorization")
      return
    }

    do {
      try await checkoutScope.invokeBeforePaymentCreate(
        paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
      )
    } catch {
      handleError(error, context: "before payment create")
      return
    }

    checkoutScope.startProcessing()

    await analyticsInteractor?.trackEvent(
      .paymentSubmitted,
      metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.klarna.rawValue))
    )

    await analyticsInteractor?.trackEvent(
      .paymentProcessingStarted,
      metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.klarna.rawValue))
    )

    do {
      let result = try await processKlarnaInteractor.authorize()

      switch result {
      case let .approved(authToken):
        authorizationToken = authToken
        await processPayment(authToken: authToken)

      case let .finalizationRequired(authToken):
        authorizationToken = authToken
        internalState = PrimerKlarnaState(
          step: .awaitingFinalization,
          categories: internalState.categories,
          selectedCategoryId: internalState.selectedCategoryId
        )

      case .declined:
        let primerError = PrimerError.klarnaError(
          message: "Klarna payment was declined",
          diagnosticsId: UUID().uuidString
        )
        checkoutScope.handlePaymentError(primerError)
      }
    } catch {
      handleError(error, context: "authorization")
    }
  }

  private func performFinalization() async {
    guard let checkoutScope else {
      logger.warn(message: "Klarna checkout scope was deallocated before finalization")
      return
    }
    checkoutScope.startProcessing()

    do {
      let result = try await processKlarnaInteractor.finalize()

      switch result {
      case let .approved(authToken):
        authorizationToken = authToken
        await processPayment(authToken: authToken)

      case .finalizationRequired:
        logger.error(message: "Unexpected finalizationRequired after finalize()")
        guard let authToken = authorizationToken else {
          handleError(
            PrimerError.klarnaError(
              message: "Authorization token not available after finalization",
              diagnosticsId: UUID().uuidString
            ),
            context: "finalization"
          )
          return
        }
        await processPayment(authToken: authToken)

      case .declined:
        let primerError = PrimerError.klarnaError(
          message: "Klarna finalization was declined",
          diagnosticsId: UUID().uuidString
        )
        checkoutScope.handlePaymentError(primerError)
      }
    } catch {
      handleError(error, context: "finalization")
    }
  }

  private func processPayment(authToken: String) async {
    do {
      let result = try await processKlarnaInteractor.tokenize(authToken: authToken)
      guard let checkoutScope else {
        logger.error(message: "Klarna checkout scope was deallocated during payment processing")
        return
      }
      checkoutScope.handlePaymentSuccess(result)
    } catch {
      handleError(error, context: "payment processing")
    }
  }
}
