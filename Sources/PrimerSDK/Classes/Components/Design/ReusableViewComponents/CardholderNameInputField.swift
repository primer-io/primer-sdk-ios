//
//  CardholderNameInputField.swift
//
//  Created on 21.03.2025.
//

import SwiftUI
import UIKit

/// A SwiftUI component for cardholder name input with validation
/// and consistent styling with other card input fields.
@available(iOS 15.0, *)
struct CardholderNameInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    var label: String

    /// Placeholder text for the input field
    var placeholder: String

    /// Callback when the validation state changes
    var onValidationChange: ((Bool) -> Void)?

    // MARK: - Private Properties

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
            CardholderNameTextField(
                cardholderName: $cardholderName,
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
            // Use DispatchQueue to avoid state updates during view update
            DispatchQueue.main.async {
                logger.debug(message: "🔄 Cardholder name validation state changed: \(newValue)")
                onValidationChange?(newValue)
            }
        }
        .onAppear {
            logger.debug(message: "👁️ Cardholder name input field appeared")
        }
    }

    /// Retrieves the cardholder name
    /// - Returns: Current cardholder name
    func getCardholderName() -> String {
        logger.debug(message: "📤 Getting cardholder name: '\(cardholderName)'")
        return cardholderName
    }
}

/// An improved UIViewRepresentable wrapper for cardholder name input
@available(iOS 15.0, *)
struct CardholderNameTextField: UIViewRepresentable, LogReporter {
    @Binding var cardholderName: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let textField = PrimerCardholderNameTextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .done

        logger.debug(message: "🔤 Creating new cardholder name text field")

        // Add a "Done" button to the keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar

        // Important: Set initial value
        textField.internalText = cardholderName

        logger.debug(message: "🔤 Initial cardholder name text field setup complete")

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        // Minimal updates to avoid cycles
        guard let primerTextField = textField as? PrimerCardholderNameTextField else { return }

        // Only update if needed
        if primerTextField.internalText != cardholderName {
            logger.debug(message: "🔄 Updating cardholder name field: internalText='\(primerTextField.internalText ?? "")' → cardholderName='\(cardholderName)'")
            primerTextField.internalText = cardholderName
            primerTextField.text = cardholderName
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        var parent: CardholderNameTextField
        private var isUpdating = false

        init(_ parent: CardholderNameTextField) {
            self.parent = parent
            super.init()
            logger.debug(message: "📝 Cardholder name field coordinator initialized")
        }

        @objc func doneButtonTapped() {
            logger.debug(message: "⌨️ Done button tapped on cardholder name field")
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ Cardholder name field began editing")
            // Clear error message when user starts editing
            parent.errorMessage = nil
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ Cardholder name field ended editing")
            // Validate the cardholder name when the field loses focus
            if let primerTextField = textField as? PrimerCardholderNameTextField,
               let name = primerTextField.internalText {
                validateCardholderName(name)
            }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Early returns to reduce nesting
            if isUpdating {
                logger.debug(message: "🔄 Avoiding reentrance in shouldChangeCharactersIn")
                return false
            }

            guard let primerTextField = textField as? PrimerCardholderNameTextField else {
                return true
            }

            logger.debug(message: "⌨️ Cardholder name shouldChangeCharactersIn - range: \(range.location),\(range.length), replacement: '\(string)'")

            // Get current text
            let currentText = primerTextField.internalText ?? ""

            // Handle return key
            if string == "\n" {
                logger.debug(message: "⌨️ Return key pressed, resigning first responder")
                textField.resignFirstResponder()
                return false
            }

            // Allow deletion
            if string.isEmpty {
                logger.debug(message: "🗑️ Deletion detected in cardholder name field")
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

                updateTextField(primerTextField, newText: newText)
                return false
            }

            // Filter for valid characters (allow letters, spaces, apostrophes, hyphens)
            let allowedCharacterSet = CharacterSet.letters.union(CharacterSet(charactersIn: " '-"))
            let characterSet = CharacterSet(charactersIn: string)
            guard allowedCharacterSet.isSuperset(of: characterSet) else {
                logger.debug(message: "⌨️ Rejecting input - contains invalid characters: '\(string)'")
                return false
            }

            // Process the input
            let newText: String
            if range.length > 0 {
                // Replace a range of text
                let start = currentText.index(currentText.startIndex, offsetBy: range.location)
                let end = currentText.index(start, offsetBy: min(range.length, currentText.count - range.location))
                newText = currentText.replacingCharacters(in: start..<end, with: string)
                logger.debug(message: "⌨️ Replacing text range from \(range.location) to \(range.location + range.length) with '\(string)'")
            } else {
                // Insert text at position
                let index = currentText.index(currentText.startIndex, offsetBy: min(range.location, currentText.count))
                newText = currentText.inserting(contentsOf: string, at: index)
                logger.debug(message: "⌨️ Inserting text '\(string)' at position \(range.location)")
            }

            logger.debug(message: "🔄 Text will change: '\(currentText)' → '\(newText)'")
            updateTextField(primerTextField, newText: newText)
            return false
        }

        private func updateTextField(_ textField: PrimerCardholderNameTextField, newText: String) {
            isUpdating = true

            // Update the text field
            textField.internalText = newText
            textField.text = newText
            logger.debug(message: "🔄 Updated text field with: '\(newText)'")

            // Update the binding
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.cardholderName = newText

                // Validate while typing
                self.validateCardholderNameWhileTyping(newText)

                self.isUpdating = false
                logger.debug(message: "🔄 Text change processing completed")
            }
        }

        // Validation while typing - more lenient
        private func validateCardholderNameWhileTyping(_ name: String) {
            if name.isEmpty {
                logger.debug(message: "🔍 Validation while typing: Empty name - marked as invalid (no error shown)")
                parent.isValid = false
                parent.errorMessage = nil // Don't show error during typing if empty
                return
            }

            // Basic validation - at least 2 characters
            parent.isValid = name.count >= 2
            if parent.isValid {
                logger.debug(message: "✅ Validation while typing: Valid name (>= 2 characters)")
            } else {
                logger.debug(message: "🔍 Validation while typing: Too short (< 2 characters) - marked as invalid (no error shown)")
            }
            parent.errorMessage = parent.isValid ? nil : nil // Don't show error during typing
        }

        // Full validation when field loses focus
        private func validateCardholderName(_ name: String) {
            if name.isEmpty {
                logger.debug(message: "⚠️ Validation failed: Cardholder name cannot be blank")
                parent.isValid = false
                parent.errorMessage = "Cardholder name cannot be blank"
                return
            }

            if name.count < 2 {
                logger.debug(message: "⚠️ Validation failed: Cardholder name is too short (\(name.count) chars)")
                parent.isValid = false
                parent.errorMessage = "Cardholder name is too short"
                return
            }

            // Check if name contains only valid characters
            let allowedCharacterSet = CharacterSet.letters.union(CharacterSet(charactersIn: " '-"))
            if name.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                logger.debug(message: "⚠️ Validation failed: Cardholder name contains invalid characters")
                parent.isValid = false
                parent.errorMessage = "Cardholder name contains invalid characters"
                return
            }

            // All checks passed
            logger.debug(message: "✅ Validation passed: Cardholder name is valid")
            parent.isValid = true
            parent.errorMessage = nil
        }
    }
}

// Custom TextField that masks its text property
class PrimerCardholderNameTextField: UITextField, LogReporter {
    /// The actual card number stored internally
    var internalText: String?

    var isEmpty: Bool {
        return (internalText ?? "").isEmpty
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        logger.debug(message: "⌨️ Cardholder name field became first responder: \(result)")
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        logger.debug(message: "⌨️ Cardholder name field resigned first responder: \(result)")
        return result
    }
}

// Extension for applying callbacks via view modifiers
@available(iOS 15.0, *)
extension CardholderNameInputField {
    func onValidationChange(_ handler: @escaping (Bool) -> Void) -> Self {
        var view = self
        view.onValidationChange = handler
        return view
    }
}
