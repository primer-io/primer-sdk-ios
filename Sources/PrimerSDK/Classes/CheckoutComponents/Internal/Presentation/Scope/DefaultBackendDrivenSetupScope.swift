//
//  DefaultBackendDrivenSetupScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
enum BackendDrivenSetupState: Equatable {
  case idle
  case settingUp
  case saved
  case failed
}

/// Saves a backend-driven method (Klarna on BDC first) without a payment. The backend publishes the
/// screens, so the scope only starts the setup and reports its token.
@available(iOS 15.0, *)
@MainActor
final class DefaultBackendDrivenSetupScope: PrimerPaymentMethodScope, ObservableObject, LogReporter {

  let paymentMethodType: String
  private(set) var presentationContext: PresentationContext

  var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  var state: AsyncStream<BackendDrivenSetupState> {
    AsyncStream { continuation in
      let task = Task { @MainActor in
        for await value in $internalState.values {
          continuation.yield(value)
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  @Published private var internalState = BackendDrivenSetupState.idle

  private weak var checkoutScope: DefaultCheckoutScope?
  private let repository: BackendDrivenSetupRepository
  private var setupTask: Task<Void, Never>?
  private var hasStarted = false

  init(
    paymentMethodType: String,
    checkoutScope: DefaultCheckoutScope,
    presentationContext: PresentationContext = .fromPaymentSelection,
    repository: BackendDrivenSetupRepository
  ) {
    self.paymentMethodType = paymentMethodType
    self.checkoutScope = checkoutScope
    self.presentationContext = presentationContext
    self.repository = repository
  }

  func start() {
    guard !hasStarted, setupTask == nil else { return }
    hasStarted = true
    submit()
  }

  func prepareForReentry() {
    hasStarted = false
  }

  func submit() {
    guard setupTask == nil, let checkoutScope else { return }
    setupTask = Task {
      await setUp(intent: checkoutScope.intent)
      setupTask = nil
    }
  }

  func cancel() {
    setupTask?.cancel()
    checkoutScope?.cancelActivePaymentMethod(returnToSelection: presentationContext.shouldShowBackButton)
  }

  private func setUp(intent: PrimerSessionIntent) async {
    internalState = .settingUp
    checkoutScope?.startProcessing(payingWith: self)

    do {
      let token = try await repository.setUp(paymentMethodType: paymentMethodType, intent: intent)
      internalState = .saved
      checkoutScope?.handleVaultSuccess(PrimerPaymentMethodToken(token: token, paymentMethodType: paymentMethodType))
    } catch is BackendDrivenCheckoutCancellation {
      internalState = .idle
      checkoutScope?.cancelActivePaymentMethod(returnToSelection: presentationContext.shouldShowBackButton)
    } catch {
      logger.error(message: "Backend-driven setup failed: \(error)")
      internalState = .failed
      let primerError = error as? PrimerError ?? PrimerError.unknown(message: "\(error)")
      checkoutScope?.handlePaymentError(primerError)
    }
  }
}
