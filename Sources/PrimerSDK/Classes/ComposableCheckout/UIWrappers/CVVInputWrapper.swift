//
//  CVVInputWrapper.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// Wrapper component that connects the existing CVVInputField with the new CardFormScope
@available(iOS 15.0, *)
public struct CVVInputWrapper: View {
    
    // MARK: - Properties
    
    private let scope: any CardFormScope
    private let label: String
    private let placeholder: String
    
    // MARK: - State
    
    @State private var cvv: String = ""
    @State private var cardNetwork: CardNetwork = .unknown
    @State private var validationErrors: [PrimerInputValidationError] = []
    @State private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(
        scope: any CardFormScope,
        label: String = "CVV",
        placeholder: String = "123"
    ) {
        self.scope = scope
        self.label = label
        self.placeholder = placeholder
    }
    
    // MARK: - Body
    
    public var body: some View {
        CVVInputField(
            label: label,
            placeholder: placeholder,
            cardNetwork: cardNetwork,
            onCvvChange: { newValue in
                // Update the scope when CVV changes
                scope.updateCvv(newValue)
            },
            onValidationChange: { isValid in
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
            .sink { [weak self = self] state in
                self?.updateFromScopeState(state)
            }
            .store(in: &cancellables)
    }
    
    private func updateFromScopeState(_ state: CardFormState) {
        // Update local state from scope
        cvv = state.inputFields[.cvv] ?? ""
        validationErrors = state.fieldErrors.filter { $0.elementType == .cvv }
        
        // Determine card network from card number for proper CVV validation
        let cardNumber = state.inputFields[.cardNumber] ?? ""
        if !cardNumber.isEmpty {
            cardNetwork = CardNetwork(cardNumber: cardNumber)
        } else {
            cardNetwork = .unknown
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct CVVInputWrapper_Previews: PreviewProvider {
    static var previews: some View {
        // Mock scope for preview
        let mockScope = MockCardFormScope()
        
        CVVInputWrapper(scope: mockScope)
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
    
    func updateCvv(_ cvv: String) {
        var fields = _state.inputFields
        fields[.cvv] = cvv
        
        _state = CardFormState(
            inputFields: fields,
            fieldErrors: _state.fieldErrors,
            isLoading: _state.isLoading,
            isSubmitEnabled: !cvv.isEmpty
        )
    }
    
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