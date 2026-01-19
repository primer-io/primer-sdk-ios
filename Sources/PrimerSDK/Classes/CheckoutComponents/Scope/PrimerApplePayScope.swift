//
//  PrimerApplePayScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import PassKit

/// Protocol defining the Apple Pay scope interface for CheckoutComponents.
/// Provides access to Apple Pay state, button customization, and payment flow control.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerApplePayScope: PrimerPaymentMethodScope where State == ApplePayFormState {

    // MARK: - State

    /// The current state of the Apple Pay scope as an async stream.
    var state: AsyncStream<ApplePayFormState> { get }

    // MARK: - Availability

    /// Whether Apple Pay is available on this device
    var isAvailable: Bool { get }

    /// Error message if Apple Pay is not available
    var availabilityError: String? { get }

    // MARK: - Button Customization

    /// The style of the Apple Pay button
    var buttonStyle: PKPaymentButtonStyle { get set }

    /// The type of the Apple Pay button
    var buttonType: PKPaymentButtonType { get set }

    /// The corner radius of the Apple Pay button
    var cornerRadius: CGFloat { get set }

    // MARK: - UI Customization

    /// Custom Apple Pay screen override
    var screen: ((_ scope: any PrimerApplePayScope) -> any View)? { get set }

    /// Custom Apple Pay button override
    var applePayButton: ((_ action: @escaping () -> Void) -> any View)? { get set }

    // MARK: - Actions

    /// Initiates the Apple Pay payment flow.
    /// This presents the Apple Pay sheet and handles the authorization.
    func pay()

    // MARK: - ViewBuilder Components
    // swiftlint:disable identifier_name
    /// Returns the default Apple Pay button view
    /// - Parameter action: The action to perform when the button is tapped
    /// - Returns: A SwiftUI view containing the Apple Pay button
    func PrimerApplePayButton(action: @escaping () -> Void) -> AnyView
    // swiftlint:enable identifier_name
}

// MARK: - Default Implementations

@available(iOS 15.0, *)
extension PrimerApplePayScope {

    /// Default implementation triggers payment on submit
    public func submit() {
        pay()
    }
}
