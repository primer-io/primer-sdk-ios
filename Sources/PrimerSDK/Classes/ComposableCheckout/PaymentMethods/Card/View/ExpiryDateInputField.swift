//
//  ExpiryDateInputField.swift
//
//
//  Created by Boris on 21.3.25..
//

// swiftlint:disable file_length

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

    // MARK: - Initialization

    init(
        label: String,
        placeholder: String,
        onValidationChange: ((Bool) -> Void)? = nil,
        onMonthChange: ((String) -> Void)? = nil,
        onYearChange: ((String) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.onValidationChange = onValidationChange
        self.onMonthChange = onMonthChange
        self.onYearChange = onYearChange
    }

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
                    validationService: validationService
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
            logger.debug(message: "👁️ Expiry date input field appeared")
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

    /// Retrieves the current month value
    /// - Returns: Current month (MM)
    func getMonth() -> String {
        let value = month
        logger.debug(message: "📤 getMonth() returning: '\(value)'")
        return value
    }

    /// Retrieves the current year value
    /// - Returns: Current year (YY)
    func getYear() -> String {
        let value = year
        logger.debug(message: "📤 getYear() returning: '\(value)'")
        return value
    }

    /// Retrieves the formatted expiry date
    /// - Returns: Current expiry date (MM/YY)
    func getExpiryDate() -> String {
        let value = expiryDate
        logger.debug(message: "📤 getExpiryDate() returning: '\(value)'")
        return value
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
    let validationService: ValidationService

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
        Coordinator(
            validationService: validationService,
            updateExpiryDate: { newValue in
                self.expiryDate = newValue
            },
            updateValidationState: { isValid, errorMessage in
                self.isValid = isValid
                self.errorMessage = errorMessage
            },
            updateMonthYear: { month, year in
                self.month = month
                self.year = year
            }
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        // MARK: - Properties

        private let validationService: ValidationService
        private let updateExpiryDate: (String) -> Void
        private let updateValidationState: (Bool?, String?) -> Void
        private let updateMonthYear: (String, String) -> Void

        private var isUpdating = false
        private var activeTextFieldUpdateToken: UUID = UUID()

        // MARK: - Initialization

        init(
            validationService: ValidationService,
            updateExpiryDate: @escaping (String) -> Void,
            updateValidationState: @escaping (Bool?, String?) -> Void,
            updateMonthYear: @escaping (String, String) -> Void
        ) {
            self.validationService = validationService
            self.updateExpiryDate = updateExpiryDate
            self.updateValidationState = updateValidationState
            self.updateMonthYear = updateMonthYear
            super.init()
            logger.debug(message: "📝 Expiry date field coordinator initialized")
        }

        // MARK: - UIActions

        @objc func doneButtonTapped() {
            logger.debug(message: "⌨️ Done button tapped on expiry date field")
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }

        // MARK: - UITextFieldDelegate

        func textFieldDidBeginEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ Expiry date field began editing")
            // Clear error message when user starts editing
            updateValidationState(nil, nil)
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

        // MARK: - Helper Methods

        private func processInput(currentText: String, range: NSRange, string: String) -> String {
            // Handle deletion
            if string.isEmpty {
                logger.debug(message: "🗑️ Deletion detected in expiry date field")

                // If deleting the separator, also remove the character before it
                if range.location == 2 && range.length == 1 && currentText.count >= 3 &&
                    currentText[currentText.index(currentText.startIndex, offsetBy: 2)] == "/" {
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
            let updateToken = UUID()
            activeTextFieldUpdateToken = updateToken
            isUpdating = true

            // Update the text field
            textField.internalText = newText
            textField.text = newText
            logger.debug(message: "🔄 Updated text field with: '\(newText)'")

            // Update the binding
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.activeTextFieldUpdateToken == updateToken else { return }
                self.updateExpiryDate(newText)

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

            updateMonthYear(month, year)
            logger.debug(message: "📅 Extracted month: \(month), year: \(year)")
        }

        // Validation while typing - more lenient
        private func validateExpiryDateWhileTyping(_ text: String) {
            if text.isEmpty {
                logger.debug(message: "🔍 Validation while typing: Empty date - marked as invalid (no error shown)")
                updateValidationState(false, nil) // Don't show error during typing if empty
                return
            }

            // Don't show validation errors until we have a complete date (MM/YY)
            let parts = text.components(separatedBy: "/")
            if parts.count < 2 || (parts.count == 2 && parts[1].count < 2) {
                logger.debug(message: "🔍 Validation while typing: Incomplete date - status pending")
                updateValidationState(nil, nil)
                return
            }

            // Now we have a complete date, do a basic check
            // We'll use a lightweight check for typing validation to provide immediate feedback

            let month = parts[0]
            let year = parts[1]

            // Simple format validation during typing
            if month.count == 2 && year.count == 2 &&
                month.isNumeric && year.isNumeric &&
                (Int(month) ?? 0) >= 1 && (Int(month) ?? 0) <= 12 {
                updateValidationState(true, nil)
                logger.debug(message: "✅ Validation while typing: Valid expiry date format")
            } else {
                updateValidationState(false, nil) // Don't show error during typing
                logger.debug(message: "🔍 Validation while typing: Invalid expiry date format - marked as invalid")
            }
        }

        private func validateExpiryDateFully(_ text: String) {
            // Create the ExpiryDateInput from the text
            if let expiryDateInput = ExpiryDateInput(formattedDate: text) {
                // Use the validation service with ExpiryDateRule
                let validationResult = validationService.validateExpiry(
                    month: expiryDateInput.month,
                    year: expiryDateInput.year
                )

                // Update state based on validation result
                updateValidationState(validationResult.isValid, validationResult.errorMessage)

                if validationResult.isValid {
                    logger.debug(message: "✅ Validation passed: Expiry date is valid")
                } else {
                    logger.debug(message: "⚠️ Validation failed: \(validationResult.errorMessage ?? "Unknown error")")
                }
            } else {
                // Invalid format
                updateValidationState(false, "Please enter date as MM/YY")
                logger.debug(message: "⚠️ Validation failed: Invalid expiry date format")
            }
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

// swiftlint:enable file_length
