//
//  CVVInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for credit card CVV input with validation based on card network.
@available(iOS 15.0, *)
internal struct CVVInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String

    /// Placeholder text for the input field
    let placeholder: String

    /// The card network to validate against (determines CVV length requirements)
    let cardNetwork: CardNetwork

    /// Callback when the CVV changes
    let onCvvChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The CVV entered by the user
    @State private var cvv: String = ""

    /// The validation state of the CVV
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

            // CVV input field
            if let validationService = validationService {
                CVVTextField(
                    cvv: $cvv,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    placeholder: placeholder,
                    cardNetwork: cardNetwork,
                    validationService: validationService,
                    onCvvChange: onCvvChange,
                    onValidationChange: onValidationChange
                )
                .padding()
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $cvv)
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
            logger.error(message: "DIContainer not available for CVVInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for CVV text field
@available(iOS 15.0, *)
private struct CVVTextField: UIViewRepresentable, LogReporter {
    @Binding var cvv: String
    @Binding var isValid: Bool?
    @Binding var errorMessage: String?
    let placeholder: String
    let cardNetwork: CardNetwork
    let validationService: ValidationService
    let onCvvChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.textContentType = .oneTimeCode // Help prevent autofill of wrong data
        textField.isSecureTextEntry = true // Mask CVV input

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
        if textField.text != cvv {
            textField.text = cvv
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            cardNetwork: cardNetwork,
            cvv: $cvv,
            isValid: $isValid,
            errorMessage: $errorMessage,
            onCvvChange: onCvvChange,
            onValidationChange: onValidationChange
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        private let cardNetwork: CardNetwork
        @Binding private var cvv: String
        @Binding private var isValid: Bool?
        @Binding private var errorMessage: String?
        private let onCvvChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?

        private var expectedCVVLength: Int {
            cardNetwork.validation?.code.length ?? 3
        }

        init(
            validationService: ValidationService,
            cardNetwork: CardNetwork,
            cvv: Binding<String>,
            isValid: Binding<Bool?>,
            errorMessage: Binding<String?>,
            onCvvChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self.cardNetwork = cardNetwork
            self._cvv = cvv
            self._isValid = isValid
            self._errorMessage = errorMessage
            self.onCvvChange = onCvvChange
            self.onValidationChange = onValidationChange
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            errorMessage = nil
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            validateCVV()
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = cvv

            // Create the new text
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)

            // Only allow numbers
            if !string.isEmpty && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
                return false
            }

            // Check max length
            if newText.count > expectedCVVLength {
                return false
            }

            // Update state
            cvv = newText
            onCvvChange?(newText)

            // Validate while typing
            if newText.count == expectedCVVLength {
                validateCVV()
            } else {
                isValid = nil
                errorMessage = nil
            }

            return false
        }

        private func validateCVV() {
            // Create CVVRule with the current card network
            let cvvRule = CVVRule(cardNetwork: cardNetwork)
            let result = cvvRule.validate(cvv)

            isValid = result.isValid
            errorMessage = result.errors.first?.message
            onValidationChange?(result.isValid)
        }
    }
}
