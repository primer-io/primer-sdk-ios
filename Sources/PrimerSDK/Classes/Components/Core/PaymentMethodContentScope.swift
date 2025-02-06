//
//  PaymentMethodContentScope.swift
//
//
//  Created by Boris on 6.2.25..
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Scope that handles behavior and UI for an individual payment method.
protocol PaymentMethodContentScope {
    /// The payment method for which this scope applies.
    var method: PaymentMethod { get }

    /// Retrieve the current state asynchronously.
    func getState() async -> PaymentMethodState

    /// Asynchronously submit the payment.
    func submit() async -> Result<PaymentResult, Error>

    #if canImport(SwiftUI)
    /// Provides default SwiftUI UI for this payment method.
    @ViewBuilder
    func defaultContent() -> AnyView
    #endif
}
