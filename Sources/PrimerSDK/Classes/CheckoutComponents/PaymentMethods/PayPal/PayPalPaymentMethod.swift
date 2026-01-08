//
//  PayPalPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct PayPalPaymentMethod: PaymentMethodProtocol {

    typealias ScopeType = DefaultPayPalScope

    static let paymentMethodType: String = PrimerPaymentMethodType.payPal.rawValue

    /// Creates a PayPal scope for this payment method
    /// - Parameters:
    ///   - checkoutScope: The parent checkout scope for navigation coordination
    ///   - diContainer: The dependency injection container used to resolve PayPal dependencies
    /// - Returns: A configured DefaultPayPalScope instance
    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> DefaultPayPalScope {

        // Check if checkoutScope is DefaultCheckoutScope to access internal methods
        guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
            throw PrimerError.invalidArchitecture(
                description: "PayPalPaymentMethod requires DefaultCheckoutScope",
                recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
            )
        }

        // Determine the correct presentation context based on the number of available payment methods
        let logger = PrimerLogging.shared.logger
        let availableMethodsCount = defaultCheckoutScope.availablePaymentMethods.count

        let paymentMethodContext: PresentationContext
        if availableMethodsCount > 1 {
            // Multiple payment methods means we came from payment selection - show back button
            paymentMethodContext = .fromPaymentSelection
        } else {
            // Single payment method means direct navigation - no back button needed
            paymentMethodContext = .direct
        }

        do {
            let processPayPalInteractor: ProcessPayPalPaymentInteractor = try diContainer.resolveSync(ProcessPayPalPaymentInteractor.self)
            let analyticsInteractor = try? diContainer.resolveSync(CheckoutComponentsAnalyticsInteractorProtocol.self)

            return DefaultPayPalScope(
                checkoutScope: defaultCheckoutScope,
                presentationContext: paymentMethodContext,
                processPayPalInteractor: processPayPalInteractor,
                analyticsInteractor: analyticsInteractor
            )
        } catch let primerError as PrimerError {
            throw primerError
        } catch {
            logger.error(message: "❌ [PayPalPaymentMethod] Failed to resolve PayPal payment dependencies: \(error)")
            throw PrimerError.invalidArchitecture(
                description: "Required PayPal payment dependencies could not be resolved",
                recoverSuggestion: "Ensure CheckoutComponents DI registration runs before presenting PayPal."
            )
        }
    }

    /// Creates the view for PayPal payments by retrieving the PayPal scope and rendering the appropriate UI.
    /// This method handles custom screens in priority order:
    /// 1. payPalScope.screen (scope-based customization)
    /// 2. Default PayPalView
    /// - Parameter checkoutScope: The parent checkout scope that manages this payment method
    /// - Returns: The PayPal view, or nil if the scope cannot be retrieved
    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        // Get the cached PayPal scope from the checkout scope
        guard let payPalScope = checkoutScope.getPaymentMethodScope(DefaultPayPalScope.self) else {
            return nil
        }

        // Check if custom screen is provided
        if let customScreen = payPalScope.screen {
            return AnyView(customScreen(payPalScope))
        } else {
            return AnyView(PayPalView(scope: payPalScope))
        }
    }

    /// Provides custom UI for this payment method using ViewBuilder.
    /// - Parameter content: A ViewBuilder closure that uses the PayPal scope as a parameter
    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (DefaultPayPalScope) -> V) -> AnyView {
        // This method would be called with a custom ViewBuilder implementation
        // For now, return a placeholder as the actual implementation would require
        // instantiating the scope and passing it to the content closure
        fatalError("Custom content method should be implemented by the CheckoutComponents framework")
    }

    /// Provides the default UI implementation for PayPal payments.
    @MainActor
    func defaultContent() -> AnyView {
        // This would return the default PayPalView
        // For now, return a placeholder as the actual implementation would require
        // proper scope creation and screen instantiation
        fatalError("Default content method should be implemented by the CheckoutComponents framework")
    }
}

// MARK: - Registration Helper

@available(iOS 15.0, *)
extension PayPalPaymentMethod {

    @MainActor
    static func register() {
        PaymentMethodRegistry.shared.register(PayPalPaymentMethod.self)
    }
}
