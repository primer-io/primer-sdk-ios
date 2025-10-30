//
//  ExpiryDateInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for credit card expiry date input with automatic formatting
/// and validation to ensure dates are valid and not in the past.
@available(iOS 15.0, *)
struct ExpiryDateInputField: View, LogReporter {
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

    /// The expiry date entered by the user
    @State private var expiryDate: String = ""

    /// The extracted month value (MM)
    @State private var month: String = ""

    /// The extracted year value (YY)
    @State private var year: String = ""

    /// The validation state of the expiry date
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization
    /// Creates a new ExpiryDateInputField with comprehensive customization support
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
            text: $expiryDate,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
        ) {
            if let validationService = validationService {
                ExpiryDateTextField(
                    expiryDate: $expiryDate,
                    month: $month,
                    year: $year,
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
                TextField(placeholder, text: $expiryDate)
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
            logger.error(message: "DIContainer not available for ExpiryDateInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for expiry date input
@available(iOS 15.0, *)
private struct ExpiryDateTextField: UIViewRepresentable, LogReporter {
    @Binding var expiryDate: String
    @Binding var month: String
    @Binding var year: String
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
            configuration: .expiryDate,
            styling: styling,
            tokens: tokens,
            doneButtonTarget: context.coordinator,
            doneButtonAction: #selector(Coordinator.doneButtonTapped)
        )

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != expiryDate {
            textField.text = expiryDate
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            expiryDate: $expiryDate,
            month: $month,
            year: $year,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            scope: scope
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var expiryDate: String
        @Binding private var month: String
        @Binding private var year: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let scope: any PrimerCardFormScope

        init(
            validationService: ValidationService,
            expiryDate: Binding<String>,
            month: Binding<String>,
            year: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self._expiryDate = expiryDate
            self._month = month
            self._year = year
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
                self.scope.clearFieldError(.expiryDate)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validateExpiryDate()
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = expiryDate

            // Handle return key
            if string == "\n" {
                textField.resignFirstResponder()
                return false
            }

            // Only allow numbers and return for non-numeric input except deletion
            if !string.isEmpty && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
                return false
            }

            // Process the input
            let newText = processInput(currentText: currentText, range: range, string: string)

            // Update the text field
            expiryDate = newText
            textField.text = newText

            // Extract month and year
            extractMonthAndYear(from: newText)

            // Update scope state
            scope.updateExpiryDate(newText)

            // Validate if complete
            if newText.count == 5 { // MM/YY format
                validateExpiryDate()
            } else {
                isValid = false
                errorMessage = nil
            }

            return false
        }

        private func processInput(currentText: String, range: NSRange, string: String) -> String {
            // Handle deletion
            if string.isEmpty {
                // If deleting the separator, also remove the character before it
                if range.location == 2 && range.length == 1 && currentText.count >= 3 &&
                    currentText[currentText.index(currentText.startIndex, offsetBy: 2)] == "/" {
                    return String(currentText.prefix(1))
                }

                // Normal deletion
                if let textRange = Range(range, in: currentText) {
                    return currentText.replacingCharacters(in: textRange, with: "")
                }
                return currentText
            }

            // Handle additions
            // Remove the / character temporarily for easier processing
            let sanitizedText = currentText.replacingOccurrences(of: "/", with: "")

            // Calculate where to insert the new text
            var sanitizedLocation = range.location
            if range.location > 2 && currentText.count >= 3 && currentText.contains("/") {
                sanitizedLocation -= 1
            }

            // Insert the new digits
            var newSanitizedText = sanitizedText
            if sanitizedLocation <= sanitizedText.count {
                let index = newSanitizedText.index(newSanitizedText.startIndex, offsetBy: min(sanitizedLocation, newSanitizedText.count))
                newSanitizedText.insert(contentsOf: string, at: index)
            } else {
                newSanitizedText += string
            }

            // Limit to 4 digits total (MMYY format)
            newSanitizedText = String(newSanitizedText.prefix(4))

            // Format with separator
            if newSanitizedText.count > 2 {
                return "\(newSanitizedText.prefix(2))/\(newSanitizedText.dropFirst(2))"
            } else {
                return newSanitizedText
            }
        }

        private func extractMonthAndYear(from text: String) {
            let parts = text.components(separatedBy: "/")

            month = parts.count > 0 ? parts[0] : ""
            year = parts.count > 1 ? parts[1] : ""

            scope.updateExpiryMonth(month)
            scope.updateExpiryYear(year)
        }

        private func validateExpiryDate() {
            // Empty field handling - don't show errors for empty fields
            let trimmedExpiry = expiryDate.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedExpiry.isEmpty {
                isValid = false // Expiry date is required
                errorMessage = nil // Never show error message for empty fields
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateExpiryValidationState(false)
                }
                return
            }

            // Parse MM/YY format for non-empty fields
            let components = expiryDate.components(separatedBy: "/")

            guard components.count == 2 else {
                isValid = false
                errorMessage = CheckoutComponentsStrings.enterValidExpiryDate
                scope.setFieldError(.expiryDate, message: CheckoutComponentsStrings.enterValidExpiryDate, errorCode: "invalid_format")
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateExpiryValidationState(false)
                }
                return
            }

            let month = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let year = components[1].trimmingCharacters(in: .whitespacesAndNewlines)

            let expiryInput = ExpiryDateInput(month: month, year: year)
            let result = validationService.validate(
                input: expiryInput,
                with: ExpiryDateRule()
            )

            isValid = result.isValid
            errorMessage = result.errorMessage

            // Update scope state based on validation
            if result.isValid {
                scope.clearFieldError(.expiryDate)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateExpiryValidationState(true)
                }
            } else {
                if let message = result.errorMessage {
                    scope.setFieldError(.expiryDate, message: message, errorCode: result.errorCode)
                }
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateExpiryValidationState(false)
                }
            }
        }
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
struct ExpiryDateInputField_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode
            VStack(spacing: 16) {
                // Default state
                ExpiryDateInputField(
                    label: "Expiry Date",
                    placeholder: "MM / YY",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // No label
                ExpiryDateInputField(
                    label: nil,
                    placeholder: "Expiration",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                ExpiryDateInputField(
                    label: "Expiry Date with Error",
                    placeholder: "Enter valid date",
                    scope: MockCardFormScope(isValid: false)
                )
                .environment(\.diContainer, MockDIContainer(
                    validationService: MockValidationService(
                        shouldFailValidation: true,
                        errorMessage: "Please enter a valid expiry date"
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
                ExpiryDateInputField(
                    label: "Expiry Date",
                    placeholder: "MM / YY",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // No label
                ExpiryDateInputField(
                    label: nil,
                    placeholder: "Expiration",
                    scope: MockCardFormScope()
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                ExpiryDateInputField(
                    label: "Expiry Date with Error",
                    placeholder: "Enter valid date",
                    scope: MockCardFormScope(isValid: false)
                )
                .environment(\.diContainer, MockDIContainer(
                    validationService: MockValidationService(
                        shouldFailValidation: true,
                        errorMessage: "Please enter a valid expiry date"
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
