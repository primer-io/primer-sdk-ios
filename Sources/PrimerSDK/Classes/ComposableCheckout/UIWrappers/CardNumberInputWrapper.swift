//
//  CardNumberInputWrapper.swift
//
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// Wrapper component that connects the existing CardNumberInputField with the new CardFormScope
@available(iOS 15.0, *)
public struct CardNumberInputWrapper: View {

    // MARK: - Properties

    private let scope: any CardFormScope
    private let label: String
    private let placeholder: String

    // MARK: - State

    @State private var cardNumber: String = ""
    @State private var validationErrors: [ComposableInputValidationError] = []
    @State private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        scope: any CardFormScope,
        label: String = "Card Number",
        placeholder: String = "1234 5678 9012 3456"
    ) {
        self.scope = scope
        self.label = label
        self.placeholder = placeholder
    }

    // MARK: - Body

    public var body: some View {
        CardNumberInputField(
            label: label,
            placeholder: placeholder,
            onCardNumberChange: { newValue in
                // Update the scope when card number changes
                scope.updateCardNumber(newValue)
            },
            onCardNetworkChange: { _ in
                // Could be used to update scope with network info if needed
                // For now, we just log it
            },
            onValidationChange: { _ in
                // Validation is handled by the scope itself
                // The existing component's validation is kept for immediate feedback
            }
        )
        .onAppear {
            setupStateBinding()
        }
    }

    // MARK: - Private Methods

    private func setupStateBinding() {
        // Subscribe to scope state changes
        scope.state
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // Update state from scope - no weak reference needed for structs
                // updateFromScopeState(state)
                // TODO: Implement proper state binding when CardFormScope.state is available
            }
            .store(in: &cancellables)
    }

    private func updateFromScopeState(_ state: CardFormState) {
        // Update local state from scope
        cardNumber = state.inputFields[.cardNumber] ?? ""
        validationErrors = state.fieldErrors.filter { $0.elementType == .cardNumber }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct CardNumberInputWrapper_Previews: PreviewProvider {
    static var previews: some View {
        // Mock scope for preview
        let mockScope = MockCardFormScope()

        CardNumberInputWrapper(scope: mockScope)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

// MARK: - Mock Scope for Preview

@available(iOS 15.0, *)
private class MockCardFormScope: CardFormScope, ObservableObject {
    @Published private var _state = CardFormState.initial

    var state: AnyPublisher<CardFormState, Never> {
        $_state.eraseToAnyPublisher()
    }

    func updateCardNumber(_ cardNumber: String) {
        var fields = _state.inputFields
        fields[.cardNumber] = cardNumber

        _state = CardFormState(
            inputFields: fields,
            fieldErrors: _state.fieldErrors,
            isLoading: _state.isLoading,
            isSubmitEnabled: !cardNumber.isEmpty
        )
    }

    func updateCvv(_ cvv: String) {}
    func updateExpiryDate(_ expiryDate: String) {}
    func updateCardholderName(_ cardholderName: String) {}
    func updatePostalCode(_ postalCode: String) {}
    func updateCountryCode(_ countryCode: String) {}
    func updateCity(_ city: String) {}
    func updateState(_ state: String) {}
    func updateAddressLine1(_ addressLine1: String) {}
    func updateAddressLine2(_ addressLine2: String) {}
    func updatePhoneNumber(_ phoneNumber: String) {}
    func updateFirstName(_ firstName: String) {}
    func updateLastName(_ lastName: String) {}
    func updateRetailOutlet(_ retailOutlet: String) {}
    func updateOtpCode(_ otpCode: String) {}
    func submit() {}
}
