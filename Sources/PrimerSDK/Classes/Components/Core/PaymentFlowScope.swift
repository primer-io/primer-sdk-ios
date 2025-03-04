//
//  PaymentFlowScope.swift
//
//
//  Created by Boris on 6.2.25..
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// The main integration interface (similar to PaymentFlowScope on Android).
protocol PaymentFlowScope {
    /// Retrieves the list of available payment methods as an `AsyncStream`.
    func getPaymentMethods() async -> AsyncStream<[PaymentMethod]>

    /// Retrieves the currently selected payment method as an `AsyncStream`.
    func getSelectedMethod() async -> AsyncStream<PaymentMethod?>

    /// Asynchronously select a payment method.
    func selectPaymentMethod(_ method: PaymentMethod?) async

    #if canImport(SwiftUI)
    /// SwiftUI helper to render payment method content.
    @ViewBuilder
    func paymentMethodContent<Content: View>(
        for method: PaymentMethod,
        @ViewBuilder content: @escaping (any PaymentMethodContentScope) -> Content
    ) -> AnyView
    #endif
}
