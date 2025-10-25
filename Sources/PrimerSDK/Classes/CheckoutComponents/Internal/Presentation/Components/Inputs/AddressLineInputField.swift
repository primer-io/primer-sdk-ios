//
//  AddressLineInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for address line input with validation and consistent styling
/// matching the card form field validation timing patterns.
@available(iOS 15.0, *)
struct AddressLineInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// Whether this field is required
    let isRequired: Bool

    /// The input element type for validation
    let inputType: PrimerInputElementType

    /// The card form scope for state management
    let scope: (any PrimerCardFormScope)?

    /// Callback when the address line changes
    let onAddressChange: ((String) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?
    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The address line entered by the user
    @State private var addressLine: String = ""

    /// The validation state
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Modifier Value Extraction
    // MARK: - Computed Properties

    /// Dynamic border color based on field state
    private var borderColor: Color {
        return primerInputBorderColor(
            errorMessage: errorMessage,
            isFocused: isFocused,
            styling: styling,
            tokens: tokens
        )
    }

    // MARK: - Initialization

    /// Creates a new AddressLineInputField with comprehensive customization support (scope-based)
    init(
        label: String?,
        placeholder: String,
        isRequired: Bool,
        inputType: PrimerInputElementType,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.inputType = inputType
        self.scope = scope
        self.styling = styling
        self.onAddressChange = nil
        self.onValidationChange = nil
    }

    /// Creates a new AddressLineInputField with comprehensive customization support (callback-based)
    init(
        label: String?,
        placeholder: String,
        isRequired: Bool,
        inputType: PrimerInputElementType,
        styling: PrimerFieldStyling? = nil,
        onAddressChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.inputType = inputType
        self.scope = nil
        self.styling = styling
        self.onAddressChange = onAddressChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
            // Label with custom styling support
            if let label = label {
                Text(label)
                    .primerLabelStyle(styling: styling, tokens: tokens)
                    
            }

            // Address input field with ZStack architecture
            ZStack {
                // Background and border styling with gradient-aware hierarchy
                // Background and border styling with custom styling support
                Color.clear
                    .primerInputFieldBorder(
                        cornerRadius: PrimerRadius.small(tokens: tokens),
                        backgroundColor: styling?.backgroundColor ?? PrimerCheckoutColors.background(tokens: tokens),
                        borderColor: borderColor,
                        borderWidth: styling?.borderWidth ?? PrimerBorderWidth.standard,
                        animationValue: isFocused
                    )

                // Input field content
                HStack {
                    if let validationService = validationService {
                        AddressLineTextField(
                            addressLine: $addressLine,
                            isValid: $isValid,
                            errorMessage: $errorMessage,
                            isFocused: $isFocused,
                            placeholder: placeholder,
                            isRequired: isRequired,
                            inputType: inputType,
                            styling: styling,
                            validationService: validationService,
                            scope: scope,
                            onAddressChange: onAddressChange,
                            onValidationChange: onValidationChange
                        )
                        .primerInputPadding(styling: styling, tokens: tokens, errorPresent: errorMessage != nil)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: $addressLine)
                            .autocapitalization(.words)
                            .disabled(true)
                            .padding(.leading, styling?.padding?.leading ?? PrimerSpacing.large(tokens: tokens))
                            .padding(.trailing, styling?.padding?.trailing ?? PrimerSpacing.large(tokens: tokens))
                            .padding(.vertical, styling?.padding?.top ?? PrimerSpacing.medium(tokens: tokens))
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
                            .primerErrorIconStyle(tokens: tokens)
                    }
                }
            }
            .primerInputFieldHeight(styling: styling, tokens: tokens)

            // Error message (always reserve space to prevent height changes)
            Text(errorMessage ?? " ")
                .primerErrorMessageStyle(tokens: tokens)
                
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(AnimationConstants.errorAnimation, value: errorMessage != nil)
        }
        .onAppear {
            setupValidationService()
        }
    }

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for AddressLineInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for address line input with focus-based validation
@available(iOS 15.0, *)
private struct AddressLineTextField: UIViewRepresentable, LogReporter {
    @Binding var addressLine: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let isRequired: Bool
    let inputType: PrimerInputElementType
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: (any PrimerCardFormScope)?
    let onAddressChange: ((String) -> Void)?
    let onValidationChange: ((Bool) -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.borderStyle = .none
        // Apply custom font or use system default
        if let customFont = styling?.font {
            textField.font = UIFont(customFont)
        } else {
            textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }

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
        let accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: PrimerComponentHeight.keyboardAccessory))
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
        if textField.text != addressLine {
            textField.text = addressLine
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            addressLine: $addressLine,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            isRequired: isRequired,
            inputType: inputType,
            scope: scope,
            onAddressChange: onAddressChange,
            onValidationChange: onValidationChange
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var addressLine: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let isRequired: Bool
        private let inputType: PrimerInputElementType
        private let scope: (any PrimerCardFormScope)?
        private let onAddressChange: ((String) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?

        init(
            validationService: ValidationService,
            addressLine: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            isRequired: Bool,
            inputType: PrimerInputElementType,
            scope: (any PrimerCardFormScope)?,
            onAddressChange: ((String) -> Void)?,
            onValidationChange: ((Bool) -> Void)?
        ) {
            self.validationService = validationService
            self._addressLine = addressLine
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.isRequired = isRequired
            self.inputType = inputType
            self.scope = scope
            self.onAddressChange = onAddressChange
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
            validateAddress()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = addressLine

            // Create new text
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)

            // Update state
            addressLine = newText

            // Update scope or use callback
            if let scope = scope {
                switch inputType {
                case .addressLine1:
                    scope.updateAddressLine1(newText)
                case .addressLine2:
                    scope.updateAddressLine2(newText)
                default:
                    break
                }
            } else {
                onAddressChange?(newText)
            }

            // Simple validation while typing (don't show errors until focus loss)
            if isRequired {
                isValid = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            } else {
                isValid = true // Optional fields are always valid while typing
            }

            // Update scope validation state while typing
            if let scope = scope as? DefaultCardFormScope {
                switch inputType {
                case .addressLine1:
                    scope.updateAddressLine1ValidationState(isValid)
                case .addressLine2:
                    scope.updateAddressLine2ValidationState(isValid)
                default:
                    break
                }
            }

            return false
        }

        private func validateAddress() {
            let trimmedAddress = addressLine.trimmingCharacters(in: .whitespacesAndNewlines)

            // Empty field handling - don't show errors for empty fields
            if trimmedAddress.isEmpty {
                isValid = isRequired ? false : true // Required fields are invalid when empty, optional fields are valid
                errorMessage = nil // Never show error message for empty fields
                onValidationChange?(isValid)

                // Clear any scope errors for empty fields
                scope?.clearFieldError(inputType)

                // Update scope validation state for empty fields
                if let scope = scope as? DefaultCardFormScope {
                    switch inputType {
                    case .addressLine1:
                        scope.updateAddressLine1ValidationState(isValid)
                    case .addressLine2:
                        scope.updateAddressLine2ValidationState(isValid)
                    default:
                        break
                    }
                }
                return
            }

            // Convert PrimerInputElementType to ValidationError.InputElementType
            let elementType: ValidationError.InputElementType = {
                switch inputType {
                case .addressLine1:
                    return .addressLine1
                case .addressLine2:
                    return .addressLine2
                default:
                    return .addressLine1
                }
            }()

            let result = validationService.validate(
                input: addressLine,
                with: AddressRule(inputElementType: elementType, isRequired: isRequired)
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
                        case .addressLine1:
                            scope.updateAddressLine1ValidationState(true)
                        case .addressLine2:
                            scope.updateAddressLine2ValidationState(true)
                        default:
                            break
                        }
                    }
                } else if let message = result.errorMessage {
                    scope.setFieldError(inputType, message: message, errorCode: result.errorCode)
                    // Update scope validation state
                    if let scope = scope as? DefaultCardFormScope {
                        switch inputType {
                        case .addressLine1:
                            scope.updateAddressLine1ValidationState(false)
                        case .addressLine2:
                            scope.updateAddressLine2ValidationState(false)
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
struct AddressLineInputField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Basic States
                Group {
                    // Address Line 1 (Required)
                    AddressLineInputField(
                        label: "Address Line 1",
                        placeholder: "Street address",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope()
                    )
                    .background(Color.gray.opacity(0.1))

                    // Address Line 2 (Optional)
                    AddressLineInputField(
                        label: "Address Line 2 (Optional)",
                        placeholder: "Apt, suite, unit, etc.",
                        isRequired: false,
                        inputType: .addressLine2,
                        scope: MockCardFormScope()
                    )
                    .background(Color.gray.opacity(0.1))

                    // No label
                    AddressLineInputField(
                        label: nil,
                        placeholder: "Enter address",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope()
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - Address Format Examples
                Group {
                    Text("Address Format Examples")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // US Street Address
                    AddressLineInputField(
                        label: "US Street Address",
                        placeholder: "123 Main Street",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope()
                    )
                    .background(Color.gray.opacity(0.1))

                    // Apartment/Unit
                    AddressLineInputField(
                        label: "Apartment/Unit",
                        placeholder: "Apt 4B",
                        isRequired: false,
                        inputType: .addressLine2,
                        scope: MockCardFormScope()
                    )
                    .background(Color.gray.opacity(0.1))

                    // UK Address
                    AddressLineInputField(
                        label: "UK Address",
                        placeholder: "10 Downing Street",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope()
                    )
                    .background(Color.gray.opacity(0.1))

                    // Building Name
                    AddressLineInputField(
                        label: "Building Name",
                        placeholder: "Empire State Building",
                        isRequired: false,
                        inputType: .addressLine2,
                        scope: MockCardFormScope()
                    )
                    .background(Color.gray.opacity(0.1))

                    // PO Box
                    AddressLineInputField(
                        label: "PO Box",
                        placeholder: "PO Box 1234",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope()
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - Validation States
                Group {
                    Text("Validation States")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Valid required field
                    AddressLineInputField(
                        label: "Valid Address (Required)",
                        placeholder: "123 Main St",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope(isValid: true)
                    )
                    .background(Color.gray.opacity(0.1))

                    // Invalid required field
                    AddressLineInputField(
                        label: "Invalid Address (Required)",
                        placeholder: "Enter valid address",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope(isValid: false)
                    )
                    .background(Color.gray.opacity(0.1))

                    // Optional field (always valid when empty)
                    AddressLineInputField(
                        label: "Optional Address",
                        placeholder: "Additional address info",
                        isRequired: false,
                        inputType: .addressLine2,
                        scope: MockCardFormScope()
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - Styling Variations
                Group {
                    Text("Styling Variations")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Light theme with custom styling
                    AddressLineInputField(
                        label: "Address (Custom Light)",
                        placeholder: "123 Main Street",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope(),
                        styling: PrimerFieldStyling(
                            font: .body,
                            textColor: .primary,
                            backgroundColor: .gray.opacity(0.05),
                            placeholderColor: .gray,
                            borderWidth: 1
                        )
                    )
                    .background(Color.gray.opacity(0.1))

                    // Dark theme styling
                    AddressLineInputField(
                        label: "Address (Dark Theme)",
                        placeholder: "456 Oak Avenue",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope(),
                        styling: PrimerFieldStyling(
                            font: .body,
                            textColor: .white,
                            backgroundColor: .black.opacity(0.8),
                            placeholderColor: .gray,
                            borderWidth: 2
                        )
                    )
                    .background(Color.gray.opacity(0.1))
                    .preferredColorScheme(.dark)

                    // Bold/prominent styling
                    AddressLineInputField(
                        label: "Address (Bold Style)",
                        placeholder: "Enter street address",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope(),
                        styling: PrimerFieldStyling(
                            font: .title3,
                            textColor: .primary,
                            backgroundColor: .blue.opacity(0.1),
                            borderWidth: 3
                        )
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - Size Variations
                Group {
                    Text("Size Variations")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    AddressLineInputField(
                        label: "Compact Address",
                        placeholder: "Address",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope(),
                        styling: PrimerFieldStyling(
                            font: .caption,
                            textColor: .primary,
                            backgroundColor: .clear,
                            borderWidth: 1
                        )
                    )
                    .background(Color.gray.opacity(0.1))

                    AddressLineInputField(
                        label: "Large Address",
                        placeholder: "Enter your street address",
                        isRequired: true,
                        inputType: .addressLine1,
                        scope: MockCardFormScope(),
                        styling: PrimerFieldStyling(
                            font: .title2,
                            textColor: .primary,
                            backgroundColor: .clear,
                            borderWidth: 2
                        )
                    )
                    .background(Color.gray.opacity(0.1))
                }
            }
            .padding()
        }
        .environment(\.designTokens, nil)
        .environment(\.diContainer, nil)
        .previewDisplayName("Address Line Input Field")
    }
}
#endif
