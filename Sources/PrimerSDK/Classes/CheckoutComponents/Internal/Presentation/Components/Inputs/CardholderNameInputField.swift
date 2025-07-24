//
//  CardholderNameInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for cardholder name input with validation
/// and consistent styling with other card input fields.
@available(iOS 15.0, *)
internal struct CardholderNameInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String

    /// Placeholder text for the input field
    let placeholder: String

    /// Callback when the cardholder name changes
    let onCardholderNameChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    /// PrimerModifier for comprehensive styling customization
    let modifier: PrimerModifier

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

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    /// Unified modifier extraction using PrimerModifierExtractor
    private var modifierProps: PrimerModifierExtractor.ComputedProperties {
        PrimerModifierExtractor.computedProperties(modifier: modifier, tokens: tokens)
    }

    // MARK: - Computed Properties

    /// Dynamic border color based on field state
    private var borderColor: Color {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return tokens?.primerColorBorderOutlinedError ?? .red
        } else if isFocused {
            return tokens?.primerColorBorderOutlinedFocus ?? .blue
        } else {
            return tokens?.primerColorBorderOutlinedDefault ?? Color(FigmaDesignConstants.inputFieldBorderColor)
        }
    }

    // MARK: - Initialization

    /// Creates a new CardholderNameInputField with comprehensive customization support
    internal init(
        label: String,
        placeholder: String,
        modifier: PrimerModifier = PrimerModifier(),
        onCardholderNameChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.modifier = modifier
        self.onCardholderNameChange = onCardholderNameChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaDesignConstants.labelInputSpacing) {
            // Label with label-specific modifier targeting
            Text(label)
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 12, weight: .medium))
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .primerModifier(modifier, target: .labelOnly)

            // Cardholder name input field with ZStack architecture
            ZStack {
                // Background and border styling with gradient-aware hierarchy
                Group {
                    if !PrimerModifierExtractor.hasBackgroundGradient(modifier) {
                        // Only apply manual background when no gradient is present
                        RoundedRectangle(cornerRadius: modifierProps.effectiveCornerRadius)
                            .fill(modifierProps.effectiveBackgroundColor)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: modifierProps.effectiveCornerRadius)
                        .stroke(borderColor, lineWidth: 1)
                        .animation(.easeInOut(duration: 0.2), value: borderColor)
                )

                // Input field content
                HStack {
                    if let validationService = validationService {
                        CardholderNameTextField(
                            cardholderName: $cardholderName,
                            isValid: $isValid,
                            errorMessage: $errorMessage,
                            isFocused: $isFocused,
                            placeholder: placeholder,
                            validationService: validationService,
                            onCardholderNameChange: onCardholderNameChange,
                            onValidationChange: onValidationChange
                        )
                        .padding(.leading, tokens?.primerSpaceLarge ?? 16)
                        .padding(.trailing, errorMessage != nil ? (tokens?.primerSizeXxlarge ?? 60) : (tokens?.primerSpaceLarge ?? 16))
                        .padding(.vertical, tokens?.primerSpaceMedium ?? 12)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: $cardholderName)
                            .keyboardType(.default)
                            .autocapitalization(.words)
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
            .frame(height: FigmaDesignConstants.inputFieldHeight)
            .primerModifier(modifier, target: .inputOnly)

            // Error message (always reserve space to prevent height changes)
            Text(errorMessage ?? " ")
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 11, weight: .regular))
                .foregroundColor(tokens?.primerColorTextNegative ?? .red)
                .padding(.top, tokens?.primerSpaceXsmall ?? 4)
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
        }
        .primerModifier(modifier, target: .container)
        .onAppear {
            setupValidationService()
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
}

/// UIViewRepresentable wrapper for cardholder name input
@available(iOS 15.0, *)
private struct CardholderNameTextField: UIViewRepresentable, LogReporter {
    @Binding var cardholderName: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let validationService: ValidationService
    let onCardholderNameChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular) // Design token compatible font
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .done

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

        // Add a "Done" button to the keyboard using a custom view to avoid UIToolbar constraints
        let accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        accessoryView.backgroundColor = UIColor.systemGray6
        
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        doneButton.addTarget(context.coordinator, action: #selector(Coordinator.doneButtonTapped), for: .touchUpInside)
        
        accessoryView.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: accessoryView.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: accessoryView.centerYAnchor)
        ])
        
        textField.inputAccessoryView = accessoryView

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != cardholderName {
            textField.text = cardholderName
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            cardholderName: $cardholderName,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            onCardholderNameChange: onCardholderNameChange,
            onValidationChange: onValidationChange
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var cardholderName: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let onCardholderNameChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?

        init(
            validationService: ValidationService,
            cardholderName: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            onCardholderNameChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._cardholderName = cardholderName
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.onCardholderNameChange = onCardholderNameChange
            self.onValidationChange = onValidationChange
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
                // Don't set isValid = false immediately - let validation happen on text change or focus loss
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validateCardholderName()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = cardholderName

            // Create new text
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)

            // Validate allowed characters (letters, spaces, apostrophes, hyphens)
            if !string.isEmpty {
                let allowedCharacterSet = CharacterSet.letters.union(CharacterSet(charactersIn: " '-"))
                let characterSet = CharacterSet(charactersIn: string)
                if !allowedCharacterSet.isSuperset(of: characterSet) {
                    return false
                }
            }

            // Update state
            cardholderName = newText
            onCardholderNameChange?(newText)

            // Simple validation while typing
            isValid = newText.count >= 2

            return false
        }

        private func validateCardholderName() {
            let trimmedName = cardholderName.trimmingCharacters(in: .whitespacesAndNewlines)

            // Empty field handling - don't show errors for empty fields
            if trimmedName.isEmpty {
                isValid = false // Cardholder name is required
                errorMessage = nil // Never show error message for empty fields
                onValidationChange?(false)
                return
            }

            let result = validationService.validate(
                input: cardholderName,
                with: CardholderNameRule()
            )

            isValid = result.isValid
            errorMessage = result.errorMessage
            onValidationChange?(result.isValid)
        }
    }
}
