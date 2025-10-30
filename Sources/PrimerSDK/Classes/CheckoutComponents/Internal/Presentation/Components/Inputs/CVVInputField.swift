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
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

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
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
            text: $cvv,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
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
                    scope: scope,
                    tokens: tokens
                )
            } else {
                // Fallback view while loading validation service
                TextField(placeholder, text: $cvv)
                    .keyboardType(.numberPad)
                    .disabled(true)
            }
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
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let cardNetwork: CardNetwork
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: any PrimerCardFormScope
    let tokens: DesignTokens?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator

        textField.configurePrimerStyle(
            placeholder: placeholder,
            configuration: .cvv,
            styling: styling,
            tokens: tokens,
            doneButtonTarget: context.coordinator,
            doneButtonAction: #selector(Coordinator.doneButtonTapped)
        )

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
        @Binding private var isValid: Bool
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
            isValid: Binding<Bool>,
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
                isValid = false
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
        Group {
            // Light mode
            VStack(spacing: 16) {
                // Default state
                CVVInputField(
                    label: "CVV",
                    placeholder: "123",
                    scope: MockCardFormScope(),
                    cardNetwork: .visa
                )
                .background(Color.gray.opacity(0.1))

                // No label
                CVVInputField(
                    label: nil,
                    placeholder: "CVV",
                    scope: MockCardFormScope(),
                    cardNetwork: .masterCard
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                CVVInputField(
                    label: "CVV with Error",
                    placeholder: "Enter valid CVV",
                    scope: MockCardFormScope(isValid: false),
                    cardNetwork: .visa
                )
                .environment(\.diContainer, MockDIContainer(
                    validationService: MockValidationService(
                        shouldFailValidation: true,
                        errorMessage: "Please enter a valid CVV"
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
                CVVInputField(
                    label: "CVV",
                    placeholder: "123",
                    scope: MockCardFormScope(),
                    cardNetwork: .visa
                )
                .background(Color.gray.opacity(0.1))

                // No label
                CVVInputField(
                    label: nil,
                    placeholder: "CVV",
                    scope: MockCardFormScope(),
                    cardNetwork: .masterCard
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                CVVInputField(
                    label: "CVV with Error",
                    placeholder: "Enter valid CVV",
                    scope: MockCardFormScope(isValid: false),
                    cardNetwork: .visa
                )
                .environment(\.diContainer, MockDIContainer(
                    validationService: MockValidationService(
                        shouldFailValidation: true,
                        errorMessage: "Please enter a valid CVV"
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
