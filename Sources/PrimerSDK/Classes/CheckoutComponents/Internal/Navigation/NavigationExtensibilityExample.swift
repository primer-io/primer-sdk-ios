//
//  NavigationExtensibilityExample.swift
//  PrimerSDK - CheckoutComponents
//
//  Examples of how to extend the navigation system in CheckoutComponents
//  Demonstrates Open/Closed Principle and protocol-based extensibility
//  Example extensibility patterns for CheckoutComponents navigation
//

import Foundation
import SwiftUI

// MARK: - Example: Extending Navigation System
// This file demonstrates how easy it is to extend the navigation system
// with new route types without modifying existing code (Open/Closed Principle)

@available(iOS 15.0, *)
enum VaultRoute: NavigationRoute {
    case vaultList
    case addPaymentMethod
    case editPaymentMethod(String)
    case deleteConfirmation(String)

    var id: String {
        switch self {
        case .vaultList: return "vault-list"
        case .addPaymentMethod: return "vault-add"
        case .editPaymentMethod(let id): return "vault-edit-\(id)"
        case .deleteConfirmation(let id): return "vault-delete-\(id)"
        }
    }

    var routeName: String {
        switch self {
        case .vaultList: return "Vault List"
        case .addPaymentMethod: return "Add Payment Method"
        case .editPaymentMethod: return "Edit Payment Method"
        case .deleteConfirmation: return "Delete Confirmation"
        }
    }

    var navigationBehavior: NavigationBehavior {
        switch self {
        case .vaultList:
            return .reset  // Start fresh
        case .addPaymentMethod, .editPaymentMethod:
            return .push   // Standard navigation
        case .deleteConfirmation:
            return .push   // Modal-like behavior
        }
    }

    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VaultRoute, rhs: VaultRoute) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Example: Specialized Coordinator for Vault Management
@available(iOS 15.0, *)
@MainActor
internal class VaultCoordinator: NavigationCoordinator, LogReporter {
    typealias Route = VaultRoute

    @Published var navigationStack: [VaultRoute] = []

    var currentRoute: VaultRoute {
        navigationStack.last ?? .vaultList
    }

    init() {
        // Start with vault list
        navigationStack = [.vaultList]
    }

    func navigate(to route: VaultRoute) {
        // Custom vault logic - handle special cases
        switch route {
        case .deleteConfirmation:
            // Delete confirmation is always a push regardless of current state
            navigationStack.append(route)
        default:
            // Standard navigation behavior
            switch route.navigationBehavior {
            case .push:
                navigationStack.append(route)
            case .reset:
                navigationStack = [route]
            case .replace:
                if !navigationStack.isEmpty {
                    navigationStack[navigationStack.count - 1] = route
                } else {
                    navigationStack = [route]
                }
            }
        }

        logger.debug(message: "🔐 [VaultCoordinator] " + route.routeName)
    }

    func goBack() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    func resetToRoot() {
        navigate(to: .vaultList)
    }

    func dismiss() {
        // Clear vault navigation and trigger dismissal
        navigationStack = []
        logger.debug(message: "🔐 [VaultCoordinator] Vault dismissed")
    }

    // Vault-specific navigation methods
    func addPaymentMethod() {
        navigate(to: .addPaymentMethod)
    }

    func editPaymentMethod(id: String) {
        navigate(to: .editPaymentMethod(id))
    }

    func confirmDelete(id: String) {
        navigate(to: .deleteConfirmation(id))
    }
}

// MARK: - Example: 3DS Flow Routes
@available(iOS 15.0, *)
enum ThreeDSRoute: NavigationRoute {
    case challenge
    case webView(URL)
    case processing
    case success
    case failure(String)

    var id: String {
        switch self {
        case .challenge: return "3ds-challenge"
        case .webView: return "3ds-webview"
        case .processing: return "3ds-processing"
        case .success: return "3ds-success"
        case .failure: return "3ds-failure"
        }
    }

    var routeName: String {
        switch self {
        case .challenge: return "3DS Challenge"
        case .webView: return "3DS Web Authentication"
        case .processing: return "3DS Processing"
        case .success: return "3DS Success"
        case .failure: return "3DS Failure"
        }
    }

    var navigationBehavior: NavigationBehavior {
        switch self {
        case .challenge:
            return .reset  // Start 3DS flow fresh
        case .webView, .processing:
            return .replace // Replace current step
        case .success, .failure:
            return .replace // Replace with result
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ThreeDSRoute, rhs: ThreeDSRoute) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Example Usage Demonstration
@available(iOS 15.0, *)
@MainActor
internal struct NavigationUsageExample {

    /// Example 1: Using the generic factory
    static func createDifferentCoordinators() {
        // Create checkout coordinator
        let checkoutCoordinator = NavigationCoordinatorFactory.createCheckoutCoordinator()

        // Create generic coordinator (demonstrates protocol usage)
        let genericCoordinator = NavigationCoordinatorFactory.createCoordinator(for: CheckoutRoute.self)

        // Both conform to NavigationCoordinator protocol
        print("Checkout coordinator depth: \(checkoutCoordinator.navigationDepth)")
        print("Generic coordinator can go back: \(genericCoordinator.canGoBack)")
    }

    /// Example 2: Protocol-based navigation
    static func demonstrateProtocolUsage<T: NavigationCoordinator>(coordinator: T) {
        // This function works with ANY NavigationCoordinator implementation
        print("Current route: \(coordinator.currentRoute.id)")
        print("Navigation info: \(coordinator.navigationInfo)")

        // Can call methods defined in the protocol
        if coordinator.canGoBack {
            coordinator.goBack()
        }
    }

    /// Example 3: Easy extension for new features
    static func demonstrateExtensibility() {
        let vaultCoordinator = VaultCoordinator()

        // Same protocol, different behavior
        demonstrateProtocolUsage(coordinator: vaultCoordinator)

        // Vault-specific navigation
        vaultCoordinator.addPaymentMethod()
        vaultCoordinator.editPaymentMethod(id: "card_123")
        vaultCoordinator.confirmDelete(id: "card_123")
    }

    /// Example 4: CheckoutComponents-specific flows
    static func demonstrateCheckoutComponentsFlows() {
        let checkoutCoordinator = CheckoutCoordinator()

        // Standard checkout flow (works with any payment method)
        checkoutCoordinator.navigate(to: .loading)
        checkoutCoordinator.navigate(to: .paymentMethodSelection)
        checkoutCoordinator.navigate(to: .paymentMethod("PAYMENT_CARD", .fromPaymentSelection))  // Example: card payment
        checkoutCoordinator.navigate(to: .selectCountry)

        // Navigate back to payment method
        checkoutCoordinator.goBack()

        // Alternative flow with different payment method
        checkoutCoordinator.navigate(to: .paymentMethod("APPLE_PAY", .fromPaymentSelection))  // Example: Apple Pay

        // Complete payment
        let result = CheckoutPaymentResult(paymentId: "pay_123", amount: "$10.00", method: "card")
        checkoutCoordinator.handlePaymentSuccess(result)
    }
}

// MARK: - Future Route Types (Examples)
// These demonstrate how easy it is to add new route types to CheckoutComponents

@available(iOS 15.0, *)
enum PayPalRoute: NavigationRoute {
    case login
    case authorization
    case processing
    case success
    case failure(String)

    var id: String { "paypal-\(self)" }
    var routeName: String { String(describing: self).capitalized }
    var navigationBehavior: NavigationBehavior {
        self == .login ? .reset : .push
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PayPalRoute, rhs: PayPalRoute) -> Bool { lhs.id == rhs.id }
}

@available(iOS 15.0, *)
enum ApplePayRoute: NavigationRoute {
    case authorization
    case processing
    case success
    case failure(String)

    var id: String { "applepay-\(self)" }
    var routeName: String { String(describing: self).capitalized }
    var navigationBehavior: NavigationBehavior {
        self == .authorization ? .reset : .replace
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ApplePayRoute, rhs: ApplePayRoute) -> Bool { lhs.id == rhs.id }
}

@available(iOS 15.0, *)
enum KlarnaRoute: NavigationRoute {
    case webView(URL)
    case processing
    case success
    case failure(String)

    var id: String { "klarna-\(self)" }
    var routeName: String { String(describing: self).capitalized }
    var navigationBehavior: NavigationBehavior {
        switch self {
        case .webView:
            return .reset
        default:
            return .replace
        }
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: KlarnaRoute, rhs: KlarnaRoute) -> Bool { lhs.id == rhs.id }
}
