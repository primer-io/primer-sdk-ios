//
//  DefaultApplePayScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@preconcurrency import PassKit
import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

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

  var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  private(set) var presentationContext: PresentationContext = .fromPaymentSelection

  private weak var checkoutScope: DefaultCheckoutScope?
  private var processPaymentInteractor: ProcessApplePayPaymentInteractor?
  private let applePayPresentationManager: ApplePayPresenting
  private var authorizationCoordinator: ApplePayAuthorizationCoordinator?
  private(set) var paymentTask: Task<Void, Never>?

  private let clientSessionActionsFactory: () -> ClientSessionActionsProtocol
  private let applePayRequestFactory: (ApplePayShippingSession.Mode) throws -> ApplePayRequest
  private let authorizationCoordinatorFactory: @MainActor (ApplePayShippingSession) -> ApplePayAuthorizationCoordinator

  init(
    checkoutScope: DefaultCheckoutScope,
    presentationContext: PresentationContext = .fromPaymentSelection,
    applePayPresentationManager: ApplePayPresenting = ApplePayPresentationManager(),
    clientSessionActionsFactory: @escaping () -> ClientSessionActionsProtocol = { ClientSessionActionsModule() },
    applePayRequestFactory: @escaping (ApplePayShippingSession.Mode) throws -> ApplePayRequest = {
      try ApplePayRequestBuilder.build(mode: $0)
    },
    authorizationCoordinatorFactory: @MainActor @escaping (ApplePayShippingSession) -> ApplePayAuthorizationCoordinator = {
      ApplePayAuthorizationCoordinator(shippingSession: $0)
    }
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
    paymentTask?.cancel()
    paymentTask = nil
    structuredState.isLoading = false
    checkoutScope?.cancelActivePaymentMethod(returnToSelection: presentationContext.shouldShowBackButton)
  }

  deinit {
    paymentTask?.cancel()
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

    paymentTask = Task { [self] in
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

      // Built per attempt: the option list, the commit and the gate must not survive a retry.
      let shippingSession = makeShippingSession()
      let applePayRequest = try applePayRequestFactory(shippingSession.mode)

      let coordinator = authorizationCoordinatorFactory(shippingSession)
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
        checkoutScope?.cancelActivePaymentMethod(returnToSelection: presentationContext.shouldShowBackButton)
        return
      }
      await handlePaymentError(error)

    } catch {
      await handlePaymentError(error)
    }
  }

  private func makeShippingSession() -> ApplePayShippingSession {
    let applePayOptions = PrimerSettings.current.paymentMethodOptions.applePayOptions
    return ApplePayShippingSession(
      mode: ApplePayShippingSession.resolveMode(
        checkoutModules: PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules,
        applePayOptions: applePayOptions
      ),
      requireShippingMethod: applePayOptions?.shippingOptions?.requireShippingMethod == true,
      addressChangeProvider: { [weak checkoutScope] in checkoutScope?.onShippingAddressChange },
      optionChangeProvider: { [weak checkoutScope] in checkoutScope?.onShippingOptionChange }
    )
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
