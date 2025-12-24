//
//  MockNavigator.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of CheckoutNavigator for testing
@available(iOS 15.0, *)
@MainActor
final class MockCheckoutNavigator {

    // MARK: - Call Tracking

    private(set) var navigateToLoadingCallCount = 0
    private(set) var navigateToPaymentSelectionCallCount = 0
    private(set) var navigateToPaymentMethodCallCount = 0
    private(set) var navigateToProcessingCallCount = 0
    private(set) var navigateToErrorCallCount = 0
    private(set) var handleOtherPaymentMethodsCallCount = 0
    private(set) var navigateBackCallCount = 0
    private(set) var dismissCallCount = 0

    private(set) var lastPaymentMethodType: String?
    private(set) var lastPresentationContext: PresentationContext?
    private(set) var lastError: PrimerError?

    // MARK: - Coordinator

    let coordinator: CheckoutCoordinator

    var checkoutCoordinator: CheckoutCoordinator {
        coordinator
    }

    var navigationEvents: AsyncStream<CheckoutRoute> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for await stack in coordinator.$navigationStack.values {
                    if let route = stack.last {
                        continuation.yield(route)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Initialization

    init() {
        self.coordinator = CheckoutCoordinator()
    }

    init(coordinator: CheckoutCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Navigation Methods

    func navigateToLoading() {
        navigateToLoadingCallCount += 1
        coordinator.navigate(to: .loading)
    }

    func navigateToPaymentSelection() {
        navigateToPaymentSelectionCallCount += 1
        coordinator.navigate(to: .paymentMethodSelection)
    }

    func navigateToPaymentMethod(_ type: String, context: PresentationContext) {
        navigateToPaymentMethodCallCount += 1
        lastPaymentMethodType = type
        lastPresentationContext = context
        coordinator.navigate(to: .paymentMethod(type, context))
    }

    func navigateToProcessing() {
        navigateToProcessingCallCount += 1
        coordinator.navigate(to: .processing)
    }

    func navigateToError(_ error: PrimerError) {
        navigateToErrorCallCount += 1
        lastError = error
        coordinator.navigate(to: .failure(error))
    }

    func handleOtherPaymentMethods() {
        handleOtherPaymentMethodsCallCount += 1
        coordinator.navigate(to: .paymentMethodSelection)
    }

    func navigateBack() {
        navigateBackCallCount += 1
        coordinator.goBack()
    }

    func dismiss() {
        dismissCallCount += 1
        coordinator.dismiss()
    }

    // MARK: - Test Helpers

    func reset() {
        navigateToLoadingCallCount = 0
        navigateToPaymentSelectionCallCount = 0
        navigateToPaymentMethodCallCount = 0
        navigateToProcessingCallCount = 0
        navigateToErrorCallCount = 0
        handleOtherPaymentMethodsCallCount = 0
        navigateBackCallCount = 0
        dismissCallCount = 0
        lastPaymentMethodType = nil
        lastPresentationContext = nil
        lastError = nil
    }

    var totalNavigationCallCount: Int {
        navigateToLoadingCallCount +
        navigateToPaymentSelectionCallCount +
        navigateToPaymentMethodCallCount +
        navigateToProcessingCallCount +
        navigateToErrorCallCount +
        handleOtherPaymentMethodsCallCount +
        navigateBackCallCount +
        dismissCallCount
    }
}
