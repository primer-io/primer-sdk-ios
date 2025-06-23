//
//  ExpiryDateInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for credit card expiry date input with automatic formatting
/// and validation to ensure dates are valid and not in the past.
@available(iOS 15.0, *)
internal struct ExpiryDateInputField: View, LogReporter {
    // MARK: - Public Properties
    
    /// The label text shown above the field
    let label: String
    
    /// Placeholder text for the input field
    let placeholder: String
    
    /// Callback when the expiry date changes
    let onExpiryDateChange: ((String) -> Void)?
    
    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?
    
    /// Callback when month value changes
    let onMonthChange: ((String) -> Void)?
    
    /// Callback when year value changes
    let onYearChange: ((String) -> Void)?
    
    // MARK: - Private Properties
    
    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?
    
    /// The expiry date entered by the user
    @State private var expiryDate: String = ""
    
    /// The extracted month value (MM)
    @State private var month: String = ""
    
    /// The extracted year value (YY)
    @State private var year: String = ""
    
    /// The validation state of the expiry date
    @State private var isValid: Bool?
    
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
            
            // Expiry date input field
            if let validationService = validationService {
                ExpiryDateTextField(
                    expiryDate: $expiryDate,
                    month: $month,
                    year: $year,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    placeholder: placeholder,
                    validationService: validationService,
                    onExpiryDateChange: onExpiryDateChange,
                    onMonthChange: onMonthChange,
                    onYearChange: onYearChange,
                    onValidationChange: onValidationChange
                )
                .padding()
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $expiryDate)
                    .keyboardType(.numberPad)
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
            logger.error(message: "DIContainer not available for ExpiryDateInputField")
            return
        }
        
        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for expiry date input
@available(iOS 15.0, *)
private struct ExpiryDateTextField: UIViewRepresentable, LogReporter {
    @Binding var expiryDate: String
    @Binding var month: String
    @Binding var year: String
    @Binding var isValid: Bool?
    @Binding var errorMessage: String?
    let placeholder: String
    let validationService: ValidationService
    let onExpiryDateChange: ((String) -> Void)?
    let onMonthChange: ((String) -> Void)?
    let onYearChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.textContentType = .none // Prevent autofill
        
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
        if textField.text != expiryDate {
            textField.text = expiryDate
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            expiryDate: $expiryDate,
            month: $month,
            year: $year,
            isValid: $isValid,
            errorMessage: $errorMessage,
            onExpiryDateChange: onExpiryDateChange,
            onMonthChange: onMonthChange,
            onYearChange: onYearChange,
            onValidationChange: onValidationChange
        )
    }
    
    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var expiryDate: String
        @Binding private var month: String
        @Binding private var year: String
        @Binding private var isValid: Bool?
        @Binding private var errorMessage: String?
        private let onExpiryDateChange: ((String) -> Void)?
        private let onMonthChange: ((String) -> Void)?
        private let onYearChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?
        
        init(
            validationService: ValidationService,
            expiryDate: Binding<String>,
            month: Binding<String>,
            year: Binding<String>,
            isValid: Binding<Bool?>,
            errorMessage: Binding<String?>,
            onExpiryDateChange: ((String) -> Void)?,
            onMonthChange: ((String) -> Void)?,
            onYearChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._expiryDate = expiryDate
            self._month = month
            self._year = year
            self._isValid = isValid
            self._errorMessage = errorMessage
            self.onExpiryDateChange = onExpiryDateChange
            self.onMonthChange = onMonthChange
            self.onYearChange = onYearChange
            self.onValidationChange = onValidationChange
        }
        
        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            errorMessage = nil
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            validateExpiryDate()
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = expiryDate
            
            // Handle return key
            if string == "\n" {
                textField.resignFirstResponder()
                return false
            }
            
            // Only allow numbers and return for non-numeric input except deletion
            if !string.isEmpty && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
                return false
            }
            
            // Process the input
            let newText = processInput(currentText: currentText, range: range, string: string)
            
            // Update the text field
            expiryDate = newText
            textField.text = newText
            
            // Extract month and year
            extractMonthAndYear(from: newText)
            
            // Notify changes
            onExpiryDateChange?(newText)
            
            // Validate if complete
            if newText.count == 5 { // MM/YY format
                validateExpiryDate()
            } else {
                isValid = nil
                errorMessage = nil
            }
            
            return false
        }
        
        private func processInput(currentText: String, range: NSRange, string: String) -> String {
            // Handle deletion
            if string.isEmpty {
                // If deleting the separator, also remove the character before it
                if range.location == 2 && range.length == 1 && currentText.count >= 3 &&
                    currentText[currentText.index(currentText.startIndex, offsetBy: 2)] == "/" {
                    return String(currentText.prefix(1))
                }
                
                // Normal deletion
                if let textRange = Range(range, in: currentText) {
                    return currentText.replacingCharacters(in: textRange, with: "")
                }
                return currentText
            }
            
            // Handle additions
            // Remove the / character temporarily for easier processing
            let sanitizedText = currentText.replacingOccurrences(of: "/", with: "")
            
            // Calculate where to insert the new text
            var sanitizedLocation = range.location
            if range.location > 2 && currentText.count >= 3 && currentText.contains("/") {
                sanitizedLocation -= 1
            }
            
            // Insert the new digits
            var newSanitizedText = sanitizedText
            if sanitizedLocation <= sanitizedText.count {
                let index = newSanitizedText.index(newSanitizedText.startIndex, offsetBy: min(sanitizedLocation, newSanitizedText.count))
                newSanitizedText.insert(contentsOf: string, at: index)
            } else {
                newSanitizedText += string
            }
            
            // Limit to 4 digits total (MMYY format)
            newSanitizedText = String(newSanitizedText.prefix(4))
            
            // Format with separator
            if newSanitizedText.count > 2 {
                return "\(newSanitizedText.prefix(2))/\(newSanitizedText.dropFirst(2))"
            } else {
                return newSanitizedText
            }
        }
        
        private func extractMonthAndYear(from text: String) {
            let parts = text.components(separatedBy: "/")
            
            month = parts.count > 0 ? parts[0] : ""
            year = parts.count > 1 ? parts[1] : ""
            
            onMonthChange?(month)
            onYearChange?(year)
        }
        
        private func validateExpiryDate() {
            // Remove separator for validation
            let cleanedValue = expiryDate.replacingOccurrences(of: "/", with: "")
            
            let result = validationService.validate(
                value: cleanedValue,
                for: .expiryDate
            )
            
            isValid = result.isValid
            errorMessage = result.errors.first?.message
            onValidationChange?(result.isValid)
        }
    }
}