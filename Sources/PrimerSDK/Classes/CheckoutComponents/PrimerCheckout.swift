//
//  PrimerCheckout.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// The main entry point for CheckoutComponents, providing a SwiftUI view for payment checkout.
/// This API matches the Android Composable API exactly for cross-platform consistency.
///
/// Example usage:
/// ```swift
/// PrimerCheckout(
///     clientToken: "your_client_token",
///     settings: PrimerSettings()
/// )
/// ```
///
/// With scope customization:
/// ```swift
/// PrimerCheckout(
///     clientToken: "your_client_token",
///     settings: PrimerSettings(),
///     scope: { checkoutScope in
///         // Customize components
///         checkoutScope.cardForm.cardNumberInput = { _ in
///             CustomCardNumberField()
///         }
///     }
/// )
/// ```
@MainActor
public struct PrimerCheckout: View {
    
    /// The client token for initializing the checkout session.
    private let clientToken: String
    
    /// Configuration settings for the checkout experience.
    private let settings: PrimerSettings
    
    /// Optional scope configuration closure for customizing UI components.
    private let scope: ((PrimerCheckoutScope) -> Void)?
    
    /// Creates a new PrimerCheckout view.
    /// - Parameters:
    ///   - clientToken: The client token obtained from your backend.
    ///   - settings: Configuration settings including theme and payment options.
    ///   - scope: Optional closure to customize UI components through the scope interface.
    public init(
        clientToken: String,
        settings: PrimerSettings = PrimerSettings(),
        scope: ((PrimerCheckoutScope) -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.scope = scope
    }
    
    public var body: some View {
        // The internal implementation will be created in Phase 5
        // For now, return a placeholder that will be replaced
        InternalCheckout(
            clientToken: clientToken,
            settings: settings,
            scope: scope
        )
    }
}

// MARK: - Internal Placeholder

/// Temporary placeholder for the internal checkout implementation.
/// This will be replaced with the actual implementation in Phase 5.
@MainActor
internal struct InternalCheckout: View {
    let clientToken: String
    let settings: PrimerSettings
    let scope: ((PrimerCheckoutScope) -> Void)?
    
    var body: some View {
        // Placeholder - will be implemented in Phase 5
        Text("CheckoutComponents - Implementation in progress")
            .padding()
    }
}