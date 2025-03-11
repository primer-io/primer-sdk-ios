//
//  PaymentFlowViewModel.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// A view model that bridges the PaymentFlow actor with SwiftUI state.
@available(iOS 14.0, *)
@MainActor
class PaymentFlowViewModel: ObservableObject {
    /// The underlying PaymentFlow actor.
    let paymentFlow = PaymentFlow()

    @Published var paymentMethods: [PaymentMethod] = []
    @Published var selectedMethod: PaymentMethod?

    /// Load payment methods from the PaymentFlow actor.
    func loadPaymentMethods() async {
        for await methods in await paymentFlow.getPaymentMethods() {
            self.paymentMethods = methods
        }
    }

    func loadSelectedMethod() async {
        for await method in await paymentFlow.getSelectedMethod() {
            self.selectedMethod = method
        }
    }

    /// Select a payment method.
    func selectMethod(_ method: PaymentMethod) async {
        await paymentFlow.selectPaymentMethod(method)
        self.selectedMethod = method
    }
}
