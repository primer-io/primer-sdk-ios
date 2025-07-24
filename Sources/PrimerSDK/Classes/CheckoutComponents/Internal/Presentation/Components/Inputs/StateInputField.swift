//
//  StateInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for state/province input with validation and consistent styling
/// matching the card form field validation timing patterns.
@available(iOS 15.0, *)
internal struct StateInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String

    /// Placeholder text for the input field
    let placeholder: String

    /// Callback when the state changes
    let onStateChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?
    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The state entered by the user
    @State private var state: String = ""

    /// The validation state of the state
    @State private var isValid: Bool = false

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
            return tokens?.primerColorBorderOutlinedDefault ?? Color(FigmaDesignConstants.inputFieldBorderColor)
        }
    }

    // MARK: - Initialization

    /// Creates a new StateInputField with comprehensive customization support
    internal init(
        label: String,
        placeholder: String,
        onStateChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.onStateChange = onStateChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaDesignConstants.labelInputSpacing) {
            // Label
            Text(label)
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 12, weight: .medium))
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            // State input field with ZStack architecture
            ZStack {
                // Background and border styling with gradient-aware hierarchy
                Group {
                    if true {
                        // Only apply manual background when no gradient is present
                        RoundedRectangle(cornerRadius: FigmaDesignConstants.inputFieldRadius)
                            .fill(tokens?.primerColorBackground ?? .white)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: FigmaDesignConstants.inputFieldRadius)
                        .stroke(borderColor, lineWidth: 1)
                        .animation(.easeInOut(duration: 0.2), value: borderColor)
                )

                // Input field content
                HStack {
                    if let validationService = validationService {
                        StateTextField(
                            state: $state,
                            isValid: $isValid,
                            errorMessage: $errorMessage,
                            isFocused: $isFocused,
                            placeholder: placeholder,
                            validationService: validationService,
                            onStateChange: onStateChange,
                            onValidationChange: onValidationChange
                        )
                        .padding(.leading, tokens?.primerSpaceLarge ?? 16)
                        .padding(.trailing, errorMessage != nil ? (tokens?.primerSizeXxlarge ?? 60) : (tokens?.primerSpaceLarge ?? 16))
                        .padding(.vertical, tokens?.primerSpaceMedium ?? 12)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: $state)
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
            logger.error(message: "DIContainer not available for StateInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for state input with focus-based validation
@available(iOS 15.0, *)
private struct StateTextField: UIViewRepresentable, LogReporter {
    @Binding var state: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let validationService: ValidationService
    let onStateChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .done

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
        if textField.text != state {
            textField.text = state
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            state: $state,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            onStateChange: onStateChange,
            onValidationChange: onValidationChange
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var state: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let onStateChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?

        init(
            validationService: ValidationService,
            state: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            onStateChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._state = state
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.onStateChange = onStateChange
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
            validateState()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = state

            // Create new text
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)

            // Update state
            state = newText
            onStateChange?(newText)

            // Simple validation while typing (don't show errors until focus loss)
            isValid = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            return false
        }

        private func validateState() {
            let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines)

            // Empty field handling - don't show errors for empty fields
            if trimmedState.isEmpty {
                isValid = false // State is required
                errorMessage = nil // Never show error message for empty fields
                onValidationChange?(false)
                return
            }

            let result = validationService.validate(
                input: state,
                with: StateRule()
            )

            isValid = result.isValid
            errorMessage = result.errorMessage
            onValidationChange?(result.isValid)
        }
    }
}
