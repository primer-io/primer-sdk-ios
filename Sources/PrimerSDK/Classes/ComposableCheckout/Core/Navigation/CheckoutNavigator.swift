//
//  CheckoutNavigator.swift
//  PrimerSDK
//
//  Created on 18.06.2025.
//

import SwiftUI
import Combine

/// Navigation events for the checkout flow
@available(iOS 15.0, *)
public enum NavigationEvent {
    case navigateToPaymentSelection
    case navigateToCardForm
    case navigateToApplePay
    case navigateToPayPal
    case navigateToSuccess
    case navigateToError(String)
    case navigateBack
}

/// Navigator class that handles navigation events using Combine instead of NotificationCenter
@available(iOS 15.0, *)
public class CheckoutNavigator: ObservableObject {

    // MARK: - Private Properties

    private let navigationSubject = PassthroughSubject<NavigationEvent, Never>()

    // MARK: - Public Properties

    /// Publisher for navigation events
    public var navigationEvents: AnyPublisher<NavigationEvent, Never> {
        navigationSubject.eraseToAnyPublisher()
    }

    // MARK: - Navigation Methods

    /// Navigate to payment selection screen
    @MainActor
    public func navigateToPaymentSelection() {
        navigationSubject.send(.navigateToPaymentSelection)
    }

    /// Navigate to card form
    @MainActor
    public func navigateToCardForm() {
        navigationSubject.send(.navigateToCardForm)
    }

    /// Navigate to Apple Pay
    @MainActor
    public func navigateToApplePay() {
        navigationSubject.send(.navigateToApplePay)
    }

    /// Navigate to PayPal
    @MainActor
    public func navigateToPayPal() {
        navigationSubject.send(.navigateToPayPal)
    }

    /// Navigate to success screen
    @MainActor
    public func navigateToSuccess() {
        navigationSubject.send(.navigateToSuccess)
    }

    /// Navigate to error screen with message
    @MainActor
    public func navigateToError(_ message: String) {
        navigationSubject.send(.navigateToError(message))
    }

    /// Navigate back
    @MainActor
    public func navigateBack() {
        navigationSubject.send(.navigateBack)
    }
}

/// Environment key for CheckoutNavigator
@available(iOS 15.0, *)
public struct CheckoutNavigatorKey: EnvironmentKey {
    public static let defaultValue: CheckoutNavigator = CheckoutNavigator()
}

@available(iOS 15.0, *)
public extension EnvironmentValues {
    var checkoutNavigator: CheckoutNavigator {
        get { self[CheckoutNavigatorKey.self] }
        set { self[CheckoutNavigatorKey.self] = newValue }
    }
}
