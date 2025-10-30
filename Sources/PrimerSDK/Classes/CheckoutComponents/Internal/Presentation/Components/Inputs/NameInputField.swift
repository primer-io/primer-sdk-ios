//
//  NameInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for first/last name input with validation and consistent styling
/// matching the card form field validation timing patterns.
@available(iOS 15.0, *)
struct NameInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// The input element type for validation
    let inputType: PrimerInputElementType

    /// The card form scope for state management
    let scope: (any PrimerCardFormScope)?

    /// Callback when the name changes
    let onNameChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?
    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The name entered by the user
    @State private var name: String = ""

    /// The validation state of the name
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    /// Creates a new NameInputField with comprehensive customization support (scope-based)
    init(
        label: String?,
        placeholder: String,
        inputType: PrimerInputElementType,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.inputType = inputType
        self.scope = scope
        self.styling = styling
        self.onNameChange = nil
        self.onValidationChange = nil
    }

    /// Creates a new NameInputField with comprehensive customization support (callback-based)
    init(
        label: String?,
        placeholder: String,
        inputType: PrimerInputElementType,
        styling: PrimerFieldStyling? = nil,
        onNameChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.inputType = inputType
        self.scope = nil
        self.styling = styling
        self.onNameChange = onNameChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $name,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
            if let validationService = validationService {
                NameTextField(
                    name: $name,
                    isValid: $isValid,
                    errorMessage: $errorMessage,
                    isFocused: $isFocused,
                    placeholder: placeholder,
                    inputType: inputType,
                    styling: styling,
                    validationService: validationService,
                    scope: scope,
                    onNameChange: onNameChange,
                    onValidationChange: onValidationChange,
                    tokens: tokens
                )
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $name)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .disabled(true)
            }
        }
        .onAppear {
            setupValidationService()
        }
    }

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for NameInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for name input with focus-based validation
@available(iOS 15.0, *)
private struct NameTextField: UIViewRepresentable, LogReporter {
    @Binding var name: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let inputType: PrimerInputElementType
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: (any PrimerCardFormScope)?
    let onNameChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
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
        if textField.text != name {
            textField.text = name
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            name: $name,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            inputType: inputType,
            scope: scope,
            onNameChange: onNameChange,
            onValidationChange: onValidationChange
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var name: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let inputType: PrimerInputElementType
        private let scope: (any PrimerCardFormScope)?
        private let onNameChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?

        init(
            validationService: ValidationService,
            name: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            inputType: PrimerInputElementType,
            scope: (any PrimerCardFormScope)?,
            onNameChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._name = name
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.inputType = inputType
            self.scope = scope
            self.onNameChange = onNameChange
            self.onValidationChange = onValidationChange
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
                self.scope?.clearFieldError(self.inputType)
                // Don't set isValid = false immediately - let validation happen on text change or focus loss
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validateName()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = name

            // Create new text
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)

            // Update state
            name = newText

            // Update scope or use callback
            if let scope = scope {
                switch inputType {
                case .firstName:
                    scope.updateFirstName(newText)
                case .lastName:
                    scope.updateLastName(newText)
                case .phoneNumber:
                    scope.updatePhoneNumber(newText)
                default:
                    break
                }
            } else {
                onNameChange?(newText)
            }

            // Simple validation while typing (don't show errors until focus loss)
            isValid = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            // Update scope validation state while typing
            if let scope = scope as? DefaultCardFormScope {
                switch inputType {
                case .firstName:
                    scope.updateFirstNameValidationState(isValid)
                case .lastName:
                    scope.updateLastNameValidationState(isValid)
                default:
                    break
                }
            }

            return false
        }

        private func validateName() {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

            // Empty field handling - don't show errors for empty fields
            if trimmedName.isEmpty {
                isValid = false // Name fields are required
                errorMessage = nil // Never show error message for empty fields
                onValidationChange?(false)
                // Update scope validation state for empty fields
                if let scope = scope as? DefaultCardFormScope {
                    switch inputType {
                    case .firstName:
                        scope.updateFirstNameValidationState(false)
                    case .lastName:
                        scope.updateLastNameValidationState(false)
                    default:
                        break
                    }
                }
                return
            }

            // Convert PrimerInputElementType to ValidationError.InputElementType
            let elementType: ValidationError.InputElementType = {
                switch inputType {
                case .firstName:
                    return .firstName
                case .lastName:
                    return .lastName
                default:
                    return .firstName
                }
            }()

            let result = validationService.validate(
                input: name,
                with: NameRule(inputElementType: elementType)
            )

            isValid = result.isValid
            errorMessage = result.errorMessage
            onValidationChange?(result.isValid)

            // Update scope state based on validation
            if let scope = scope {
                if result.isValid {
                    scope.clearFieldError(inputType)
                    // Update scope validation state
                    if let scope = scope as? DefaultCardFormScope {
                        switch inputType {
                        case .firstName:
                            scope.updateFirstNameValidationState(true)
                        case .lastName:
                            scope.updateLastNameValidationState(true)
                        default:
                            break
                        }
                    }
                } else if let message = result.errorMessage {
                    scope.setFieldError(inputType, message: message, errorCode: result.errorCode)
                    // Update scope validation state
                    if let scope = scope as? DefaultCardFormScope {
                        switch inputType {
                        case .firstName:
                            scope.updateFirstNameValidationState(false)
                        case .lastName:
                            scope.updateLastNameValidationState(false)
                        default:
                            break
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
struct NameInputField_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode
            VStack(spacing: 16) {
                // Default state
                NameInputField(
                    label: "First Name",
                    placeholder: "Jane",
                    inputType: .firstName,
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // No label
                NameInputField(
                    label: nil,
                    placeholder: "Name",
                    inputType: .firstName,
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                NameInputField(
                    label: "Name with Error",
                    placeholder: "Enter valid name",
                    inputType: .firstName,
                    scope: MockCardFormScope(isValid: false)
                )
                .environment(\.diContainer, MockDIContainer(
                    validationService: MockValidationService(
                        shouldFailValidation: true,
                        errorMessage: "Please enter a valid name"
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
                NameInputField(
                    label: "First Name",
                    placeholder: "Jane",
                    inputType: .firstName,
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // No label
                NameInputField(
                    label: nil,
                    placeholder: "Name",
                    inputType: .firstName,
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                NameInputField(
                    label: "Name with Error",
                    placeholder: "Enter valid name",
                    inputType: .firstName,
                    scope: MockCardFormScope(isValid: false)
                )
                .environment(\.diContainer, MockDIContainer(
                    validationService: MockValidationService(
                        shouldFailValidation: true,
                        errorMessage: "Please enter a valid name"
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
