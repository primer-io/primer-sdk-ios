//
//  SubmitButtonWrapper.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// Wrapper component that provides a submit button connected to the CardFormScope
@available(iOS 15.0, *)
public struct SubmitButtonWrapper: View {
    
    // MARK: - Properties
    
    private let scope: any CardFormScope
    private let text: String
    
    // MARK: - State
    
    @State private var isLoading: Bool = false
    @State private var isEnabled: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.designTokens) private var tokens
    
    // MARK: - Initialization
    
    public init(
        scope: any CardFormScope,
        text: String = "Submit"
    ) {
        self.scope = scope
        self.text = text
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: {
            scope.submit()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(text)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(.white)
            .background(
                (isEnabled && !isLoading) 
                    ? (tokens?.primerColorPrimary ?? .blue)
                    : (tokens?.primerColorGray300 ?? .gray)
            )
            .cornerRadius(8)
        }
        .disabled(!isEnabled || isLoading)
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
        // Update button state from scope
        isLoading = state.isLoading
        isEnabled = state.isSubmitEnabled
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct SubmitButtonWrapper_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Enabled state
            SubmitButtonWrapper(scope: MockCardFormScope(enabled: true))
            
            // Disabled state
            SubmitButtonWrapper(scope: MockCardFormScope(enabled: false))
            
            // Loading state
            SubmitButtonWrapper(scope: MockCardFormScope(enabled: true, loading: true))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Mock Scope for Preview

@available(iOS 15.0, *)
private class MockCardFormScope: CardFormScope, ObservableObject {
    @Published private var _state: CardFormState
    
    init(enabled: Bool = false, loading: Bool = false) {
        _state = CardFormState(
            inputFields: [:],
            fieldErrors: [],
            isLoading: loading,
            isSubmitEnabled: enabled
        )
    }
    
    var state: AnyPublisher<CardFormState, Never> {
        $_state.eraseToAnyPublisher()
    }
    
    func updateCardNumber(_ cardNumber: String) {}
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