//
//  PaymentMethodContentView.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// A helper view that instantiates the appropriate PaymentMethodContentScope
/// and passes it to the provided content builder.
@available(iOS 14.0, *)
struct PaymentMethodContentView<Content: View>: View {
    @StateObject private var scopeHolder: ScopeHolder
    private let contentBuilder: (any PaymentMethodContentScope) -> Content

    nonisolated init(method: PaymentMethod,
                     @ViewBuilder content: @escaping (any PaymentMethodContentScope) -> Content) {
        // Choose the appropriate scope implementation based on the payment method type.
        let chosenScope: any PaymentMethodContentScope
        switch method.methodType {
        case .card:
            chosenScope = CardPaymentContentScope(method: method)
        case .paypal:
            chosenScope = PayPalPaymentContentScope(method: method)
        case .applePay:
            chosenScope = ApplePayPaymentContentScope(method: method)
        }
        // Initialize the scope holder (no Combine subscription is needed)
        _scopeHolder = StateObject(wrappedValue: ScopeHolder(scope: chosenScope))
        self.contentBuilder = content
    }

    var body: some View {
        contentBuilder(scopeHolder.scope)
    }
}

/// A simple holder class for the PaymentMethodContentScope.
private class ScopeHolder: ObservableObject {
    let scope: any PaymentMethodContentScope

    init(scope: any PaymentMethodContentScope) {
        self.scope = scope
    }
}
