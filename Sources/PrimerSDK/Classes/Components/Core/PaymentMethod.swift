//
//  PaymentMethod.swift
//
//
//  Created by Boris on 6.2.25..
//

/// Protocol representing a payment method.
protocol PaymentMethod {
    var id: String { get }
    var name: String { get }
    var methodType: PaymentMethodType { get }
    // TODO: Add additional properties (e.g., icon, configuration) if needed.
}

/// Enumeration for different payment method types.
enum PaymentMethodType {
    case card
    case paypal
    case applePay
    // TODO: Add more types as needed.
}

/// Represents the validation state of a payment method.
struct PaymentValidationState {
    let isValid: Bool
    // TODO: Add more validation info if needed (e.g., error messages).
}

/// Represents the overall state for a payment method.
struct PaymentMethodState {
    let isLoading: Bool
    let validationState: PaymentValidationState
    // TODO: Extend with additional state properties as needed.
}
