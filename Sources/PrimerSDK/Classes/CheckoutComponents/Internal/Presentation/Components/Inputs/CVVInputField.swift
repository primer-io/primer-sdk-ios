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
struct CVVInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// The card form scope for state management
    let scope: any PrimerCardFormScope

    /// The card network to validate against (determines CVV length requirements)
    let cardNetwork: CardNetwork

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?

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

    /// Creates a new CVVInputField with comprehensive customization support
    init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        cardNetwork: CardNetwork,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
        self.cardNetwork = cardNetwork
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

            // CVV input field with ZStack architecture
            ZStack {
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
                        CVVTextField(
                            cvv: $cvv,
                            isValid: $isValid,
                            errorMessage: $errorMessage,
                            isFocused: $isFocused,
                            placeholder: placeholder,
                            cardNetwork: cardNetwork,
                            styling: styling,
                            validationService: validationService,
                            scope: scope
                        )
                        .primerInputPadding(styling: styling, tokens: tokens, errorPresent: errorMessage != nil)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: $cvv)
                            .keyboardType(.numberPad)
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

                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: PrimerComponentHeight.errorMessage)
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(AnimationConstants.errorAnimation, value: errorMessage != nil)
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
    @Binding var isFocused: Bool
    let placeholder: String
    let cardNetwork: CardNetwork
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: any PrimerCardFormScope

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.borderStyle = .none
        // Apply custom font or use system default
        if let customFont = styling?.font {
            textField.font = UIFont(customFont)
        } else {
            textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }

        textField.textContentType = .oneTimeCode // Help prevent autofill of wrong data
        textField.isSecureTextEntry = true // Mask CVV input

        // Apply custom text color if provided
        if let textColor = styling?.textColor {
            textField.textColor = UIColor(textColor)
        }

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
            scope: scope
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        private let cardNetwork: CardNetwork
        @Binding private var cvv: String
        @Binding private var isValid: Bool?
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let scope: any PrimerCardFormScope

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
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self.cardNetwork = cardNetwork
            self._cvv = cvv
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
                self.scope.clearFieldError(.cvv)
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
            scope.updateCvv(newText)

            // Validate while typing
            if newText.count == expectedCVVLength {
                validateCVV()
            } else {
                isValid = nil
                errorMessage = nil
                // Update scope validation state for incomplete CVV
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCvvValidationState(false)
                }
            }

            return false
        }

        private func validateCVV() {
            // Empty field handling - don't show errors for empty fields
            let trimmedCVV = cvv.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedCVV.isEmpty {
                isValid = false // CVV is required
                errorMessage = nil // Never show error message for empty fields
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCvvValidationState(false)
                }
                return
            }

            // Create CVVRule with the current card network for non-empty fields
            let cvvRule = CVVRule(cardNetwork: cardNetwork)
            let result = cvvRule.validate(cvv)

            isValid = result.isValid
            errorMessage = result.errorMessage

            // Update scope state based on validation
            if result.isValid {
                scope.clearFieldError(.cvv)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCvvValidationState(true)
                }
            } else {
                if let message = result.errorMessage {
                    scope.setFieldError(.cvv, message: message, errorCode: result.errorCode)
                }
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCvvValidationState(false)
                }
            }
        }
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
struct CVVInputField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Basic States
                Group {
                    // Default empty state (Visa)
                    CVVInputField(
                        label: "CVV",
                        placeholder: "123",
                        scope: MockCardFormScope(),
                        cardNetwork: .visa
                    )
                    .background(Color.gray.opacity(0.1))

                    // No label (Mastercard)
                    CVVInputField(
                        label: nil,
                        placeholder: "CVV",
                        scope: MockCardFormScope(),
                        cardNetwork: .masterCard
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - Card Network Variations
                Group {
                    Text("Card Network Variations")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Visa - 3 digits
                    CVVInputField(
                        label: "Visa CVV (3 digits)",
                        placeholder: "123",
                        scope: MockCardFormScope(),
                        cardNetwork: .visa
                    )
                    .background(Color.gray.opacity(0.1))

                    // Mastercard - 3 digits
                    CVVInputField(
                        label: "Mastercard CVV (3 digits)",
                        placeholder: "456",
                        scope: MockCardFormScope(),
                        cardNetwork: .masterCard
                    )
                    .background(Color.gray.opacity(0.1))

                    // American Express - 4 digits
                    CVVInputField(
                        label: "Amex CID (4 digits)",
                        placeholder: "1234",
                        scope: MockCardFormScope(),
                        cardNetwork: .amex
                    )
                    .background(Color.gray.opacity(0.1))

                    // Discover - 3 digits
                    CVVInputField(
                        label: "Discover CVV (3 digits)",
                        placeholder: "789",
                        scope: MockCardFormScope(),
                        cardNetwork: .discover
                    )
                    .background(Color.gray.opacity(0.1))

                    // Unknown network - defaults to 3
                    CVVInputField(
                        label: "Unknown Network (3 digits)",
                        placeholder: "CVV",
                        scope: MockCardFormScope(),
                        cardNetwork: .unknown
                    )
                    .background(Color.gray.opacity(0.1))
                }

                Divider()

                // MARK: - Validation States
                Group {
                    Text("Validation States")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Valid state
                    CVVInputField(
                        label: "Valid CVV",
                        placeholder: "123",
                        scope: MockCardFormScope(isValid: true),
                        cardNetwork: .visa
                    )
                    .background(Color.gray.opacity(0.1))

                    // Invalid state
                    CVVInputField(
                        label: "Invalid CVV",
                        placeholder: "Enter valid CVV",
                        scope: MockCardFormScope(isValid: false),
                        cardNetwork: .visa
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
                    CVVInputField(
                        label: "CVV (Custom Light)",
                        placeholder: "123",
                        scope: MockCardFormScope(),
                        cardNetwork: .visa,
                        styling: PrimerFieldStyling(
                            font: .body,
                            textColor: .primary,
                            backgroundColor: .gray.opacity(0.05),
                            placeholderColor: .gray,
                            borderWidth: 1,
                        )
                    )
                    .background(Color.gray.opacity(0.1))

                    // Dark theme styling
                    CVVInputField(
                        label: "CVV (Dark Theme)",
                        placeholder: "123",
                        scope: MockCardFormScope(),
                        cardNetwork: .visa,
                        styling: PrimerFieldStyling(
                            font: .body,
                            textColor: .white,
                            backgroundColor: .black.opacity(0.8),
                            placeholderColor: .gray,
                            borderWidth: 2,
                        )
                    )
                    .background(Color.gray.opacity(0.1))
                    .preferredColorScheme(.dark)

                    // Bold/prominent styling
                    CVVInputField(
                        label: "CVV (Bold Style)",
                        placeholder: "CVV",
                        scope: MockCardFormScope(),
                        cardNetwork: .visa,
                        styling: PrimerFieldStyling(
                            font: .title3,
                            textColor: .primary,
                            backgroundColor: .blue.opacity(0.1),
                            borderWidth: 3
                        )
                    )
                    .background(Color.gray.opacity(0.1))

                    // Monospaced font for security codes
                    CVVInputField(
                        label: "CVV (Monospaced)",
                        placeholder: "123",
                        scope: MockCardFormScope(),
                        cardNetwork: .visa,
                        styling: PrimerFieldStyling(
                            font: .system(.body, design: .monospaced),
                            textColor: .primary,
                            backgroundColor: .clear,
                            borderWidth: 1
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

                    CVVInputField(
                        label: "Compact CVV",
                        placeholder: "CVV",
                        scope: MockCardFormScope(),
                        cardNetwork: .visa,
                        styling: PrimerFieldStyling(
                            font: .caption,
                            textColor: .primary,
                            backgroundColor: .clear,
                            borderWidth: 1
                        )
                    )
                    .background(Color.gray.opacity(0.1))

                    CVVInputField(
                        label: "Large CVV",
                        placeholder: "Security Code",
                        scope: MockCardFormScope(),
                        cardNetwork: .visa,
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
        .previewDisplayName("CVV Input Field")
    }
}
#endif
