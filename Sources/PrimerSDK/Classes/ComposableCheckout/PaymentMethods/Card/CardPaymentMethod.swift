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
    private let _scope: CardViewModel

    @MainActor
    init(validationService: ValidationService) async {
        // Create validators with callback placeholders (will be set up in CardViewModel)
        let formValidator = CardFormValidator(validationService: validationService)
        let cardNumberValidator = CardNumberValidator(
            validationService: validationService,
            onValidationChange: { _ in },
            onErrorMessageChange: { _ in }
        )
        let cvvValidator = CVVValidator(
            validationService: validationService,
            cardNetwork: .unknown,
            onValidationChange: { _ in },
            onErrorMessageChange: { _ in }
        )
        let expiryDateValidator = ExpiryDateValidator(
            validationService: validationService,
            onValidationChange: { _ in },
            onErrorMessageChange: { _ in },
            onMonthChange: { _ in },
            onYearChange: { _ in }
        )
        let cardholderNameValidator = CardholderNameValidator(
            validationService: validationService,
            onValidationChange: { _ in },
            onErrorMessageChange: { _ in }
        )
        
        self._scope = CardViewModel(
            validationService: validationService,
            formValidator: formValidator,
            cardNumberValidator: cardNumberValidator,
            cvvValidator: cvvValidator,
            expiryDateValidator: expiryDateValidator,
            cardholderNameValidator: cardholderNameValidator
        )
    }

    @MainActor
    var scope: CardViewModel {
        _scope
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
        return AnyView(content(_scope))
    }

    /**
     * Provides the default experience for card based payments.
     */
    @MainActor
    func defaultContent() -> AnyView {
        return AnyView(CardPaymentView(scope: _scope))
    }
}
