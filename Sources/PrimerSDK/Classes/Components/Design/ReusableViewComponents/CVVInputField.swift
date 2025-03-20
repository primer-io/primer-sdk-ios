//
//  CVVInputField.swift
//
//  Created by Boris on 20.3.25..
//

import SwiftUI
import UIKit

/// A SwiftUI component for credit card CVV input with validation based on card network.
@available(iOS 15.0, *)
struct CVVInputField: View {
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
            CVVTextField(
                cvv: $cvv,
                isValid: $isValid,
                errorMessage: $errorMessage,
                placeholder: placeholder,
                cardNetwork: cardNetwork
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
        return cvv
    }
}

/// An improved UIViewRepresentable wrapper for a CVV text field
@available(iOS 15.0, *)
struct CVVTextField: UIViewRepresentable {
    @Binding var cvv: String
    @Binding var isValid: Bool?
    @Binding var errorMessage: String?
    var placeholder: String
    var cardNetwork: CardNetwork

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

        print("🔤 Creating new CVV text field")

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
            print("🔄 Updating CVV text field: internalText='\(cvvTextField.internalText ?? "")' → cvv='\(cvv)'")
            cvvTextField.internalText = cvv
            cvvTextField.text = cvv
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CVVTextField
        var expectedCVVLength: Int = 3 // Default length, will be updated based on card type

        // Add a flag to prevent update cycles
        private var isUpdating = false

        init(_ parent: CVVTextField) {
            self.parent = parent
            super.init()
        }

        @objc func doneButtonTapped() {
            print("⌨️ Done button tapped")
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            print("⌨️ CVV field began editing")
            // Clear error message when user starts editing
            parent.errorMessage = nil
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            print("⌨️ CVV field ended editing")
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

            print("⌨️ CVV shouldChangeCharactersIn - range: \(range.location),\(range.length), replacement: '\(string)'")

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
            parent.cvv = newText
            isUpdating = false

            // Validate while typing
            validateCVVWhileTyping(newText)

            return false
        }

        // Validation while typing - keep it minimal during input
        private func validateCVVWhileTyping(_ cvv: String) {
            if cvv.isEmpty {
                parent.isValid = nil
                parent.errorMessage = nil
                return
            }

            // Check if all characters are numeric
            if !cvv.isNumeric {
                parent.isValid = false
                parent.errorMessage = "CVV must contain only numbers"
                return
            }

            // Check length based on card type
            if cvv.count == expectedCVVLength {
                parent.isValid = true
                parent.errorMessage = nil
            } else {
                parent.isValid = nil
                parent.errorMessage = nil
            }
        }

        // Full validation when field loses focus
        private func validateCVVFully(_ cvv: String) {
            if cvv.isEmpty {
                parent.isValid = false
                parent.errorMessage = "CVV cannot be blank"
                return
            }

            if !cvv.isNumeric {
                parent.isValid = false
                parent.errorMessage = "CVV must contain only numbers"
                return
            }

            if cvv.count != expectedCVVLength {
                parent.isValid = false
                parent.errorMessage = "CVV must be \(expectedCVVLength) digits"
                return
            }

            parent.isValid = true
            parent.errorMessage = nil
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

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
struct CVVInputField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CVVInputField(
                label: "CVV",
                placeholder: "123",
                cardNetwork: .visa,
                onValidationChange: { _ in }
            )
            .padding()

            CVVInputField(
                label: "Security Code",
                placeholder: "1234",
                cardNetwork: .amex,
                onValidationChange: { _ in }
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
