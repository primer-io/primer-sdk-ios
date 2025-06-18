//
//  CardholderNameInputWrapper.swift
//
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// Wrapper component that connects the existing CardholderNameInputField with the new CardFormScope
@available(iOS 15.0, *)
public struct CardholderNameInputWrapper: View {

    // MARK: - Properties

    private let scope: any CardFormScope
    private let modifier: PrimerModifier
    private let label: String?
    private let placeholder: String?

    // MARK: - State

    @State private var cardholderName: String = ""
    @State private var validationErrors: [ComposableInputValidationError] = []
    @State private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        scope: any CardFormScope,
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = "Cardholder Name",
        placeholder: String? = "John Doe"
    ) {
        self.scope = scope
        self.modifier = modifier
        self.label = label
        self.placeholder = placeholder
    }

    // MARK: - Body

    public var body: some View {
        CardholderNameInputField(
            label: label ?? "Cardholder Name",
            placeholder: placeholder ?? "John Doe",
            onCardholderNameChange: { newValue in
                // Update the scope when cardholder name changes
                scope.updateCardholderName(newValue)
            },
            onValidationChange: { _ in
                // Validation is handled by the scope itself
                // The existing component's validation is kept for immediate feedback
            }
        )
        .primerModifier(modifier)
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
                // Note: No weak reference needed for structs
                // updateFromScopeState(state)
            }
            .store(in: &cancellables)
    }

    private func updateFromScopeState(_ state: CardFormState) {
        // Update local state from scope
        cardholderName = state.inputFields[.cardholderName] ?? ""
        validationErrors = state.fieldErrors.filter { $0.elementType == .cardholderName }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct CardholderNameInputWrapper_Previews: PreviewProvider {
    static var previews: some View {
        // Mock scope for preview
        let mockScope = MockCardFormScope()

        CardholderNameInputWrapper(scope: mockScope)
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

    func updateCardNumber(_ cardNumber: String) {}
    func updateCvv(_ cvv: String) {}
    func updateExpiryDate(_ expiryDate: String) {}

    func updateCardholderName(_ cardholderName: String) {
        var fields = _state.inputFields
        fields[.cardholderName] = cardholderName

        _state = CardFormState(
            inputFields: fields,
            fieldErrors: _state.fieldErrors,
            isLoading: _state.isLoading,
            isSubmitEnabled: !cardholderName.isEmpty
        )
    }

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
