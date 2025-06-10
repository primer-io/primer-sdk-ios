//
//  CardholderNameInputField.swift
//
//  Created on 21.03.2025.
//

// swiftlint:disable file_length

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

    // MARK: - Initialization

    init(
        label: String,
        placeholder: String,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.onValidationChange = onValidationChange
    }

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
                    validationService: validationService
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
            logger.debug(message: "👁️ Cardholder name input field appeared")
        }
        .onChange(of: isValid) { newValue in
            // Use DispatchQueue to avoid state updates during view update
            DispatchQueue.main.async {
                logger.debug(message: "🔄 Cardholder name validation state changed: \(newValue)")
                onValidationChange?(newValue)
            }
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
    let validationService: ValidationService

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
        Coordinator(
            validationService: validationService,
            updateCardholderName: { newValue in
                self.cardholderName = newValue
            },
            updateValidationState: { isValid, errorMessage in
                self.isValid = isValid
                self.errorMessage = errorMessage
            }
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        // MARK: - Properties

        private let validationService: ValidationService
        private let updateCardholderName: (String) -> Void
        private let updateValidationState: (Bool, String?) -> Void

        private var isUpdating = false
        private var activeTextFieldUpdateToken: UUID = UUID()

        // MARK: - Initialization

        init(
            validationService: ValidationService,
            updateCardholderName: @escaping (String) -> Void,
            updateValidationState: @escaping (Bool, String?) -> Void
        ) {
            self.validationService = validationService
            self.updateCardholderName = updateCardholderName
            self.updateValidationState = updateValidationState
            super.init()
            logger.debug(message: "📝 Cardholder name field coordinator initialized")
        }

        // MARK: - UI Actions

        @objc func doneButtonTapped() {
            logger.debug(message: "⌨️ Done button tapped on cardholder name field")
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }

        // MARK: - UITextFieldDelegate Methods

        func textFieldDidBeginEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ Cardholder name field began editing")
            // Clear error message when user starts editing
            updateValidationState(false, nil)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ Cardholder name field ended editing")
            // Validate the cardholder name when the field loses focus
            if let primerTextField = textField as? PrimerCardholderNameTextField,
               let name = primerTextField.internalText {
                validateCardholderName(name)
            }
        }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            // Early return if an update is already in progress to avoid reentrance.
            if isUpdating {
                logger.debug(message: "🔄 Avoiding reentrance in shouldChangeCharactersIn")
                return false
            }

            // Ensure the text field is the expected custom type.
            guard let primerTextField = textField as? PrimerCardholderNameTextField else {
                return true
            }

            // Log the range and replacement string.
            logger.debug(message: "⌨️ Cardholder name shouldChangeCharactersIn - range: \(range.location),\(range.length), replacement: '\(string)'")

            // Retrieve the current text (or use an empty string if nil).
            let currentText = primerTextField.internalText ?? ""

            // Handle special cases: if the user presses the return key or performs deletion,
            // then we process those actions separately.
            if handleSpecialCases(for: primerTextField,
                                  in: textField,
                                  currentText: currentText,
                                  range: range,
                                  replacementString: string) {
                return false
            }

            // Validate that the input contains only allowed characters.
            // Allowed characters are letters, spaces, apostrophes, and hyphens.
            guard validateAllowedCharacters(for: string) else {
                logger.debug(message: "⌨️ Rejecting input - contains invalid characters: '\(string)'")
                return false
            }

            // Process the input change. Depending on whether this is an insertion or a replacement,
            // the helper function computes the new text.
            let newText = processInputChange(currentText: currentText,
                                             range: range,
                                             replacementString: string)
            logger.debug(message: "🔄 Text will change: '\(currentText)' → '\(newText)'")

            // When inserting text, extra spaces may have been added if pasting.
            // For paste operations (string longer than one character), we trim any leading/trailing whitespace.
            let replacement = string.count > 1 ? string.trimmingCharacters(in: .whitespacesAndNewlines) : string
            // Compute the desired cursor offset:
            // • For deletion, we want the cursor to be at the starting index of the deletion (range.location).
            // • For insertion, we set it to range.location + (trimmed replacement string length).
            let desiredCursorOffset = string.isEmpty ? range.location : range.location + replacement.count

            // Update the text field with the new text and restore the cursor position.
            updateTextField(primerTextField, newText: newText, desiredCursorOffset: desiredCursorOffset)
            return false
        }

        // MARK: - Helper Functions

        /// Handles special cases such as when the return key is pressed or when deletion occurs.
        ///
        /// - Parameters:
        ///   - primerTextField: The custom text field (PrimerCardholderNameTextField).
        ///   - textField: The original UITextField instance.
        ///   - currentText: The current text from the text field.
        ///   - range: The range where the change is occurring.
        ///   - replacementString: The string to be inserted.
        /// - Returns: `true` if a special case was handled (i.e. no further processing is needed).
        private func handleSpecialCases(for primerTextField: PrimerCardholderNameTextField,
                                        in textField: UITextField,
                                        currentText: String,
                                        range: NSRange,
                                        replacementString string: String) -> Bool {
            // Handle the return key by resigning first responder.
            if string == "\n" {
                logger.debug(message: "⌨️ Return key pressed, resigning first responder")
                textField.resignFirstResponder()
                return true
            }

            // Handle deletion when the replacement string is empty.
            if string.isEmpty {
                logger.debug(message: "🗑️ Deletion detected in cardholder name field")
                let newText: String
                if range.length > 0 && range.location < currentText.count {
                    // Range deletion: remove the specified range from the current text.
                    let start = currentText.index(currentText.startIndex, offsetBy: range.location)
                    let end = currentText.index(start, offsetBy: min(range.length, currentText.count - range.location))
                    newText = currentText.replacingCharacters(in: start..<end, with: "")
                    logger.debug(message: "🗑️ Range deletion from \(range.location) to \(range.location + range.length)")
                } else if range.location < currentText.count {
                    // Single character deletion: remove the character at the specified location.
                    var chars = Array(currentText)
                    chars.remove(at: range.location)
                    newText = String(chars)
                    logger.debug(message: "🗑️ Single character deletion at position \(range.location)")
                } else {
                    // If the deletion range is outside the text bounds, do nothing.
                    newText = currentText
                    logger.debug(message: "🗑️ No deletion performed (range outside text bounds)")
                }
                // Update the text field with the new text and set the cursor at the deletion start.
                updateTextField(primerTextField, newText: newText, desiredCursorOffset: range.location)
                return true
            }

            // No special case handled; return false.
            return false
        }

        /// Validates that the input string contains only allowed characters.
        ///
        /// - Parameter string: The string to validate.
        /// - Returns: `true` if the string consists only of letters, spaces, apostrophes, and hyphens; otherwise, `false`.
        private func validateAllowedCharacters(for string: String) -> Bool {
            let allowedCharacterSet = CharacterSet.letters.union(CharacterSet(charactersIn: " '-"))
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacterSet.isSuperset(of: characterSet)
        }

        /// Processes the input change by replacing the text in the given range or inserting new text.
        ///
        /// - Parameters:
        ///   - currentText: The current text in the text field.
        ///   - range: The range where the change should be applied.
        ///   - replacementString: The string to insert.
        /// - Returns: The updated text after the change.
        private func processInputChange(currentText: String,
                                        range: NSRange,
                                        replacementString string: String) -> String {
            if range.length > 0 {
                // If a range of text is being replaced, compute the new text.
                let start = currentText.index(currentText.startIndex, offsetBy: range.location)
                let end = currentText.index(start, offsetBy: min(range.length, currentText.count - range.location))
                logger.debug(message: "⌨️ Replacing text range from \(range.location) to \(range.location + range.length) with '\(string)'")
                return currentText.replacingCharacters(in: start..<end, with: string)
            } else {
                // Otherwise, insert the new text at the specified index.
                let index = currentText.index(currentText.startIndex, offsetBy: min(range.location, currentText.count))
                logger.debug(message: "⌨️ Inserting text '\(string)' at position \(range.location)")
                // If pasting (i.e. string has length > 1), trim any extra whitespace.
                let replacement = string.count > 1 ? string.trimmingCharacters(in: .whitespacesAndNewlines) : string
                return currentText.inserting(contentsOf: replacement, at: index)
            }
        }

        /// Updates the text field's UI and internal state, and restores the cursor position.
        ///
        /// - Parameters:
        ///   - textField: The custom text field (PrimerCardholderNameTextField) to update.
        ///   - newText: The new text to set.
        ///   - desiredCursorOffset: The offset (in characters) where the cursor should be restored.
        private func updateTextField(_ textField: PrimerCardholderNameTextField,
                                     newText: String,
                                     desiredCursorOffset: Int) {
            let updateToken = UUID()
            activeTextFieldUpdateToken = updateToken
            isUpdating = true

            // Update the internal text (used for logic/formatting) and the visible text.
            textField.internalText = newText
            textField.text = newText
            logger.debug(message: "🔄 Updated text field with: '\(newText)'")

            // Restore the cursor position on the main thread.
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.activeTextFieldUpdateToken == updateToken else { return }

                // Update parent binding
                self.updateCardholderName(newText)

                // Try to obtain the text position corresponding to the desired offset.
                if let newPosition = textField.position(from: textField.beginningOfDocument, offset: desiredCursorOffset) {
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                    logger.debug(message: "🔄 Restored cursor position to offset: \(desiredCursorOffset)")
                } else {
                    logger.debug(message: "🔄 Could not restore cursor position; defaulting to end")
                }

                // Validate while typing using the validation service
                self.validateCardholderNameWhileTyping(newText)
                self.isUpdating = false
                logger.debug(message: "🔄 Text change processing completed")
            }
        }

        // MARK: - Validation Methods

        // Validation while typing - more lenient
        private func validateCardholderNameWhileTyping(_ name: String) {
            if name.isEmpty {
                logger.debug(message: "🔍 Validation while typing: Empty name - marked as invalid (no error shown)")
                updateValidationState(false, nil) // Don't show error during typing if empty
                return
            }

            // Use the validation service but with more lenient expectations during typing
            // Just verify it's at least 2 characters for immediate feedback
            let isValid = name.count >= 2
            updateValidationState(isValid, nil) // Don't show error during typing

            if isValid {
                logger.debug(message: "✅ Validation while typing: Valid name (>= 2 characters)")
            } else {
                logger.debug(message: "🔍 Validation while typing: Too short (< 2 characters) - marked as invalid (no error shown)")
            }
        }

        // Full validation when field loses focus
        private func validateCardholderName(_ name: String) {
            // Use the validation service for complete validation
            let validationResult = validationService.validateCardholderName(name)

            // Update the state based on validation result
            updateValidationState(validationResult.isValid, validationResult.errorMessage)

            if validationResult.isValid {
                logger.debug(message: "✅ Validation passed: Cardholder name is valid")
            } else {
                logger.debug(message: "⚠️ Validation failed: \(validationResult.errorMessage ?? "Unknown error")")
            }
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

// swiftlint:enable file_length
