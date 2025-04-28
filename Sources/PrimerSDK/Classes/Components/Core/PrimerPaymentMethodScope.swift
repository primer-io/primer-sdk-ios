//
//  PaymentMethodContentScope.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// Scope interface for interacting with a specific payment method's UI state and behavior.
///
/// - Parameter T: The specific implementation of PrimerPaymentMethodUiState that represents
///                the UI state for this payment method.
@MainActor
public protocol PrimerPaymentMethodScope<T> {
    associatedtype T: PrimerPaymentMethodUiState

    /// AsyncStream containing the current UI state for this payment method.
    ///
    /// This provides observable access to the payment method's state, allowing UI components to react to state
    /// changes. The state is of type T, which is the payment method-specific implementation of
    /// PrimerPaymentMethodUiState that contains all the relevant state information for this payment method.
    func state() -> AsyncStream<T?>

    /// Submits the payment information for processing.
    /// To be called when the user has completed entering payment details.
    func submit() async throws -> PaymentResult

    /// Cancels the current payment method flow.
    /// To be called when the user wants to abort the payment process.
    func cancel() async
}

/// Base protocol for payment method UI state implementations implemented by all payment methods with their specific
/// state information.
public protocol PrimerPaymentMethodUiState {}
