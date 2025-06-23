//
//  CardNumberInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for credit card number input with automatic formatting,
/// validation, and card network detection.
@available(iOS 15.0, *)
internal struct CardNumberInputField: View, LogReporter {
    // MARK: - Public Properties
    
    /// The label text shown above the field
    let label: String
    
    /// Placeholder text for the input field
    let placeholder: String
    
    /// Callback when the card number changes
    let onCardNumberChange: ((String) -> Void)?
    
    /// Callback when the card network changes
    let onCardNetworkChange: ((CardNetwork) -> Void)?
    
    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?
    
    // MARK: - Private Properties
    
    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?
    
    /// The card number entered by the user (without formatting)
    @State private var cardNumber: String = ""
    
    /// The validation state of the card number
    @State private var isValid: Bool?
    
    /// The detected card network based on the card number
    @State private var cardNetwork: CardNetwork = .unknown
    
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
            
            // Card input field with network icon
            HStack(spacing: 8) {
                if let validationService = validationService {
                    CardNumberTextField(
                        cardNumber: $cardNumber,
                        isValid: $isValid,
                        cardNetwork: $cardNetwork,
                        errorMessage: $errorMessage,
                        placeholder: placeholder,
                        validationService: validationService,
                        onCardNumberChange: onCardNumberChange,
                        onCardNetworkChange: onCardNetworkChange,
                        onValidationChange: onValidationChange
                    )
                    .padding()
                    .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                    .cornerRadius(8)
                } else {
                    // Fallback view while loading validation service
                    TextField(placeholder, text: .constant(""))
                        .disabled(true)
                        .padding()
                        .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Card network icon if detected
                if cardNetwork != .unknown {
                    if let icon = cardNetwork.icon {
                        Image(uiImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 24)
                    }
                }
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
            logger.error(message: "DIContainer not available for CardNumberInputField")
            return
        }
        
        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for card number text field
@available(iOS 15.0, *)
private struct CardNumberTextField: UIViewRepresentable, LogReporter {
    @Binding var cardNumber: String
    @Binding var isValid: Bool?
    @Binding var cardNetwork: CardNetwork
    @Binding var errorMessage: String?
    let placeholder: String
    let validationService: ValidationService
    let onCardNumberChange: ((String) -> Void)?
    let onCardNetworkChange: ((CardNetwork) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        
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
        // Update text field if needed
        if textField.text != formatCardNumber(cardNumber, for: cardNetwork) {
            textField.text = formatCardNumber(cardNumber, for: cardNetwork)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            cardNumber: $cardNumber,
            cardNetwork: $cardNetwork,
            isValid: $isValid,
            errorMessage: $errorMessage,
            onCardNumberChange: onCardNumberChange,
            onCardNetworkChange: onCardNetworkChange,
            onValidationChange: onValidationChange
        )
    }
    
    private func formatCardNumber(_ number: String, for network: CardNetwork) -> String {
        let gaps = network.validation?.gaps ?? [4, 8, 12]
        var formatted = ""
        
        for (index, char) in number.enumerated() {
            formatted.append(char)
            if gaps.contains(index + 1) && index + 1 < number.count {
                formatted.append(" ")
            }
        }
        
        return formatted
    }
    
    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var cardNumber: String
        @Binding private var cardNetwork: CardNetwork
        @Binding private var isValid: Bool?
        @Binding private var errorMessage: String?
        private let onCardNumberChange: ((String) -> Void)?
        private let onCardNetworkChange: ((CardNetwork) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?
        
        init(
            validationService: ValidationService,
            cardNumber: Binding<String>,
            cardNetwork: Binding<CardNetwork>,
            isValid: Binding<Bool?>,
            errorMessage: Binding<String?>,
            onCardNumberChange: ((String) -> Void)?,
            onCardNetworkChange: ((CardNetwork) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._cardNumber = cardNumber
            self._cardNetwork = cardNetwork
            self._isValid = isValid
            self._errorMessage = errorMessage
            self.onCardNumberChange = onCardNumberChange
            self.onCardNetworkChange = onCardNetworkChange
            self.onValidationChange = onValidationChange
        }
        
        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            errorMessage = nil
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            validateCardNumber()
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text without formatting
            let currentText = cardNumber
            
            // Handle deletion
            if string.isEmpty {
                if range.length > 0 {
                    // Delete range
                    if let textRange = Range(range, in: currentText) {
                        cardNumber = currentText.replacingCharacters(in: textRange, with: "")
                    }
                } else if range.location > 0 {
                    // Backspace
                    let index = currentText.index(currentText.startIndex, offsetBy: range.location - 1)
                    cardNumber = currentText.removing(at: index)
                }
            } else {
                // Only allow numeric input
                let filtered = string.filter { $0.isNumber }
                if filtered.isEmpty { return false }
                
                // Insert at position
                if range.location <= currentText.count {
                    let index = currentText.index(currentText.startIndex, offsetBy: range.location)
                    cardNumber = currentText.inserting(contentsOf: filtered, at: index)
                } else {
                    cardNumber = currentText + filtered
                }
            }
            
            // Limit to 19 digits
            if cardNumber.count > 19 {
                cardNumber = String(cardNumber.prefix(19))
            }
            
            // Update card network
            let newNetwork = CardNetwork(cardNumber: cardNumber)
            if newNetwork != cardNetwork {
                cardNetwork = newNetwork
                onCardNetworkChange?(newNetwork)
            }
            
            // Update formatted text
            textField.text = formatCardNumber(cardNumber, for: cardNetwork)
            
            // Notify changes
            onCardNumberChange?(cardNumber)
            
            // Validate if we have enough digits
            if cardNumber.count >= 13 {
                validateCardNumber()
            }
            
            return false
        }
        
        private func formatCardNumber(_ number: String, for network: CardNetwork) -> String {
            let gaps = network.validation?.gaps ?? [4, 8, 12]
            var formatted = ""
            
            for (index, char) in number.enumerated() {
                formatted.append(char)
                if gaps.contains(index + 1) && index + 1 < number.count {
                    formatted.append(" ")
                }
            }
            
            return formatted
        }
        
        private func validateCardNumber() {
            let result = validationService.validate(
                value: cardNumber,
                for: .cardNumber
            )
            
            isValid = result.isValid
            errorMessage = result.errors.first?.message
            onValidationChange?(result.isValid)
        }
    }
}

// String extensions
private extension String {
    func removing(at index: Index) -> String {
        var result = self
        result.remove(at: index)
        return result
    }
    
    func inserting(contentsOf newElements: String, at index: Index) -> String {
        var result = self
        result.insert(contentsOf: newElements, at: index)
        return result
    }
}