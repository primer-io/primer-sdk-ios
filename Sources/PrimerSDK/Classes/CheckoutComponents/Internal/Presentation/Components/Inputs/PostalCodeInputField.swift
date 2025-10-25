//
//  PostalCodeInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for postal code input with validation and consistent styling
/// matching the card form field validation timing patterns.
@available(iOS 15.0, *)
struct PostalCodeInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// Country code for validation (optional)
    let countryCode: String?

    /// The card form scope for state management
    let scope: any PrimerCardFormScope

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?
    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The postal code entered by the user
    @State private var postalCode: String = ""

    /// The validation state of the postal code
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

    /// Country-specific keyboard type
    private var keyboardTypeForCountry: UIKeyboardType {
        // US ZIP codes are numeric
        if countryCode == "US" {
            return .numberPad
        }
        // Default to alphanumeric for other countries
        return .default
    }

    // MARK: - Initialization

    /// Creates a new PostalCodeInputField with comprehensive customization support
    init(
        label: String?,
        placeholder: String,
        countryCode: String? = nil,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.countryCode = countryCode
        self.scope = scope
        self.styling = styling
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
            // Label with custom styling support
            if let label = label {
                Text(label)
                    .primerLabelStyle(styling: styling, tokens: tokens)
                    
            }

            // Postal code input field with ZStack architecture
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
                        PostalCodeTextField(
                            postalCode: $postalCode,
                            isValid: $isValid,
                            errorMessage: $errorMessage,
                            isFocused: $isFocused,
                            placeholder: placeholder,
                            countryCode: countryCode,
                            keyboardType: keyboardTypeForCountry,
                            styling: styling,
                            validationService: validationService,
                            scope: scope
                        )
                        .primerInputPadding(styling: styling, tokens: tokens, errorPresent: errorMessage != nil)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: $postalCode)
                            .keyboardType(keyboardTypeForCountry)
                            .autocapitalization(.allCharacters)
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
            logger.error(message: "DIContainer not available for PostalCodeInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for postal code input with focus-based validation
@available(iOS 15.0, *)
private struct PostalCodeTextField: UIViewRepresentable, LogReporter {
    @Binding var postalCode: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let countryCode: String?
    let keyboardType: UIKeyboardType
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: any PrimerCardFormScope

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
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = .allCharacters
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
        if textField.text != postalCode {
            textField.text = postalCode
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            postalCode: $postalCode,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            countryCode: countryCode,
            scope: scope
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var postalCode: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let countryCode: String?
        private let scope: any PrimerCardFormScope

        init(
            validationService: ValidationService,
            postalCode: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            countryCode: String?,
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self._postalCode = postalCode
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.countryCode = countryCode
            self.scope = scope
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
                self.scope.clearFieldError(.postalCode)
                // Don't set isValid = false immediately - let validation happen on text change or focus loss
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validatePostalCode()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = postalCode

            // Create new text
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)

            // Update state
            postalCode = newText
            scope.updatePostalCode(newText)

            // Simple validation while typing (don't show errors until focus loss)
            isValid = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            // Update scope validation state while typing
            if let scope = scope as? DefaultCardFormScope {
                scope.updatePostalCodeValidationState(isValid)
            }

            return false
        }

        private func validatePostalCode() {
            let trimmedPostalCode = postalCode.trimmingCharacters(in: .whitespacesAndNewlines)

            // Empty field handling - don't show errors for empty fields
            if trimmedPostalCode.isEmpty {
                isValid = false // Postal code is required
                errorMessage = nil // Never show error message for empty fields
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updatePostalCodeValidationState(false)
                }
                return
            }

            let result = validationService.validate(
                input: postalCode,
                with: PostalCodeRule(countryCode: countryCode)
            )

            isValid = result.isValid
            errorMessage = result.errorMessage

            // Update scope state based on validation
            if result.isValid {
                scope.clearFieldError(.postalCode)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updatePostalCodeValidationState(true)
                }
            } else if let message = result.errorMessage {
                scope.setFieldError(.postalCode, message: message, errorCode: result.errorCode)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updatePostalCodeValidationState(false)
                }
            }
        }
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
struct PostalCodeInputField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Basic States
                Group {
                    PostalCodeInputField(label: "Postal Code", placeholder: "Enter postal code", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    PostalCodeInputField(label: nil, placeholder: "Postal Code", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                }
                Divider()
                // MARK: - Country Format Examples
                Group {
                    Text("Country Format Examples").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    PostalCodeInputField(label: "US ZIP Code", placeholder: "90210", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    PostalCodeInputField(label: "UK Postcode", placeholder: "SW1A 1AA", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    PostalCodeInputField(label: "Canadian Postal Code", placeholder: "K1A 0B1", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    PostalCodeInputField(label: "German PLZ", placeholder: "10115", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    PostalCodeInputField(label: "Australian Postcode", placeholder: "2000", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                }
                Divider()
                // MARK: - Validation States
                Group {
                    Text("Validation States").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    PostalCodeInputField(label: "Valid Postal Code", placeholder: "90210", scope: MockCardFormScope(isValid: true))
                        .background(Color.gray.opacity(0.1))
                    PostalCodeInputField(label: "Invalid Postal Code", placeholder: "Enter valid code", scope: MockCardFormScope(isValid: false))
                        .background(Color.gray.opacity(0.1))
                }
                Divider()
                // MARK: - Styling Variations
                Group {
                    Text("Styling Variations").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    PostalCodeInputField(label: "Postal Code (Custom Light)", placeholder: "90210", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .body, textColor: .primary, backgroundColor: .gray.opacity(0.05), placeholderColor: .gray, borderWidth: 1))
                        .background(Color.gray.opacity(0.1))
                    PostalCodeInputField(label: "Postal Code (Dark Theme)", placeholder: "SW1A 1AA", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .body, textColor: .white, backgroundColor: .black.opacity(0.8), placeholderColor: .gray, borderWidth: 2))
                        .background(Color.gray.opacity(0.1))
                        .preferredColorScheme(.dark)
                    PostalCodeInputField(label: "Postal Code (Bold Style)", placeholder: "Enter code", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .title3, textColor: .primary, backgroundColor: .blue.opacity(0.1), borderWidth: 3))
                        .background(Color.gray.opacity(0.1))
                    PostalCodeInputField(label: "Postal Code (Monospaced)", placeholder: "90210", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .system(.body, design: .monospaced), textColor: .primary, backgroundColor: .clear, borderWidth: 1))
                        .background(Color.gray.opacity(0.1))
                }
                Divider()
                // MARK: - Size Variations
                Group {
                    Text("Size Variations").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    PostalCodeInputField(label: "Compact Postal Code", placeholder: "Code", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .caption, textColor: .primary, backgroundColor: .clear, borderWidth: 1))
                        .background(Color.gray.opacity(0.1))
                    PostalCodeInputField(label: "Large Postal Code", placeholder: "Enter your postal code", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .title2, textColor: .primary, backgroundColor: .clear, borderWidth: 2))
                        .background(Color.gray.opacity(0.1))
                }
            }.padding()
        }
        .environment(\.designTokens, nil)
        .environment(\.diContainer, nil)
        .previewDisplayName("Postal Code Input Field")
    }
}
#endif
