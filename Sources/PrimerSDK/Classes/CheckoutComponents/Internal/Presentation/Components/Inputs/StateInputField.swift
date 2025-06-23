//
//  StateInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// A SwiftUI component for state/province input with validation
@available(iOS 15.0, *)
internal struct StateInputField: View, LogReporter {
    // MARK: - Public Properties
    
    /// The label text shown above the field
    let label: String
    
    /// Placeholder text for the input field
    let placeholder: String
    
    /// Callback when the state changes
    let onStateChange: ((String) -> Void)?
    
    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?
    
    // MARK: - Private Properties
    
    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?
    
    /// The state entered by the user
    @State private var state: String = ""
    
    /// The validation state
    @State private var isValid: Bool = false
    
    /// Error message if validation fails
    @State private var errorMessage: String?
    
    @Environment(\.designTokens) private var tokens
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            
            // State input field
            TextField(placeholder, text: $state)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.allCharacters)
                .padding()
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: state) { newValue in
                    onStateChange?(newValue)
                    validateState()
                }
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 2)
            }
        }
        .onAppear {
            setupValidationService()
        }
    }
    
    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for StateInputField")
            return
        }
        
        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
    
    private func validateState() {
        guard let validationService = validationService else { return }
        
        let result = validationService.validate(
            value: state,
            for: .state
        )
        
        isValid = result.isValid
        errorMessage = result.errors.first?.message
        onValidationChange?(result.isValid)
    }
}