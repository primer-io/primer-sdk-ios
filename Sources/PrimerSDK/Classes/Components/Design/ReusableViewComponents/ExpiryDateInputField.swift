//
//  ExpiryDateInputField.swift
//  
//
//  Created by Boris on 21.3.25..
//


//
//  ExpiryDateInputField.swift
//
//  Created on 21.03.2025.
//

import SwiftUI
import UIKit

/// A SwiftUI component for credit card expiry date input with automatic formatting
/// and validation to ensure dates are valid and not in the past.
@available(iOS 15.0, *)
struct ExpiryDateInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    var label: String

    /// Placeholder text for the input field
    var placeholder: String

    /// Callback when the validation state changes
    var onValidationChange: ((Bool) -> Void)?
    
    /// Callback when month value changes
    var onMonthChange: ((String) -> Void)?
    
    /// Callback when year value changes
    var onYearChange: ((String) -> Void)?

    // MARK: - Private Properties

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
            ExpiryDateTextField(
                expiryDate: $expiryDate,
                month: $month,
                year: $year,
                isValid: $isValid,
                errorMessage: $errorMessage,
                placeholder: placeholder
            )
            .padding()
            .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
            .cornerRadius(8)

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 2)
            }
        }
        .onChange(of: isValid) { newValue in
            if let isValid = newValue {
                // Use DispatchQueue to avoid state updates during view update
                DispatchQueue.main.async {
                    logger.debug(message: "🔄 Expiry date validation state changed: \(isValid)")
                    onValidationChange?(isValid)
                }
            }
        }
        .onChange(of: month) { newValue in
            DispatchQueue.main.async {
                logger.debug(message: "📅 Month value changed: \(newValue)")
                onMonthChange?(newValue)
            }
        }
        .onChange(of: year) { newValue in
            DispatchQueue.main.async {
                logger.debug(message: "📅 Year value changed: \(newValue)")
                onYearChange?(newValue)
            }
        }
        .onAppear {
            logger.debug(message: "👁️ Expiry date input field appeared")
        }
    }

    /// Retrieves the current month value
    /// - Returns: Current month (MM)
    func getMonth() -> String {
        return month
    }
    
    /// Retrieves the current year value
    /// - Returns: Current year (YY)
    func getYear() -> String {
        return year
    }
    
    /// Retrieves the formatted expiry date
    /// - Returns: Current expiry date (MM/YY)
    func getExpiryDate() -> String {
        return expiryDate
    }
}

/// An improved UIViewRepresentable wrapper for expiry date input
@available(iOS 15.0, *)
struct ExpiryDateTextField: UIViewRepresentable, LogReporter {
    @Binding var expiryDate: String
    @Binding var month: String
    @Binding var year: String
    @Binding var isValid: Bool?
    @Binding var errorMessage: String?
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let textField = PrimerExpiryDateTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.textContentType = .none // Prevent autofill

        logger.debug(message: "🔤 Creating new expiry date text field")

        // Add a "Done" button to the keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar

        // Important: Set initial value
        textField.internalText = expiryDate
        
        logger.debug(message: "🔤 Initial expiry date text field setup complete")

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        // Minimal updates to avoid cycles
        guard let expiryTextField = textField as? PrimerExpiryDateTextField else { return }

        // Only update if needed
        if expiryTextField.internalText != expiryDate {
            logger.debug(message: "🔄 Updating expiry date field: internalText='\(expiryTextField.internalText ?? "")' → expiryDate='\(expiryDate)'")
            expiryTextField.internalText = expiryDate
            expiryTextField.text = expiryDate
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        var parent: ExpiryDateTextField
        private var isUpdating = false

        init(_ parent: ExpiryDateTextField) {
            self.parent = parent
            super.init()
            logger.debug(message: "📝 Expiry date field coordinator initialized")
        }

        @objc func doneButtonTapped() {
            logger.debug(message: "⌨️ Done button tapped on expiry date field")
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ Expiry date field began editing")
            // Clear error message when user starts editing
            parent.errorMessage = nil
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ Expiry date field ended editing")
            // Validate the expiry date when the field loses focus
            if let expiryTextField = textField as? PrimerExpiryDateTextField,
               let text = expiryTextField.internalText {
                validateExpiryDateFully(text)
            }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Early returns to reduce nesting
            if isUpdating {
                logger.debug(message: "🔄 Avoiding reentrance in shouldChangeCharactersIn")
                return false
            }

            guard let expiryTextField = textField as? PrimerExpiryDateTextField else {
                return true
            }

            logger.debug(message: "⌨️ Expiry date shouldChangeCharactersIn - range: \(range.location),\(range.length), replacement: '\(string)'")

            // Get current text
            let currentText = expiryTextField.internalText ?? ""
            
            // Handle return key
            if string == "\n" {
                logger.debug(message: "⌨️ Return key pressed, resigning first responder")
                textField.resignFirstResponder()
                return false
            }

            // Only allow numbers and just return for non-numeric input except for deletion
            if !string.isEmpty && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
                logger.debug(message: "⌨️ Rejecting non-numeric input: '\(string)'")
                return false
            }
            
            // Process the input to create the new text value
            let newText = processInput(currentText: currentText, range: range, string: string)
            
            // Update the UI and bindings
            updateTextField(expiryTextField, newText: newText)
            
            return false
        }
        
        private func processInput(currentText: String, range: NSRange, string: String) -> String {
            // Handle deletion
            if string.isEmpty {
                logger.debug(message: "🗑️ Deletion detected in expiry date field")
                
                // If deleting the separator, also remove the character before it
                if range.location == 2 && range.length == 1 && currentText.count >= 3 && currentText[currentText.index(currentText.startIndex, offsetBy: 2)] == "/" {
                    let newText = String(currentText.prefix(1))
                    logger.debug(message: "🗑️ Deleting separator and character before it: '\(currentText)' → '\(newText)'")
                    return newText
                }
                
                // Normal deletion
                let newText: String
                if range.length > 0 && range.location < currentText.count {
                    let start = currentText.index(currentText.startIndex, offsetBy: range.location)
                    let end = currentText.index(start, offsetBy: min(range.length, currentText.count - range.location))
                    newText = currentText.replacingCharacters(in: start..<end, with: "")
                    logger.debug(message: "🗑️ Range deletion from \(range.location) to \(range.location + range.length)")
                } else if range.location < currentText.count {
                    let index = currentText.index(currentText.startIndex, offsetBy: range.location)
                    var chars = Array(currentText)
                    chars.remove(at: range.location)
                    newText = String(chars)
                    logger.debug(message: "🗑️ Single character deletion at position \(range.location)")
                } else {
                    newText = currentText
                    logger.debug(message: "🗑️ No deletion performed (range outside text bounds)")
                }
                
                return newText
            }
            
            // Handle additions
            // Remove the / character temporarily for easier processing
            let sanitizedText = currentText.replacingOccurrences(of: "/", with: "")
            
            // Calculate where to insert the new text in the sanitized version
            var sanitizedLocation = range.location
            // Adjust the location if we're after the separator in the original text
            if range.location > 2 && currentText.count >= 3 && currentText[currentText.index(currentText.startIndex, offsetBy: 2)] == "/" {
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
            
            // Limit to 4 digits total (MM/YY format)
            newSanitizedText = String(newSanitizedText.prefix(4))
            
            // Format with separator
            let formattedText: String
            if newSanitizedText.count > 2 {
                formattedText = "\(newSanitizedText.prefix(2))/\(newSanitizedText.dropFirst(2))"
            } else {
                formattedText = newSanitizedText
            }
            
            logger.debug(message: "⌨️ Processed input: '\(currentText)' → '\(formattedText)'")
            return formattedText
        }
        
        private func updateTextField(_ textField: PrimerExpiryDateTextField, newText: String) {
            isUpdating = true
            
            // Update the text field
            textField.internalText = newText
            textField.text = newText
            logger.debug(message: "🔄 Updated text field with: '\(newText)'")
            
            // Update the binding
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.expiryDate = newText
                
                // Extract month and year
                self.extractMonthAndYear(from: newText)
                
                // Validate while typing
                self.validateExpiryDateWhileTyping(newText)
                
                self.isUpdating = false
                logger.debug(message: "🔄 Text change processing completed")
            }
        }
        
        private func extractMonthAndYear(from text: String) {
            let parts = text.components(separatedBy: "/")
            
            let month = parts.count > 0 ? parts[0] : ""
            let year = parts.count > 1 ? parts[1] : ""
            
            if parent.month != month {
                parent.month = month
                logger.debug(message: "📅 Extracted month: \(month)")
            }
            
            if parent.year != year {
                parent.year = year
                logger.debug(message: "📅 Extracted year: \(year)")
            }
        }
        
        // Validation while typing - more lenient
        private func validateExpiryDateWhileTyping(_ text: String) {
            if text.isEmpty {
                logger.debug(message: "🔍 Validation while typing: Empty date - marked as invalid (no error shown)")
                parent.isValid = false
                parent.errorMessage = nil // Don't show error during typing if empty
                return
            }
            
            // Don't show validation errors until we have a complete date (MM/YY)
            let parts = text.components(separatedBy: "/")
            if parts.count < 2 || (parts.count == 2 && parts[1].count < 2) {
                logger.debug(message: "🔍 Validation while typing: Incomplete date - status pending")
                parent.isValid = nil
                parent.errorMessage = nil
                return
            }
            
            // Now we have a complete date, validate it
            if isExpiryDateValid(text) {
                logger.debug(message: "✅ Validation while typing: Valid expiry date")
                parent.isValid = true
                parent.errorMessage = nil
            } else {
                logger.debug(message: "🔍 Validation while typing: Invalid expiry date - marked as invalid")
                parent.isValid = false
                parent.errorMessage = nil // Don't show error during typing
            }
        }
        
        // Full validation when field loses focus
        private func validateExpiryDateFully(_ text: String) {
            if text.isEmpty {
                logger.debug(message: "⚠️ Validation failed: Expiry date cannot be blank")
                parent.isValid = false
                parent.errorMessage = "Expiry date cannot be blank"
                return
            }
            
            let parts = text.components(separatedBy: "/")
            if parts.count < 2 {
                logger.debug(message: "⚠️ Validation failed: Invalid expiry date format")
                parent.isValid = false
                parent.errorMessage = "Please enter date as MM/YY"
                return
            }
            
            let month = parts[0]
            let year = parts[1]
            
            // Check month format
            if month.count != 2 || !month.isNumeric {
                logger.debug(message: "⚠️ Validation failed: Invalid month format")
                parent.isValid = false
                parent.errorMessage = "Month must be 2 digits (01-12)"
                return
            }
            
            // Check year format
            if year.count != 2 || !year.isNumeric {
                logger.debug(message: "⚠️ Validation failed: Invalid year format")
                parent.isValid = false
                parent.errorMessage = "Year must be 2 digits"
                return
            }
            
            // Check if month is valid (01-12)
            if let monthInt = Int(month), (monthInt < 1 || monthInt > 12) {
                logger.debug(message: "⚠️ Validation failed: Month must be between 01 and 12")
                parent.isValid = false
                parent.errorMessage = "Month must be between 01 and 12"
                return
            }
            
            // Check if expiry date is in the future
            if !isExpiryDateValid(text) {
                logger.debug(message: "⚠️ Validation failed: Expiry date must be in the future")
                parent.isValid = false
                parent.errorMessage = "Expiry date must be in the future"
                return
            }
            
            // All checks passed
            logger.debug(message: "✅ Validation passed: Expiry date is valid")
            parent.isValid = true
            parent.errorMessage = nil
        }
        
        /// Checks if the expiry date is valid (not in the past)
        private func isExpiryDateValid(_ text: String) -> Bool {
            let parts = text.components(separatedBy: "/")
            if parts.count < 2 {
                return false
            }
            
            guard let month = Int(parts[0]), let year = Int(parts[1]) else {
                return false
            }
            
            // Get current date components
            let calendar = Calendar.current
            let currentDateComponents = calendar.dateComponents([.year, .month], from: Date())
            
            // Validate month value (1-12)
            if month < 1 || month > 12 {
                return false
            }
            
            // Get current year's last two digits
            let currentYear = currentDateComponents.year! % 100
            let currentMonth = currentDateComponents.month!
            
            // The card expires at the end of the month
            // If it's the current year, make sure the month is in the future
            if year < currentYear {
                return false
            } else if year == currentYear && month < currentMonth {
                return false
            }
            
            return true
        }
    }
}

// Custom TextField that masks its text property
class PrimerExpiryDateTextField: UITextField, LogReporter {
    /// The actual expiry date stored internally
    var internalText: String?

    var isEmpty: Bool {
        return (internalText ?? "").isEmpty
    }
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        logger.debug(message: "⌨️ Expiry date field became first responder: \(result)")
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        logger.debug(message: "⌨️ Expiry date field resigned first responder: \(result)")
        return result
    }
}

// Extension for applying callbacks via view modifiers
@available(iOS 15.0, *)
extension ExpiryDateInputField {
    func onValidationChange(_ handler: @escaping (Bool) -> Void) -> Self {
        var view = self
        view.onValidationChange = handler
        return view
    }
    
    func onMonthChange(_ handler: @escaping (String) -> Void) -> Self {
        var view = self
        view.onMonthChange = handler
        return view
    }
    
    func onYearChange(_ handler: @escaping (String) -> Void) -> Self {
        var view = self
        view.onYearChange = handler
        return view
    }
}
