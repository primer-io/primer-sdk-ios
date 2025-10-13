//
//  CardPaymentMethod.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 26.6.25.
//

import SwiftUI

/// Card payment method implementation conforming to PaymentMethodProtocol.
/// Provides self-contained card payment functionality with scope creation.
@available(iOS 15.0, *)
struct CardPaymentMethod: PaymentMethodProtocol {

    /// The scope type this payment method creates
    typealias ScopeType = DefaultCardFormScope

    /// The payment method type identifier for cards
    static let paymentMethodType: String = "PAYMENT_CARD"

    /// Creates a card form scope for this payment method
    /// - Parameters:
    ///   - checkoutScope: The parent checkout scope for navigation coordination
    ///   - diContainer: The dependency injection container used to resolve card form dependencies
    /// - Returns: A configured DefaultCardFormScope instance
    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> DefaultCardFormScope {

        // Check if checkoutScope is DefaultCheckoutScope to access internal methods
        guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
            throw PrimerError.invalidArchitecture(
                description: "CardPaymentMethod requires DefaultCheckoutScope",
                recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
            )
        }

        // Determine the correct presentation context based on the number of available payment methods
        let logger = PrimerLogging.shared.logger
        let availableMethodsCount = defaultCheckoutScope.availablePaymentMethods.count
        let checkoutContext = defaultCheckoutScope.presentationContext

        logger.info(message: "🧭 [CardPaymentMethod] Creating card scope with context decision:")
        logger.info(message: "🧭 [CardPaymentMethod]   - Available payment methods: \(availableMethodsCount)")
        logger.info(message: "🧭 [CardPaymentMethod]   - Checkout scope context: \(checkoutContext)")

        let paymentMethodContext: PresentationContext
        if availableMethodsCount > 1 {
            // Multiple payment methods means we came from payment selection - show back button
            paymentMethodContext = .fromPaymentSelection
            logger.info(message: "🧭 [CardPaymentMethod]   - Decision: MULTIPLE methods → using .fromPaymentSelection (back button will show)")
        } else {
            // Single payment method means direct navigation - no back button needed
            paymentMethodContext = .direct
            logger.info(message: "🧭 [CardPaymentMethod]   - Decision: SINGLE method → using .direct (no back button)")
        }

        logger.info(message: "🧭 [CardPaymentMethod]   - Final card scope context: \(paymentMethodContext)")

        do {
            let processCardInteractor: ProcessCardPaymentInteractor = try diContainer.resolveSync(ProcessCardPaymentInteractor.self)
            let validateInputInteractor = try? diContainer.resolveSync(ValidateInputInteractor.self)
            let cardNetworkDetectionInteractor = try? diContainer.resolveSync(CardNetworkDetectionInteractor.self)

            if validateInputInteractor == nil {
                logger.debug(message: "⚠️ [CardPaymentMethod] ValidateInputInteractor not registered – using local validation only")
            }

            if cardNetworkDetectionInteractor == nil {
                logger.warn(message: "⚠️ [CardPaymentMethod] CardNetworkDetectionInteractor not registered – co-badged detection disabled")
            }

            return DefaultCardFormScope(
                checkoutScope: defaultCheckoutScope,
                presentationContext: paymentMethodContext,
                processCardPaymentInteractor: processCardInteractor,
                validateInputInteractor: validateInputInteractor,
                cardNetworkDetectionInteractor: cardNetworkDetectionInteractor
            )
        } catch let primerError as PrimerError {
            throw primerError
        } catch {
            logger.error(message: "❌ [CardPaymentMethod] Failed to resolve card payment dependencies: \(error)")
            throw PrimerError.invalidArchitecture(
                description: "ProcessCardPaymentInteractor could not be resolved",
                recoverSuggestion: "Ensure CheckoutComponents DI registration runs before presenting the Card form."
            )
        }
    }

    /// Provides custom UI for this payment method using ViewBuilder.
    /// - Parameter content: A ViewBuilder closure that uses the card form scope as a parameter
    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (DefaultCardFormScope) -> V) -> AnyView {
        // This method would be called with a custom ViewBuilder implementation
        // For now, return a placeholder as the actual implementation would require
        // instantiating the scope and passing it to the content closure
        fatalError("Custom content method should be implemented by the CheckoutComponents framework")
    }

    /// Provides the default UI implementation for card payments.
    @MainActor
    func defaultContent() -> AnyView {
        // This would return the default CardFormScreen
        // For now, return a placeholder as the actual implementation would require
        // proper scope creation and screen instantiation
        fatalError("Default content method should be implemented by the CheckoutComponents framework")
    }
}

// MARK: - Registration Helper

@available(iOS 15.0, *)
extension CardPaymentMethod {

    /// Registers the card payment method with the global registry
    /// This should be called during SDK initialization
    @MainActor
    static func register() {
        PaymentMethodRegistry.shared.register(CardPaymentMethod.self)
    }
}
