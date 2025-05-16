//
//  PaymentMethodProtocol.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// Represents a payment method available in the Primer checkout flow.
///
/// Each payment method has its own UI representation along with state management, encapsulated by its associated
/// PrimerPaymentMethodScope. This protocol provides both a customizable UI interface and a default implementation.
public protocol PaymentMethodProtocol: Identifiable {
    associatedtype ScopeType: PrimerPaymentMethodScope

    /// The display name for the payment method.
    var name: String? { get }

    /// The type of payment method.
    var type: PaymentMethodType { get }

    /// Provides access to this payment method's state and behavior.
    @MainActor
    var scope: ScopeType { get }

    /// Defines a custom UI for this payment method using SwiftUI.
    ///
    /// - Parameter content: A ViewBuilder closure that uses the payment method's scope as a parameter,
    ///                      allowing full access to the payment method's state and behavior.
    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (ScopeType) -> V) -> AnyView

    /// Provides the default UI implementation for this payment method.
    @MainActor
    func defaultContent() -> AnyView
}

/// Defines the types of payment methods supported by the SDK
public enum PaymentMethodType: String {
    case paymentCard = "PAYMENT_CARD"
    case klarna = "KLARNA"
    case paypal = "PAYPAL"
    case applePay = "APPLE_PAY"

    // Add other payment methods as needed
}
