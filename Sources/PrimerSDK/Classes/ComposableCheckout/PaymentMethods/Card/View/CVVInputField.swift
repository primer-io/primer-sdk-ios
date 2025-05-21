//
//  CVVInputField.swift
//
//  Created by Boris on 20.3.25..
//

import SwiftUI
import UIKit

/// A SwiftUI component for credit card CVV input with validation based on card network.
@available(iOS 15.0, *)
struct CVVInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    var label: String

    /// Placeholder text for the input field
    var placeholder: String

    /// The card network to validate against (determines CVV length requirements)
    var cardNetwork: CardNetwork

    /// Callback when the validation state changes
    var onValidationChange: ((Bool) -> Void)?

    // MARK: - Private Properties

    /// The validation service used to validate the CVV
    private let validationService: ValidationService

    /// The CVV entered by the user
    @State private var cvv: String = ""

    /// The validation state of the CVV
    @State private var isValid: Bool?

    /// Error message if validation fails
    @State private var errorMessage: String?

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(
        label: String,
        placeholder: String,
        cardNetwork: CardNetwork,
        validationService: ValidationService,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.cardNetwork = cardNetwork
        self.validationService = validationService
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            // CVV input field
            CVVTextField(
                cvv: $cvv,
                isValid: $isValid,
                errorMessage: $errorMessage,
                placeholder: placeholder,
                cardNetwork: cardNetwork,
                validationService: validationService
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
                    onValidationChange?(isValid)
                }
            }
        }
    }

    /// Retrieves the current CVV value
    /// - Returns: Current CVV
    func getCVV() -> String {
        let value = cvv
        logger.debug(message: "📤 getCVV() returning: '\(value)'")
        return value
    }
}

/// An improved UIViewRepresentable wrapper for a CVV text field
@available(iOS 15.0, *)
struct CVVTextField: UIViewRepresentable, LogReporter {
    @Binding var cvv: String
    @Binding var isValid: Bool?
    @Binding var errorMessage: String?
    var placeholder: String
    var cardNetwork: CardNetwork
    let validationService: ValidationService

    func makeUIView(context: Context) -> UITextField {
        let textField = PrimerCVVTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.textContentType = .oneTimeCode // Help prevent autofill of wrong data

        // Define the required CVV length based on card network
        context.coordinator.expectedCVVLength = cardNetwork.validation?.code.length ?? 3
        logger.debug(message: "🔤 Creating new CVV text field")

        // Add a "Done" button to the keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar

        // Important: Set initial value
        textField.internalText = cvv

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        // Minimal updates to avoid cycles
        guard let cvvTextField = textField as? PrimerCVVTextField else { return }

        // Only update if needed
        if cvvTextField.internalText != cvv {
            logger.debug(message: "🔄 Updating CVV text field: internalText='\(cvvTextField.internalText ?? "")' → cvv='\(cvv)'")
            cvvTextField.internalText = cvv
            cvvTextField.text = cvv
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            cardNetwork: cardNetwork,
            updateCVV: { newValue in
                self.cvv = newValue
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
        private let cardNetwork: CardNetwork
        private let updateCVV: (String) -> Void
        private let updateValidationState: (Bool?, String?) -> Void

        var expectedCVVLength: Int = 3 // Default length, will be updated based on card type

        // Add a flag to prevent update cycles
        private var isUpdating = false

        // MARK: - Initialization

        init(
            validationService: ValidationService,
            cardNetwork: CardNetwork,
            updateCVV: @escaping (String) -> Void,
            updateValidationState: @escaping (Bool?, String?) -> Void
        ) {
            self.validationService = validationService
            self.cardNetwork = cardNetwork
            self.updateCVV = updateCVV
            self.updateValidationState = updateValidationState
            super.init()
            logger.debug(message: "📝 CVV field coordinator initialized")
        }

        // MARK: - UIActions

        @objc func doneButtonTapped() {
            logger.debug(message: "⌨️ Done button tapped")
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }

        // MARK: - UITextFieldDelegate

        func textFieldDidBeginEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ CVV field began editing")
            // Clear error message when user starts editing
            updateValidationState(nil, nil)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ CVV field ended editing")
            // Validate the CVV when the field loses focus
            if let cvvTextField = textField as? PrimerCVVTextField,
               let cvv = cvvTextField.internalText {
                validateCVVFully(cvv)
            }
        }

        // MARK: - Main UITextFieldDelegate method
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Avoid reentrance
            if isUpdating {
                return false
            }

            guard let cvvTextField = textField as? PrimerCVVTextField else {
                return true
            }

            logger.debug(message: "⌨️ CVV shouldChangeCharactersIn - range: \(range.location),\(range.length), replacement: '\(string)'")

            // Get current text
            let currentText = cvvTextField.internalText ?? ""

            // Create the new text that would result from this change
            let newText: String
            if let textRange = Range(range, in: currentText) {
                newText = currentText.replacingCharacters(in: textRange, with: string)
            } else {
                newText = currentText
            }

            // Only allow numbers
            if !string.isEmpty && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
                return false
            }

            // Check max length
            if newText.count > expectedCVVLength {
                return false
            }

            // Update the text
            isUpdating = true
            cvvTextField.internalText = newText
            cvvTextField.text = newText
            updateCVV(newText)
            isUpdating = false

            // Validate while typing
            validateCVVWhileTyping(newText)

            return false
        }

        // MARK: - Validation Methods

        // Validation while typing - keep it minimal during input
        private func validateCVVWhileTyping(_ cvv: String) {
            if cvv.isEmpty {
                updateValidationState(nil, nil)
                return
            }

            // Simple validation during typing - we'll use the simpler verification
            // for immediate feedback and use the full validation service on blur

            // Check if all characters are numeric
            if !cvv.allSatisfy({ $0.isNumber }) {
                updateValidationState(false, "CVV must contain only numbers")
                return
            }

            // Check length based on card type
            if cvv.count == expectedCVVLength {
                updateValidationState(true, nil)
            } else {
                updateValidationState(nil, nil)
            }
        }

        // Full validation when field loses focus
        private func validateCVVFully(_ cvv: String) {
            // Use the validation service with the CVVRule
            let validationResult = validationService.validateCVV(cvv, cardNetwork: cardNetwork)

            // Update state based on validation result
            updateValidationState(validationResult.isValid, validationResult.errorMessage)

            if validationResult.isValid {
                logger.debug(message: "✅ Validation passed: CVV is valid")
            } else {
                logger.debug(message: "⚠️ Validation failed: \(validationResult.errorMessage ?? "Unknown error")")
            }
        }
    }
}

// MARK: - Custom TextField

/// A custom UITextField that masks its text property to prevent exposing
/// sensitive CVV information externally, while maintaining the internal value.
class PrimerCVVTextField: UITextField {
    /// The actual CVV stored internally
    var internalText: String?

    /// Overridden to return masked text for external access
    override var text: String? {
        get {
            return "****"
        }
        set {
            super.text = newValue
        }
    }
}
