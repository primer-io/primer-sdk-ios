//
//  CardPaymentMethod.swift
//
//
//  Created by Boris on 24.3.25..
//

import SwiftUI

/**
 * Implementation of a payment method that handles card payments.
 *
 * This class extends the base PaymentMethodProtocol with a CardPaymentMethodScope, providing functionality specific
 * to card payment processing.
 */
@available(iOS 15.0, *)
class CardPaymentMethod: PaymentMethodProtocol {
    typealias ScopeType = CardViewModel

    var id: String = UUID().uuidString
    var name: String? = "Card"
    var type: PaymentMethodType = .paymentCard

    @MainActor
    var scope: CardViewModel {
        CardViewModel()
    }

    /**
     * Displays custom content within the card payment method's scope, replacing the
     * default implementation.
     *
     * This method allows merchants to build a customized card payment experience while leveraging Primer's
     * validated and secure field implementations. Merchants can:
     *
     * - Use components from CardPaymentMethodScope like `PrimerCardNumberField`, `PrimerCvvField`, etc.
     * - Arrange Primer fields in any custom order or layout
     * - Interlace Primer fields with their own custom UI elements (e.g., discount fields)
     * - Add completely custom composables built with `PrimerInputField` or any other custom components
     * - Control form submission either with `PrimerPayButton` or any custom button that calls
     * `CardPaymentMethodScope.submit()`
     */
    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (CardViewModel) -> V) -> AnyView {
        let viewModel = scope
        return AnyView(content(viewModel))
    }

    /**
     * Provides the default experience for card based payments.
     */
    @MainActor
    func defaultContent() -> AnyView {
        return AnyView(CardPaymentView(scope: scope))
    }
}
