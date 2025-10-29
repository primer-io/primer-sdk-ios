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
struct CardholderNameInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// The card form scope for state management
    let scope: any PrimerCardFormScope

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?

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
    // MARK: - Computed Properties

    /// Dynamic border color based on field state
    private var borderColor: Color {
        let color: Color
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            color = styling?.errorBorderColor ?? tokens?.primerColorBorderOutlinedError ?? .red
        } else if isFocused {
            color = styling?.focusedBorderColor ?? tokens?.primerColorBorderOutlinedFocus ?? .blue
        } else {
            color = styling?.borderColor ?? tokens?.primerColorBorderOutlinedDefault ?? Color(FigmaDesignConstants.inputFieldBorderColor)
        }
        return color
    }

    // MARK: - Initialization

    /// Creates a new CardholderNameInputField with comprehensive customization support
    init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
        self.styling = styling
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaDesignConstants.labelInputSpacing) {
            // Label with custom styling support
            if let label = label {
                Text(label)
                    .font(styling?.labelFont ?? (tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 12, weight: .medium)))
                    .foregroundColor(styling?.labelColor ?? tokens?.primerColorTextSecondary ?? .secondary)
            }

            // Cardholder name input field with ZStack architecture
            ZStack {
                // Background and border styling with custom styling support
                RoundedRectangle(cornerRadius: styling?.cornerRadius ?? FigmaDesignConstants.inputFieldRadius)
                    .fill(styling?.backgroundColor ?? tokens?.primerColorBackground ?? .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: styling?.cornerRadius ?? FigmaDesignConstants.inputFieldRadius)
                            .stroke(borderColor, lineWidth: styling?.borderWidth ?? 1)
                            .animation(.easeInOut(duration: 0.2), value: isFocused)
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
                            styling: styling,
                            validationService: validationService,
                            scope: scope
                        )
                        .padding(.leading, styling?.padding?.leading ?? tokens?.primerSpaceLarge ?? 16)
                        .padding(.trailing, errorMessage != nil ?
                                    (tokens?.primerSizeXxlarge ?? 60) :
                                    (styling?.padding?.trailing ?? tokens?.primerSpaceLarge ?? 16))
                        .padding(.vertical, styling?.padding?.top ?? tokens?.primerSpaceMedium ?? 12)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: $cardholderName)
                            .keyboardType(.default)
                            .autocapitalization(.words)
                            .disabled(true)
                            .padding(.leading, styling?.padding?.leading ?? tokens?.primerSpaceLarge ?? 16)
                            .padding(.trailing, styling?.padding?.trailing ?? tokens?.primerSpaceLarge ?? 16)
                            .padding(.vertical, styling?.padding?.top ?? tokens?.primerSpaceMedium ?? 12)
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
                            .foregroundColor(tokens?.primerColorIconNegative ?? .defaultIconNegative)
                            .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    }
                }
            }
            .frame(height: styling?.fieldHeight ?? FigmaDesignConstants.inputFieldHeight)

            // Error message (always reserve space to prevent height changes)
            Text(errorMessage ?? " ")
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 11, weight: .regular))
                .foregroundColor(tokens?.primerColorTextNegative ?? .red)
                .padding(.top, tokens?.primerSpaceXsmall ?? 4)
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
        }
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
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: any PrimerCardFormScope

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.borderStyle = .none
        // Apply custom font or use system default
        // MARK: - Dynamic Type Support
        if let customFont = styling?.font {
            textField.font = UIFont(customFont)
        } else {
            let baseSize: CGFloat = 16
            let metrics = UIFontMetrics(forTextStyle: .body)
            let scaledSize = metrics.scaledValue(for: baseSize)
            textField.font = UIFont.systemFont(ofSize: scaledSize, weight: .regular)
        }
        textField.adjustsFontForContentSizeCategory = true

        textField.backgroundColor = .clear

        // Apply custom text color if provided
        if let textColor = styling?.textColor {
            textField.textColor = UIColor(textColor)
        }
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .done

        // Apply custom placeholder styling or use defaults
        let placeholderFont: UIFont = {
            if let customFont = styling?.font {
                return UIFont(customFont)
            } else if let interFont = UIFont(name: "InterVariable", size: 16) {
                return interFont
            }
            return UIFont.systemFont(ofSize: 16, weight: .regular)
        }()

        let placeholderColor = styling?.placeholderColor != nil ? UIColor(styling!.placeholderColor!) : UIColor.systemGray

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: placeholderColor,
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

        // MARK: - Accessibility Configuration
        textField.accessibilityIdentifier = AccessibilityIdentifiers.CheckoutComponents.CardForm.cardholderName
        textField.accessibilityLabel = placeholder
        textField.accessibilityHint = AccessibilityStrings.cardholderNameHint

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
            scope: scope
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var cardholderName: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let scope: any PrimerCardFormScope

        init(
            validationService: ValidationService,
            cardholderName: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self._cardholderName = cardholderName
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.scope = scope
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
                self.scope.clearFieldError(.cardholderName)
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
            scope.updateCardholderName(newText)

            // Simple validation while typing
            isValid = newText.count >= 2

            // Update scope validation state while typing
            if let scope = scope as? DefaultCardFormScope {
                scope.updateCardholderNameValidationState(isValid)
            }

            return false
        }

        private func validateCardholderName() {
            let trimmedName = cardholderName.trimmingCharacters(in: .whitespacesAndNewlines)

            // Empty field handling - don't show errors for empty fields
            if trimmedName.isEmpty {
                isValid = false // Cardholder name is required
                errorMessage = nil // Never show error message for empty fields
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardholderNameValidationState(false)
                }
                return
            }

            let result = validationService.validate(
                input: cardholderName,
                with: CardholderNameRule()
            )

            isValid = result.isValid
            errorMessage = result.errorMessage

            // Update scope state based on validation
            if result.isValid {
                scope.clearFieldError(.cardholderName)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardholderNameValidationState(true)
                }
            } else {
                if let message = result.errorMessage {
                    scope.setFieldError(.cardholderName, message: message, errorCode: result.errorCode)
                }
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardholderNameValidationState(false)
                }
            }

        }
    }
}
