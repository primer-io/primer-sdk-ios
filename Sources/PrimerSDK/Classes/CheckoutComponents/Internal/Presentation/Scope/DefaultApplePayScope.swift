//
//  DefaultApplePayScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@preconcurrency import PassKit
import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class DefaultApplePayScope: PrimerApplePayScope, ObservableObject {

  @Published var structuredState: PrimerApplePayState

  var state: AsyncStream<PrimerApplePayState> {
    AsyncStream { continuation in
      let task = Task { [self] in
        continuation.yield(structuredState)

        for await _ in $structuredState.values {
          continuation.yield(structuredState)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  var screen: ApplePayScreenComponent?
  var applePayButton: ApplePayButtonComponent?

  private(set) var presentationContext: PresentationContext = .fromPaymentSelection

  private weak var checkoutScope: DefaultCheckoutScope?
  private var processPaymentInteractor: ProcessApplePayPaymentInteractor?
  private let applePayPresentationManager: ApplePayPresenting
  private var authorizationCoordinator: ApplePayAuthorizationCoordinator?

  private let clientSessionActionsFactory: () -> ClientSessionActionsProtocol
  private let applePayRequestFactory: () throws -> ApplePayRequest
  private let authorizationCoordinatorFactory: @MainActor () -> ApplePayAuthorizationCoordinator

  init(
    checkoutScope: DefaultCheckoutScope,
    presentationContext: PresentationContext = .fromPaymentSelection,
    applePayPresentationManager: ApplePayPresenting = ApplePayPresentationManager(),
    clientSessionActionsFactory: @escaping () -> ClientSessionActionsProtocol = { ClientSessionActionsModule() },
    applePayRequestFactory: @escaping () throws -> ApplePayRequest = { try ApplePayRequestBuilder.build() },
    authorizationCoordinatorFactory: @MainActor @escaping () -> ApplePayAuthorizationCoordinator = { ApplePayAuthorizationCoordinator() }
  ) {
    self.checkoutScope = checkoutScope
    self.presentationContext = presentationContext
    self.applePayPresentationManager = applePayPresentationManager
    self.clientSessionActionsFactory = clientSessionActionsFactory
    self.applePayRequestFactory = applePayRequestFactory
    self.authorizationCoordinatorFactory = authorizationCoordinatorFactory

    structuredState = applePayPresentationManager.isPresentable
      ? .available()
      : .unavailable(error: applePayPresentationManager.errorForDisplay.localizedDescription)

    Task { [self] in
      await setupInteractors()
    }
  }

  private func setupInteractors() async {
    do {
      guard let container = await DIContainer.current else {
        throw ContainerError.containerUnavailable
      }
      processPaymentInteractor = try await container.resolve(ProcessApplePayPaymentInteractor.self)
    } catch {
      // Interactor resolution failed - will be retried lazily during payment
    }
  }

  func start() {
    if applePayPresentationManager.isPresentable {
      structuredState = .available(
        buttonStyle: structuredState.buttonStyle,
        buttonType: structuredState.buttonType,
        cornerRadius: structuredState.cornerRadius
      )
    } else {
      structuredState = .unavailable(error: applePayPresentationManager.errorForDisplay.localizedDescription)
    }
  }

  func cancel() {
    structuredState.isLoading = false
    if presentationContext.shouldShowBackButton {
      checkoutScope?.checkoutNavigator.navigateBack()
    }
  }

  func onBack() {
    if presentationContext.shouldShowBackButton {
      checkoutScope?.checkoutNavigator.navigateBack()
    }
  }

  func onDismiss() {
    checkoutScope?.onDismiss()
  }

  func submit() {
    guard structuredState.isAvailable, !structuredState.isLoading else { return }

    Task { [self] in
      await performPayment()
    }
  }

  private func performPayment() async {
    structuredState.isLoading = true

    do {
      try await checkoutScope?.invokeBeforePaymentCreate(
        paymentMethodType: PrimerPaymentMethodType.applePay.rawValue
      )

      let clientSessionActions = clientSessionActionsFactory()
      try await clientSessionActions.selectPaymentMethodIfNeeded(
        PrimerPaymentMethodType.applePay.rawValue,
        cardNetwork: nil
      )

      let applePayRequest = try applePayRequestFactory()

      let coordinator = authorizationCoordinatorFactory()
      authorizationCoordinator = coordinator

      let payment = try await coordinator.authorize(
        with: applePayRequest,
        presentationManager: applePayPresentationManager
      )

      var interactor = processPaymentInteractor
      if interactor == nil {
        if let container = await DIContainer.current {
          interactor = try? await container.resolve(ProcessApplePayPaymentInteractor.self)
          processPaymentInteractor = interactor
        }
      }

      guard let interactor else {
        throw PrimerError.invalidArchitecture(
          description: "ProcessApplePayPaymentInteractor not initialized",
          recoverSuggestion: "Ensure proper SDK initialization"
        )
      }

      let result = try await interactor.execute(payment: payment)
      await handlePaymentSuccess(result)

    } catch let error as PrimerError {
      if case .cancelled = error {
        structuredState.isLoading = false
        return
      }
      await handlePaymentError(error)

    } catch {
      await handlePaymentError(error)
    }
  }

  private func handlePaymentSuccess(_ result: PaymentResult) async {
    structuredState.isLoading = false

    guard let checkoutScope else { return }
    checkoutScope.handlePaymentSuccess(result)
  }

  private func handlePaymentError(_ error: Error) async {
    structuredState.isLoading = false

    let primerError =
      error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)

    guard let checkoutScope else { return }
    checkoutScope.handlePaymentError(primerError)
  }

  // swiftlint:disable identifier_name

  func PrimerApplePayButton(action: @escaping () -> Void) -> AnyView {
    AnyView(
      ApplePayButtonView(
        style: structuredState.buttonStyle,
        type: structuredState.buttonType,
        cornerRadius: structuredState.cornerRadius,
        action: action
      )
    )
  }

  // swiftlint:enable identifier_name
}

// MARK: - Apple Pay Authorization Coordinator

/// Coordinator that handles PKPaymentAuthorizationControllerDelegate callbacks.
/// Bridges PassKit delegate pattern to async/await.
@available(iOS 15.0, *)
@MainActor
final class ApplePayAuthorizationCoordinator: NSObject, PKPaymentAuthorizationControllerDelegate {

  private var authorizationContinuation: CheckedContinuation<PKPayment, Error>?
  private var completionHandler: ((PKPaymentAuthorizationResult) -> Void)?
  private var isCancelled = true
  private var didTimeout = false

  func authorize(
    with request: ApplePayRequest,
    presentationManager: ApplePayPresenting
  ) async throws -> PKPayment {
    try await withCheckedThrowingContinuation { continuation in
      self.authorizationContinuation = continuation
      self.isCancelled = true
      self.didTimeout = false

      Task { @MainActor in
        do {
          try await presentationManager.present(withRequest: request, delegate: self)
        } catch {
          self.authorizationContinuation?.resume(throwing: error)
          self.authorizationContinuation = nil
        }
      }
    }
  }

  // MARK: - PKPaymentAuthorizationControllerDelegate

  func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
    controller.dismiss(completion: nil)

    if isCancelled {
      let error = PrimerError.cancelled(
        paymentMethodType: PrimerPaymentMethodType.applePay.rawValue)
      authorizationContinuation?.resume(throwing: error)
      authorizationContinuation = nil
    } else if didTimeout {
      let error = PrimerError.applePayTimedOut()
      authorizationContinuation?.resume(throwing: error)
      authorizationContinuation = nil
    }
  }

  func paymentAuthorizationController(
    _ controller: PKPaymentAuthorizationController,
    didAuthorizePayment payment: PKPayment,
    handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
  ) {
    isCancelled = false
    didTimeout = false

    // Complete the authorization with success
    completion(PKPaymentAuthorizationResult(status: .success, errors: nil))

    // Capture and clear continuation before dismiss to avoid @MainActor access in @Sendable closure
    let continuation = authorizationContinuation
    authorizationContinuation = nil
    controller.dismiss {
      continuation?.resume(returning: payment)
    }
  }
}
