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
internal struct CardPaymentMethod: PaymentMethodProtocol {

    /// The payment method type identifier for cards
    internal static let paymentMethodType: String = "PAYMENT_CARD"

    /// Creates a card form scope for this payment method
    /// - Parameters:
    ///   - checkoutScope: The parent checkout scope for navigation coordination
    ///   - diContainer: The dependency injection container for resolving services (not used by card form)
    /// - Returns: A configured DefaultCardFormScope instance
    @MainActor
    internal static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: DIContainer
    ) throws -> DefaultCardFormScope {

        // Check if checkoutScope is DefaultCheckoutScope to access internal methods
        guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
            throw PrimerError.invalidArchitecture(
                description: "CardPaymentMethod requires DefaultCheckoutScope",
                recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation",
                userInfo: ["paymentMethodType": paymentMethodType],
                diagnosticsId: UUID().uuidString
            )
        }

        // Create the card form scope using the existing initialization pattern
        // The DefaultCardFormScope gets its DIContainer internally from DIContainer.shared
        return DefaultCardFormScope(checkoutScope: defaultCheckoutScope)
    }
}

// MARK: - Registration Helper

@available(iOS 15.0, *)
extension CardPaymentMethod {

    /// Registers the card payment method with the global registry
    /// This should be called during SDK initialization
    @MainActor
    internal static func register() {
        PaymentMethodRegistry.shared.register(CardPaymentMethod.self)
    }
}
