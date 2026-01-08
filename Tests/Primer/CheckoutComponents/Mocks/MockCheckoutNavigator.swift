//
//  MockCheckoutNavigator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@testable import PrimerSDK

/// Mock implementation of CheckoutNavigator for testing navigation events.
/// Provides controlled AsyncStream, call tracking, and captured parameters.
@available(iOS 15.0, *)
@MainActor
final class MockCheckoutNavigator: ObservableObject {

    // MARK: - Underlying Coordinator

    private let coordinator: MockCheckoutCoordinator

    // MARK: - AsyncStream Support

    private var continuation: AsyncStream<CheckoutRoute>.Continuation?
    private(set) var emittedRoutes: [CheckoutRoute] = []

    /// Navigation state as AsyncStream (matches real implementation)
    var navigationEvents: AsyncStream<CheckoutRoute> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
            // Emit current route as initial value
            if let currentRoute = self?.coordinator.currentRoute {
                continuation.yield(currentRoute)
            }
        }
    }

    // MARK: - Call Tracking

    private(set) var navigateToLoadingCallCount = 0
    private(set) var navigateToPaymentSelectionCallCount = 0
    private(set) var navigateToVaultedPaymentMethodsCallCount = 0
    private(set) var navigateToDeleteConfirmationCallCount = 0
    private(set) var navigateToPaymentMethodCallCount = 0
    private(set) var navigateToProcessingCallCount = 0
    private(set) var navigateToErrorCallCount = 0
    private(set) var handleOtherPaymentMethodsCallCount = 0
    private(set) var navigateBackCallCount = 0
    private(set) var dismissCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastPaymentMethodType: String?
    private(set) var lastPresentationContext: PresentationContext?
    private(set) var lastError: PrimerError?
    private(set) var lastVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?

    // MARK: - Initialization

    init(coordinator: MockCheckoutCoordinator? = nil) {
        self.coordinator = coordinator ?? MockCheckoutCoordinator()
    }

    // MARK: - Navigation Methods (match real implementation API)

    func navigateToLoading() {
        navigateToLoadingCallCount += 1
        coordinator.navigate(to: .loading)
        emitCurrentRoute()
    }

    func navigateToPaymentSelection() {
        navigateToPaymentSelectionCallCount += 1
        coordinator.navigate(to: .paymentMethodSelection)
        emitCurrentRoute()
    }

    func navigateToVaultedPaymentMethods() {
        navigateToVaultedPaymentMethodsCallCount += 1
        coordinator.navigate(to: .vaultedPaymentMethods)
        emitCurrentRoute()
    }

    func navigateToDeleteVaultedPaymentMethodConfirmation(
        _ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
    ) {
        navigateToDeleteConfirmationCallCount += 1
        lastVaultedPaymentMethod = method
        coordinator.navigate(to: .deleteVaultedPaymentMethodConfirmation(method))
        emitCurrentRoute()
    }

    func navigateToPaymentMethod(_ paymentMethodType: String, context: PresentationContext = .fromPaymentSelection) {
        navigateToPaymentMethodCallCount += 1
        lastPaymentMethodType = paymentMethodType
        lastPresentationContext = context
        coordinator.navigate(to: .paymentMethod(paymentMethodType, context))
        emitCurrentRoute()
    }

    func navigateToProcessing() {
        navigateToProcessingCallCount += 1
        coordinator.navigate(to: .processing)
        emitCurrentRoute()
    }

    func navigateToError(_ error: PrimerError) {
        navigateToErrorCallCount += 1
        lastError = error
        coordinator.handlePaymentFailure(error)
        emitCurrentRoute()
    }

    func handleOtherPaymentMethods() {
        handleOtherPaymentMethodsCallCount += 1
        coordinator.navigate(to: .paymentMethodSelection)
        emitCurrentRoute()
    }

    func navigateBack() {
        navigateBackCallCount += 1
        coordinator.goBack()
        emitCurrentRoute()
    }

    func dismiss() {
        dismissCallCount += 1
        coordinator.dismiss()
        emitCurrentRoute()
    }

    // MARK: - Coordinator Access (matches real implementation)

    var checkoutCoordinator: MockCheckoutCoordinator {
        coordinator
    }

    // MARK: - Test Helpers

    func emit(_ route: CheckoutRoute) {
        emittedRoutes.append(route)
        continuation?.yield(route)
    }

    func finish() {
        continuation?.finish()
    }

    /// Resets all call counts and captured parameters
    func reset() {
        navigateToLoadingCallCount = 0
        navigateToPaymentSelectionCallCount = 0
        navigateToVaultedPaymentMethodsCallCount = 0
        navigateToDeleteConfirmationCallCount = 0
        navigateToPaymentMethodCallCount = 0
        navigateToProcessingCallCount = 0
        navigateToErrorCallCount = 0
        handleOtherPaymentMethodsCallCount = 0
        navigateBackCallCount = 0
        dismissCallCount = 0

        lastPaymentMethodType = nil
        lastPresentationContext = nil
        lastError = nil
        lastVaultedPaymentMethod = nil
        emittedRoutes = []

        coordinator.reset()
    }

    var totalNavigationCalls: Int {
        navigateToLoadingCallCount +
        navigateToPaymentSelectionCallCount +
        navigateToVaultedPaymentMethodsCallCount +
        navigateToDeleteConfirmationCallCount +
        navigateToPaymentMethodCallCount +
        navigateToProcessingCallCount +
        navigateToErrorCallCount +
        handleOtherPaymentMethodsCallCount +
        navigateBackCallCount +
        dismissCallCount
    }

    // MARK: - Private Helpers

    private func emitCurrentRoute() {
        let route = coordinator.currentRoute
        emittedRoutes.append(route)
        continuation?.yield(route)
    }
}

// MARK: - Factory Methods

@available(iOS 15.0, *)
extension MockCheckoutNavigator {

    static func atPaymentSelection() -> MockCheckoutNavigator {
        MockCheckoutNavigator(coordinator: .atPaymentSelection())
    }

    static func atCardPayment() -> MockCheckoutNavigator {
        MockCheckoutNavigator(coordinator: .atCardPayment())
    }

    static func withNavigationBlocked() -> MockCheckoutNavigator {
        MockCheckoutNavigator(coordinator: .withNavigationBlocked())
    }
}
