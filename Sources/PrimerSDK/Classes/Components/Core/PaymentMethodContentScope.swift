//
//  PaymentMethodContentScope.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// Scope that handles behavior and UI for an individual payment method.
protocol PaymentMethodContentScope: AnyObject, ObservableObject {
    /// The payment method for which this scope applies.
    var method: PaymentMethod { get }
    /// Indicates if a submission is in progress.
    var isLoading: Bool { get }
    /// Current validation state of the payment method input.
    var validationState: PaymentValidationState { get }
    /// Retrieve the current state asynchronously (snapshot of isLoading and validation).
    func getState() async -> PaymentMethodState
    /// Asynchronously submit the payment.
    func submit() async -> Result<PaymentResult, Error>
    /// Provides default SwiftUI UI for this payment method.
    @ViewBuilder func defaultContent() -> AnyView
}
