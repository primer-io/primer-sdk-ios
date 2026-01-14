//
//  DefaultApplePayScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import PassKit

/// Default implementation of PrimerApplePayScope.
/// Manages Apple Pay state, button customization, and payment flow coordination.
@available(iOS 15.0, *)
@MainActor
public final class DefaultApplePayScope: PrimerApplePayScope, ObservableObject {

    // MARK: - State

    @Published var structuredState: ApplePayFormState

    public var state: AsyncStream<ApplePayFormState> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                // Yield initial state immediately
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

    // MARK: - Availability

    public var isAvailable: Bool {
        structuredState.isAvailable
    }

    public var availabilityError: String? {
        structuredState.availabilityError
    }

    // MARK: - Button Customization

    public var buttonStyle: PKPaymentButtonStyle {
        get { structuredState.buttonStyle }
        set { structuredState.buttonStyle = newValue }
    }

    public var buttonType: PKPaymentButtonType {
        get { structuredState.buttonType }
        set { structuredState.buttonType = newValue }
    }

    public var cornerRadius: CGFloat {
        get { structuredState.cornerRadius }
        set { structuredState.cornerRadius = newValue }
    }

    // MARK: - UI Customization

    public var screen: ((_ scope: any PrimerApplePayScope) -> any View)?
    public var applePayButton: ((_ action: @escaping () -> Void) -> any View)?

    // MARK: - Presentation Context

    public private(set) var presentationContext: PresentationContext = .fromPaymentSelection

    // MARK: - Dependencies

    private weak var checkoutScope: DefaultCheckoutScope?
    private var processPaymentInteractor: ProcessApplePayPaymentInteractor?
    private let applePayPresentationManager: ApplePayPresenting
    private var authorizationCoordinator: ApplePayAuthorizationCoordinator?

    // MARK: - Initialization

    init(
        checkoutScope: DefaultCheckoutScope,
        presentationContext: PresentationContext = .fromPaymentSelection,
        applePayPresentationManager: ApplePayPresenting = ApplePayPresentationManager()
    ) {
        self.checkoutScope = checkoutScope
        self.presentationContext = presentationContext
        self.applePayPresentationManager = applePayPresentationManager

        // Initialize state based on availability
        let isPresentable = applePayPresentationManager.isPresentable
        let availabilityError = applePayPresentationManager.errorForDisplay
        if isPresentable {
            self.structuredState = .available()
        } else {
            self.structuredState = .unavailable(error: availabilityError.localizedDescription)
        }

        Task {
            await setupInteractors()
        }
    }

    // MARK: - Setup

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

    // MARK: - PrimerPaymentMethodScope

    public func start() {
        if applePayPresentationManager.isPresentable {
            structuredState = .available(
                buttonStyle: structuredState.buttonStyle,
                buttonType: structuredState.buttonType,
                cornerRadius: structuredState.cornerRadius
            )
        } else {
            let error = applePayPresentationManager.errorForDisplay
            structuredState = .unavailable(error: error.localizedDescription)
        }
    }

    public func cancel() {
        structuredState.isLoading = false
        if presentationContext.shouldShowBackButton {
            checkoutScope?.checkoutNavigator.navigateBack()
        }
    }

    public func onBack() {
        if presentationContext.shouldShowBackButton {
            checkoutScope?.checkoutNavigator.navigateBack()
        }
    }

    public func onDismiss() {
        checkoutScope?.onDismiss()
    }

    // MARK: - Pay Action

    public func pay() {
        guard structuredState.isAvailable else { return }
        guard !structuredState.isLoading else { return }

        Task {
            await performPayment()
        }
    }

    private func performPayment() async {
        structuredState.isLoading = true

        do {
            // Select payment method
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            try await clientSessionActionsModule.selectPaymentMethodIfNeeded(
                PrimerPaymentMethodType.applePay.rawValue,
                cardNetwork: nil
            )

            // Build Apple Pay request
            let applePayRequest = try ApplePayRequestBuilder.build()

            // Create coordinator and present Apple Pay
            let coordinator = ApplePayAuthorizationCoordinator()
            self.authorizationCoordinator = coordinator

            // Present and await authorization
            let payment = try await coordinator.authorize(
                with: applePayRequest,
                presentationManager: applePayPresentationManager
            )

            // Lazily resolve interactor if not already set
            var interactor = processPaymentInteractor
            if interactor == nil {
                if let container = await DIContainer.current {
                    interactor = try? await container.resolve(ProcessApplePayPaymentInteractor.self)
                    processPaymentInteractor = interactor
                }
            }

            guard let interactor = interactor else {
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

        guard let checkoutScope = checkoutScope else { return }
        checkoutScope.handlePaymentSuccess(result)
    }

    private func handlePaymentError(_ error: Error) async {
        structuredState.isLoading = false

        let primerError = error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)

        guard let checkoutScope = checkoutScope else { return }
        checkoutScope.handlePaymentError(primerError)
    }

    // MARK: - ViewBuilder

    public func PrimerApplePayButton(action: @escaping () -> Void) -> AnyView {
        AnyView(
            ApplePayButtonView(
                style: structuredState.buttonStyle,
                type: structuredState.buttonType,
                cornerRadius: structuredState.cornerRadius,
                action: action
            )
        )
    }
}

// MARK: - Apple Pay Authorization Coordinator

/// Coordinator that handles PKPaymentAuthorizationControllerDelegate callbacks.
/// Bridges PassKit delegate pattern to async/await.
@available(iOS 15.0, *)
final class ApplePayAuthorizationCoordinator: NSObject, PKPaymentAuthorizationControllerDelegate {

    // MARK: - Continuations

    private var authorizationContinuation: CheckedContinuation<PKPayment, Error>?
    private var completionHandler: ((PKPaymentAuthorizationResult) -> Void)?

    // MARK: - State

    private var isCancelled = true
    private var didTimeout = false

    // MARK: - Authorization

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
            let error = PrimerError.cancelled(paymentMethodType: PrimerPaymentMethodType.applePay.rawValue)
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

        // Dismiss and resume continuation
        controller.dismiss { [weak self] in
            self?.authorizationContinuation?.resume(returning: payment)
            self?.authorizationContinuation = nil
        }
    }
}
