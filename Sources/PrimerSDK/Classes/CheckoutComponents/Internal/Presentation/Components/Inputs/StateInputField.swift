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
struct StateInputField: View, LogReporter {
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

    /// The state entered by the user
    @State private var state: String = ""

    /// The validation state of the state
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    /// Creates a new StateInputField with comprehensive customization support
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
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $state,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
            if let validationService = validationService {
                StateTextField(
                    state: $state,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    isFocused: $isFocused,
                    placeholder: placeholder,
                    styling: styling,
                    validationService: validationService,
                    scope: scope,
                    tokens: tokens
                )
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $state)
                    .autocapitalization(.words)
                    .disabled(true)
            }
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
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: any PrimerCardFormScope
    let tokens: DesignTokens?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator

        textField.configurePrimerStyle(
            placeholder: placeholder,
            configuration: .standard,
            styling: styling,
            tokens: tokens,
            doneButtonTarget: context.coordinator,
            doneButtonAction: #selector(Coordinator.doneButtonTapped)
        )

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
            scope: scope
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var state: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let scope: any PrimerCardFormScope

        init(
            validationService: ValidationService,
            state: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self._state = state
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
                self.scope.clearFieldError(.state)
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
            scope.updateState(newText)

            // Simple validation while typing (don't show errors until focus loss)
            isValid = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            // Update scope validation state while typing
            if let scope = scope as? DefaultCardFormScope {
                scope.updateStateValidationState(isValid)
            }

            return false
        }

        private func validateState() {
            let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines)

            // Empty field handling - don't show errors for empty fields
            if trimmedState.isEmpty {
                isValid = false // State is required
                errorMessage = nil // Never show error message for empty fields
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateStateValidationState(false)
                }
                return
            }

            let result = validationService.validate(
                input: state,
                with: StateRule()
            )

            isValid = result.isValid
            errorMessage = result.errorMessage

            // Update scope state based on validation
            if result.isValid {
                scope.clearFieldError(.state)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateStateValidationState(true)
                }
            } else if let message = result.errorMessage {
                scope.setFieldError(.state, message: message, errorCode: result.errorCode)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateStateValidationState(false)
                }
            }
        }
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
struct StateInputField_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode
            VStack(spacing: 16) {
                // Default state
                StateInputField(
                    label: "State",
                    placeholder: "Enter state",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // No label
                StateInputField(
                    label: nil,
                    placeholder: "State",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                StateInputField(
                    label: "State with Error",
                    placeholder: "Enter valid state",
                    scope: MockCardFormScope(isValid: false)
                )
                .environment(\.diContainer, MockDIContainer(
                    validationService: MockValidationService(
                        shouldFailValidation: true,
                        errorMessage: "Please enter a valid state"
                    )
                ))
                .background(Color.gray.opacity(0.1))
            }
            .padding()
            .environment(\.designTokens, MockDesignTokens.light)
            .environment(\.diContainer, MockDIContainer())
            .previewDisplayName("Light Mode")

            // Dark mode
            VStack(spacing: 16) {
                // Default state
                StateInputField(
                    label: "State",
                    placeholder: "Enter state",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // No label
                StateInputField(
                    label: nil,
                    placeholder: "State",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                StateInputField(
                    label: "State with Error",
                    placeholder: "Enter valid state",
                    scope: MockCardFormScope(isValid: false)
                )
                .environment(\.diContainer, MockDIContainer(
                    validationService: MockValidationService(
                        shouldFailValidation: true,
                        errorMessage: "Please enter a valid state"
                    )
                ))
                .background(Color.gray.opacity(0.1))
            }
            .padding()
            .background(Color.black)
            .environment(\.designTokens, MockDesignTokens.dark)
            .environment(\.diContainer, MockDIContainer())
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif
