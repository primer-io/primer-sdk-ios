//
//  PaymentMethodContentView.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

// PaymentMethodContentView.swift

/// A helper view that instantiates the appropriate PaymentMethodContentScope and passes it to the provided content builder.
struct PaymentMethodContentView<Content: View>: View {
    let method: PaymentMethod
    let content: (any PaymentMethodContentScope) -> Content

    var body: some View {
        // Decide which scope to use based on the payment method type.
        let scope: any PaymentMethodContentScope
        switch method.methodType {
        case .card:
            scope = DefaultPaymentMethodContentScope(method: method)
        case .paypal:
            scope = PayPalPaymentContentScope(method: method)
        case .applePay:
            scope = ApplePayPaymentContentScope(method: method)
        }
        return content(scope)
    }
}
