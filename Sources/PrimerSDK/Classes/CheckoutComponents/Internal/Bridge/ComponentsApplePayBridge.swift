//
//  ComponentsApplePayBridge.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Bridge surface used by `primer-io-react-native` to drive Apple Pay through the Checkout
/// Components scope without going through `PrimerCheckout` (SwiftUI) or
/// `PrimerCheckoutPresenter` (UIKit). Mirrors `ComponentsBillingAddressBridge` and
/// `ComponentsClientSessionBridge`.
@available(iOS 15.0, *)
@MainActor
@_spi(PrimerInternal)
public final class ComponentsApplePayBridge {

    public let stateStream: AsyncStream<ComponentsApplePayState>
    private let stateContinuation: AsyncStream<ComponentsApplePayState>.Continuation

    /// The Checkout Components scope does NOT fire
    /// `PrimerDelegate.primerDidCompleteCheckoutWithData` — terminal results only propagate
    /// through `PrimerCheckoutScope.state`. This bridge observes that stream and re-emits
    /// Apple Pay outcomes so the RN bridge can route them into
    /// `PrimerCheckoutProvider.paymentOutcome` / `onCheckoutComplete` / `onError`.
    /// Cancellations do not emit (matching the card flow's behaviour).
    public let outcomeStream: AsyncStream<ComponentsApplePayOutcome>
    private let outcomeContinuation: AsyncStream<ComponentsApplePayOutcome>.Continuation

    private var initializer: CheckoutSDKInitializer?
    private var checkoutScope: DefaultCheckoutScope?
    private var applePayScope: (any PrimerApplePayScope)?
    private var stateObservationTask: Task<Void, Never>?
    private var outcomeObservationTask: Task<Void, Never>?

    public init() {
        // Streams are created at init (not in setup) so yields from setup can't race the
        // consumer attaching its iterator.
        var capturedStateContinuation: AsyncStream<ComponentsApplePayState>.Continuation!
        stateStream = AsyncStream { continuation in
            capturedStateContinuation = continuation
        }
        stateContinuation = capturedStateContinuation

        var capturedOutcomeContinuation: AsyncStream<ComponentsApplePayOutcome>.Continuation!
        outcomeStream = AsyncStream { continuation in
            capturedOutcomeContinuation = continuation
        }
        outcomeContinuation = capturedOutcomeContinuation
    }

    /// Reads `PrimerSettings.current` internally — settings are already populated globally
    /// by the prior `PrimerHeadlessUniversalCheckout.startWithClientToken` call.
    public func setup(clientToken: String) async throws {
        Analytics.Service.fire(event: Analytics.Event.sdk(
            name: "\(Self.self).\(#function)",
            params: ["category": "APPLE_PAY"]
        ))

        let initializer = CheckoutSDKInitializer(
            clientToken: clientToken,
            primerSettings: PrimerSettings.current,
            primerTheme: PrimerCheckoutTheme(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator(),
            presentationContext: .direct
        )

        let result = try await initializer.initialize()
        let scope = result.checkoutScope

        self.initializer = initializer
        checkoutScope = scope

        // `DefaultCheckoutScope.init` spawns an async Task that loads payment methods and
        // only then populates `paymentMethodScopeCache` (what `getPaymentMethodScope`
        // reads). Wait for `.ready` (or `.failure`) before resolving the Apple Pay scope.
        waitForReady: for await state in scope.state {
            switch state {
            case .ready:
                break waitForReady
            case let .failure(error):
                throw error
            default:
                continue
            }
        }

        guard let applePay = scope.getPaymentMethodScope((any PrimerApplePayScope).self) else {
            throw PrimerError.unableToPresentPaymentMethod(
                paymentMethodType: "APPLE_PAY",
                reason: "Apple Pay scope is not registered for this session"
            )
        }
        applePayScope = applePay

        startStateObservation(on: applePay)
        startOutcomeObservation(on: scope)
    }

    public func startPayment() async throws {
        guard let applePayScope else {
            throw PrimerError.unableToPresentPaymentMethod(
                paymentMethodType: "APPLE_PAY",
                reason: "Apple Pay bridge has not been set up. Call setup() first."
            )
        }
        applePayScope.submit()
    }

    public func cancel() async {
        applePayScope?.cancel()
    }

    public func dispose() async {
        Analytics.Service.fire(event: Analytics.Event.sdk(
            name: "\(Self.self).\(#function)",
            params: ["category": "APPLE_PAY"]
        ))

        stateObservationTask?.cancel()
        stateObservationTask = nil
        outcomeObservationTask?.cancel()
        outcomeObservationTask = nil
        stateContinuation.finish()
        outcomeContinuation.finish()
        checkoutScope?.onDismiss()
        checkoutScope = nil
        applePayScope = nil
        initializer?.cleanup()
        initializer = nil
        await DIContainer.clearContainer()
    }

    private func startStateObservation(on scope: any PrimerApplePayScope) {
        stateObservationTask?.cancel()
        stateObservationTask = Task { [stateContinuation] in
            for await state in scope.state {
                stateContinuation.yield(ComponentsApplePayState(from: state))
            }
        }
    }

    private func startOutcomeObservation(on scope: DefaultCheckoutScope) {
        outcomeObservationTask?.cancel()
        outcomeObservationTask = Task { [outcomeContinuation] in
            for await state in scope.state {
                switch state {
                case let .success(result):
                    outcomeContinuation.yield(ComponentsApplePayOutcome(from: result))
                case let .failure(error):
                    outcomeContinuation.yield(ComponentsApplePayOutcome(from: error))
                default:
                    continue
                }
            }
        }
    }
}

// MARK: - Bridge-Public Types

@available(iOS 15.0, *)
@_spi(PrimerInternal)
public struct ComponentsApplePayState: Sendable {

    public let isAvailable: Bool
    public let isLoading: Bool
    public let availabilityError: ComponentsApplePayAvailabilityError?

    public init(
        isAvailable: Bool,
        isLoading: Bool,
        availabilityError: ComponentsApplePayAvailabilityError?
    ) {
        self.isAvailable = isAvailable
        self.isLoading = isLoading
        self.availabilityError = availabilityError
    }
}

@available(iOS 15.0, *)
@_spi(PrimerInternal)
public struct ComponentsApplePayAvailabilityError: Sendable {

    public let code: String
    public let message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}

/// Cancellations do not produce an outcome (matching the card flow's "cancel = no
/// `paymentOutcome` change" behaviour).
@available(iOS 15.0, *)
@_spi(PrimerInternal)
public enum ComponentsApplePayOutcome: Sendable {
    case success(paymentId: String, status: String, amount: Int?, currencyCode: String?, paymentMethodType: String)
    case failure(errorCode: String, errorMessage: String, diagnosticsId: String)
}

@available(iOS 15.0, *)
extension ComponentsApplePayOutcome {
    init(from result: PaymentResult) {
        self = .success(
            paymentId: result.paymentId,
            status: String(describing: result.status),
            amount: result.amount,
            currencyCode: result.currencyCode,
            paymentMethodType: result.paymentMethodType ?? "APPLE_PAY"
        )
    }

    init(from error: PrimerError) {
        self = .failure(
            errorCode: error.errorId,
            errorMessage: error.errorDescription ?? "Apple Pay payment failed.",
            diagnosticsId: error.diagnosticsId
        )
    }
}

// MARK: - State Mapping

@available(iOS 15.0, *)
extension ComponentsApplePayState {
    init(from state: PrimerApplePayState) {
        isAvailable = state.isAvailable
        isLoading = state.isLoading
        availabilityError = state.availabilityError.map { message in
            ComponentsApplePayAvailabilityError(
                code: Self.stableCode(for: message),
                message: message
            )
        }
    }

    static func stableCode(for message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("os version") || lower.contains("ios 15") || lower.contains("unsupported os") {
            return "OS_VERSION_TOO_LOW"
        }
        if lower.contains("wallet") || lower.contains("no card") || lower.contains("no eligible card") {
            return "NO_WALLET_CARD"
        }
        if lower.contains("merchant identifier") || lower.contains("merchantidentifier") {
            return "MERCHANT_IDENTIFIER_MISSING"
        }
        if lower.contains("client session") || lower.contains("clientsession") {
            return "CHECKOUT_SESSION_INVALID"
        }
        return "UNKNOWN"
    }
}
