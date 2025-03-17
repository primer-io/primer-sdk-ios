//
//  CardPaymentUiState.swift
//
//
//  Created by Boris on 17.3.25..
//

import SwiftUI

/// Card payment UI state
struct CardPaymentUiState: PrimerPaymentMethodUiState {
    let cardNumber: String
    let expiryMonth: String
    let expiryYear: String
    let cvv: String
    let cardholderName: String
    let isValid: Bool

    static let empty = CardPaymentUiState(
        cardNumber: "",
        expiryMonth: "",
        expiryYear: "",
        cvv: "",
        cardholderName: "",
        isValid: false
    )
}

/// Scope for card payments
@MainActor
protocol CardPaymentMethodScope: PrimerPaymentMethodScope where T == CardPaymentUiState {
    func updateCardNumber(_ value: String)
    func updateExpiryMonth(_ value: String)
    func updateExpiryYear(_ value: String)
    func updateCvv(_ value: String)
    func updateCardholderName(_ value: String)
}

/// Card payment method view model
@MainActor
class CardPaymentViewModel: ObservableObject, CardPaymentMethodScope {
    typealias T = CardPaymentUiState

    private var stateContinuations: [AsyncStream<CardPaymentUiState?>.Continuation] = []
    private var currentState: CardPaymentUiState = .empty

    func state() -> AsyncStream<CardPaymentUiState?> {
        AsyncStream { continuation in
            self.stateContinuations.append(continuation)
            continuation.yield(currentState)
        }
    }

    func updateCardNumber(_ value: String) {
        updateState(with: CardPaymentUiState(
            cardNumber: value,
            expiryMonth: currentState.expiryMonth,
            expiryYear: currentState.expiryYear,
            cvv: currentState.cvv,
            cardholderName: currentState.cardholderName,
            isValid: validateCard(
                number: value,
                expiryMonth: currentState.expiryMonth,
                expiryYear: currentState.expiryYear,
                cvv: currentState.cvv,
                name: currentState.cardholderName
            )
        ))
    }

    func updateExpiryMonth(_ value: String) {
        updateState(with: CardPaymentUiState(
            cardNumber: currentState.cardNumber,
            expiryMonth: value,
            expiryYear: currentState.expiryYear,
            cvv: currentState.cvv,
            cardholderName: currentState.cardholderName,
            isValid: validateCard(
                number: currentState.cardNumber,
                expiryMonth: value,
                expiryYear: currentState.expiryYear,
                cvv: currentState.cvv,
                name: currentState.cardholderName
            )
        ))
    }

    func updateExpiryYear(_ value: String) {
        updateState(with: CardPaymentUiState(
            cardNumber: currentState.cardNumber,
            expiryMonth: currentState.expiryMonth,
            expiryYear: value,
            cvv: currentState.cvv,
            cardholderName: currentState.cardholderName,
            isValid: validateCard(
                number: currentState.cardNumber,
                expiryMonth: currentState.expiryMonth,
                expiryYear: value,
                cvv: currentState.cvv,
                name: currentState.cardholderName
            )
        ))
    }

    func updateCvv(_ value: String) {
        updateState(with: CardPaymentUiState(
            cardNumber: currentState.cardNumber,
            expiryMonth: currentState.expiryMonth,
            expiryYear: currentState.expiryYear,
            cvv: value,
            cardholderName: currentState.cardholderName,
            isValid: validateCard(
                number: currentState.cardNumber,
                expiryMonth: currentState.expiryMonth,
                expiryYear: currentState.expiryYear,
                cvv: value,
                name: currentState.cardholderName
            )
        ))
    }

    func updateCardholderName(_ value: String) {
        updateState(with: CardPaymentUiState(
            cardNumber: currentState.cardNumber,
            expiryMonth: currentState.expiryMonth,
            expiryYear: currentState.expiryYear,
            cvv: currentState.cvv,
            cardholderName: value,
            isValid: validateCard(
                number: currentState.cardNumber,
                expiryMonth: currentState.expiryMonth,
                expiryYear: currentState.expiryYear,
                cvv: currentState.cvv,
                name: value
            )
        ))
    }

    func submit() async throws -> PaymentResult {
        guard currentState.isValid else {
            throw ComponentsPrimerError.invalidCardDetails
        }

        // Simulate payment processing
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)

        return PaymentResult(
            transactionId: UUID().uuidString,
            amount: Decimal(100),
            currency: "USD"
        )
    }

    func cancel() async {
        updateState(with: .empty)
    }

    private func updateState(with newState: CardPaymentUiState) {
        currentState = newState
        for continuation in stateContinuations {
            continuation.yield(newState)
        }
    }

    private func validateCard(number: String,
                              expiryMonth: String,
                              expiryYear: String,
                              cvv: String,
                              name: String) -> Bool {
        // Basic validation logic
        guard !number.isEmpty, !expiryMonth.isEmpty, !expiryYear.isEmpty, !cvv.isEmpty, !name.isEmpty
        else {
            return false
        }

        // More sophisticated validation would be implemented here
        return true
    }
}

/// Card payment method implementation
class CardPaymentMethod: PaymentMethodProtocol, Identifiable {
    // Explicitly define the associated type to be the concrete type
    typealias ScopeType = CardPaymentViewModel

    var id: String = UUID().uuidString
    var name: String? = "Card"
    var type: PaymentMethodType = .paymentCard

    @MainActor
    var scope: CardPaymentViewModel {
        CardPaymentViewModel()
    }

    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (CardPaymentViewModel) -> V) -> AnyView {
        AnyView(content(scope))
    }

    @MainActor
    func defaultContent() -> AnyView {
        if #available(iOS 14.0, *) {
            return AnyView(CardPaymentView(scope: scope))
        } else {
            // Fallback for earlier iOS versions
            return AnyView(Text("Card payment not available on this iOS version"))
        }
    }
}
