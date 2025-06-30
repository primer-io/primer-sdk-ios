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

    /// PrimerModifier for comprehensive styling customization
    let modifier: PrimerModifier

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

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Computed Properties

    /// Dynamic border color based on field state
    private var borderColor: Color {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return tokens?.primerColorBorderOutlinedError ?? .red
        } else if isFocused {
            return tokens?.primerColorBorderOutlinedFocus ?? .blue
        } else {
            return tokens?.primerColorBorderOutlinedDefault ?? Color(.systemGray4)
        }
    }

    // MARK: - Initialization

    /// Creates a new CVVInputField with comprehensive customization support
    internal init(
        label: String,
        placeholder: String,
        cardNetwork: CardNetwork,
        modifier: PrimerModifier = PrimerModifier(),
        onCvvChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.cardNetwork = cardNetwork
        self.modifier = modifier
        self.onCvvChange = onCvvChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: tokens?.primerSpaceSmall ?? 6) {
            // Label
            Text(label)
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 12, weight: .medium))
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            // CVV input field with ZStack architecture
            ZStack {
                // Background and border styling
                RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
                    .fill(tokens?.primerColorBackground ?? Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
                            .stroke(borderColor, lineWidth: 1)
                            .animation(.easeInOut(duration: 0.2), value: borderColor)
                    )
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: tokens?.primerSpaceXsmall ?? 2,
                        x: 0,
                        y: 1
                    )

                // Input field content
                HStack {
                    if let validationService = validationService {
                        CVVTextField(
                            cvv: $cvv,
                            isValid: $isValid,
                            errorMessage: $errorMessage,
                            isFocused: $isFocused,
                            placeholder: placeholder,
                            cardNetwork: cardNetwork,
                            validationService: validationService,
                            onCvvChange: onCvvChange,
                            onValidationChange: onValidationChange
                        )
                        .padding(.leading, tokens?.primerSpaceLarge ?? 16)
                        .padding(.trailing, errorMessage != nil ? (tokens?.primerSizeXxlarge ?? 60) : (tokens?.primerSpaceLarge ?? 16))
                        .padding(.vertical, tokens?.primerSpaceMedium ?? 12)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: $cvv)
                            .keyboardType(.numberPad)
                            .disabled(true)
                            .padding(.leading, tokens?.primerSpaceLarge ?? 16)
                            .padding(.trailing, tokens?.primerSpaceLarge ?? 16)
                            .padding(.vertical, tokens?.primerSpaceMedium ?? 12)
                    }

                    Spacer()
                }

                // Right side overlay (error icon)
                HStack {
                    Spacer()

                    if let errorMessage = errorMessage, !errorMessage.isEmpty {
                        // Error icon when validation fails
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: tokens?.primerSizeMedium ?? 20, height: tokens?.primerSizeMedium ?? 20)
                            .foregroundColor(tokens?.primerColorIconNegative ?? Color(red: 1.0, green: 0.45, blue: 0.47))
                            .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    }
                }
            }
            .frame(height: tokens?.primerSizeXxxlarge ?? 48)

            // Error message (always reserve space to prevent height changes)
            Text(errorMessage ?? " ")
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 11, weight: .regular))
                .foregroundColor(tokens?.primerColorTextNegative ?? .red)
                .padding(.top, tokens?.primerSpaceXsmall ?? 4)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 15) // Fixed height to prevent layout shifts
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
        }
        .primerModifier(modifier)
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
    @Binding var isFocused: Bool
    let placeholder: String
    let cardNetwork: CardNetwork
    let validationService: ValidationService
    let onCvvChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.borderStyle = .none
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular) // Design token compatible font
        textField.textContentType = .oneTimeCode // Help prevent autofill of wrong data
        textField.isSecureTextEntry = true // Mask CVV input

        // Set placeholder color to match design tokens (same as PrimerInputField)
        // Use Inter font or fallback to system font based on design tokens
        let placeholderFont: UIFont = {
            if let interFont = UIFont(name: "InterVariable", size: 16) {
                return interFont
            }
            return UIFont.systemFont(ofSize: 16, weight: .regular)
        }()
        
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.systemGray,
                .font: placeholderFont
            ]
        )

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
            isFocused: $isFocused,
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
        @Binding private var isFocused: Bool
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
            isFocused: Binding<Bool>,
            onCvvChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self.cardNetwork = cardNetwork
            self._cvv = cvv
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.onCvvChange = onCvvChange
            self.onValidationChange = onValidationChange
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
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
            // Empty field handling - don't show errors for empty fields
            let trimmedCVV = cvv.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedCVV.isEmpty {
                isValid = false // CVV is required
                errorMessage = nil // Never show error message for empty fields
                onValidationChange?(false)
                return
            }

            // Create CVVRule with the current card network for non-empty fields
            let cvvRule = CVVRule(cardNetwork: cardNetwork)
            let result = cvvRule.validate(cvv)

            isValid = result.isValid
            errorMessage = result.errorMessage
            onValidationChange?(result.isValid)
        }
    }
}
