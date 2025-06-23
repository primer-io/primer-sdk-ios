//
//  CardholderNameInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for cardholder name input with validation
/// and consistent styling with other card input fields.
@available(iOS 15.0, *)
internal struct CardholderNameInputField: View, LogReporter {
    // MARK: - Public Properties
    
    /// The label text shown above the field
    let label: String
    
    /// Placeholder text for the input field
    let placeholder: String
    
    /// Callback when the cardholder name changes
    let onCardholderNameChange: ((String) -> Void)?
    
    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?
    
    // MARK: - Private Properties
    
    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?
    
    /// The cardholder name entered by the user
    @State private var cardholderName: String = ""
    
    /// The validation state of the cardholder name
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
            
            // Cardholder name input field
            if let validationService = validationService {
                CardholderNameTextField(
                    cardholderName: $cardholderName,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    placeholder: placeholder,
                    validationService: validationService,
                    onCardholderNameChange: onCardholderNameChange,
                    onValidationChange: onValidationChange
                )
                .padding()
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $cardholderName)
                    .keyboardType(.default)
                    .autocapitalization(.words)
                    .disabled(true)
                    .padding()
                    .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                    .cornerRadius(8)
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
            logger.error(message: "DIContainer not available for CardholderNameInputField")
            return
        }
        
        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for cardholder name input
@available(iOS 15.0, *)
private struct CardholderNameTextField: UIViewRepresentable, LogReporter {
    @Binding var cardholderName: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    let placeholder: String
    let validationService: ValidationService
    let onCardholderNameChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        
        // Add a "Done" button to the keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
        
        return textField
    }
    
    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != cardholderName {
            textField.text = cardholderName
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            cardholderName: $cardholderName,
            isValid: $isValid,
            errorMessage: $errorMessage,
            onCardholderNameChange: onCardholderNameChange,
            onValidationChange: onValidationChange
        )
    }
    
    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var cardholderName: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        private let onCardholderNameChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?
        
        init(
            validationService: ValidationService,
            cardholderName: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            onCardholderNameChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._cardholderName = cardholderName
            self._isValid = isValid
            self._errorMessage = errorMessage
            self.onCardholderNameChange = onCardholderNameChange
            self.onValidationChange = onValidationChange
        }
        
        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            errorMessage = nil
            isValid = false
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            validateCardholderName()
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = cardholderName
            
            // Create new text
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)
            
            // Validate allowed characters (letters, spaces, apostrophes, hyphens)
            if !string.isEmpty {
                let allowedCharacterSet = CharacterSet.letters.union(CharacterSet(charactersIn: " '-"))
                let characterSet = CharacterSet(charactersIn: string)
                if !allowedCharacterSet.isSuperset(of: characterSet) {
                    return false
                }
            }
            
            // Update state
            cardholderName = newText
            onCardholderNameChange?(newText)
            
            // Simple validation while typing
            isValid = newText.count >= 2
            
            return false
        }
        
        private func validateCardholderName() {
            let result = validationService.validate(
                value: cardholderName,
                for: .cardholderName
            )
            
            isValid = result.isValid
            errorMessage = result.errors.first?.message
            onValidationChange?(result.isValid)
        }
    }
}