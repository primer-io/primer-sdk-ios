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

    /// Navigate to success screen and handle final checkout completion
    @MainActor
    public func navigateToSuccess() {
        navigationSubject.send(.navigateToSuccess)

        // Handle the checkout completion with existing delegate system
        Task {
            await handleCheckoutCompletion()
        }
    }

    /// Handle successful checkout completion
    @MainActor
    private func handleCheckoutCompletion() async {
        // Create minimal checkout data for successful payment
        // In a full implementation, this would contain the actual payment result
        let checkoutData = PrimerCheckoutData(payment: nil, additionalInfo: nil)

        // Call the legacy delegate to maintain compatibility
        // The delegate proxy already handles UI dismissal
        PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
    }

    /// Navigate to error screen with message
    @MainActor
    public func navigateToError(_ message: String) {
        navigationSubject.send(.navigateToError(message))

        // Handle the error with existing delegate system
        Task {
            await handleCheckoutError(message)
        }
    }

    /// Handle checkout error
    @MainActor
    private func handleCheckoutError(_ message: String) async {
        // Create a generic error for the delegate
        let nsError = NSError(domain: "ComposableCheckout", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        let error = PrimerError.underlyingErrors(errors: [nsError], userInfo: [String: String]?.errorUserInfoDictionary(), diagnosticsId: UUID().uuidString)

        // Call the legacy delegate to maintain compatibility
        PrimerDelegateProxy.primerDidFailWithError(error, data: nil) { _ in
            // Handle error decision - the delegate proxy will manage UI dismissal if needed
        }
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
