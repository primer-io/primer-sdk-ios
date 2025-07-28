//
//  ExpiryDateInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// Helper function to convert SwiftUI Font to UIFont
@available(iOS 15.0, *)
private func convertSwiftUIFontToUIFont(_ font: Font) -> UIFont {
    // Handle iOS 14.0+ specific font cases first
    if #available(iOS 14.0, *) {
        switch font {
        case .title2:
            return UIFont.preferredFont(forTextStyle: .title2)
        case .title3:
            return UIFont.preferredFont(forTextStyle: .title3)
        case .caption2:
            return UIFont.preferredFont(forTextStyle: .caption2)
        default:
            break
        }
    }

    // Handle all iOS 13.1+ compatible cases
    switch font {
    case .largeTitle:
        return UIFont.preferredFont(forTextStyle: .largeTitle)
    case .title:
        return UIFont.preferredFont(forTextStyle: .title1)
    case .headline:
        return UIFont.preferredFont(forTextStyle: .headline)
    case .subheadline:
        return UIFont.preferredFont(forTextStyle: .subheadline)
    case .body:
        return UIFont.preferredFont(forTextStyle: .body)
    case .callout:
        return UIFont.preferredFont(forTextStyle: .callout)
    case .footnote:
        return UIFont.preferredFont(forTextStyle: .footnote)
    case .caption:
        return UIFont.preferredFont(forTextStyle: .caption1)
    default:
        return UIFont.systemFont(ofSize: 16, weight: .regular)
    }
}

/// A SwiftUI component for credit card expiry date input with automatic formatting
/// and validation to ensure dates are valid and not in the past.
@available(iOS 15.0, *)
internal struct ExpiryDateInputField: View, LogReporter {
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
    /// Creates a new ExpiryDateInputField with comprehensive customization support
    internal init(
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

            // Expiry date input field with ZStack architecture
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
                            scope: scope
                        )
                        .padding(.leading, styling?.padding?.leading ?? tokens?.primerSpaceLarge ?? 16)
                        .padding(.trailing, errorMessage != nil ?
                                    (tokens?.primerSizeXxlarge ?? 60) :
                                    (styling?.padding?.trailing ?? tokens?.primerSpaceLarge ?? 16))
                        .padding(.vertical, styling?.padding?.top ?? tokens?.primerSpaceMedium ?? 12)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: $expiryDate)
                            .keyboardType(.numberPad)
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
                            .foregroundColor(tokens?.primerColorIconNegative ?? Color(red: 1.0, green: 0.45, blue: 0.47))
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
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 15) // Fixed height to prevent layout shifts
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
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
    @Binding var isValid: Bool?
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
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
            textField.font = convertSwiftUIFontToUIFont(customFont)
        } else {
            textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }

        textField.backgroundColor = .clear

        // Apply custom text color if provided
        if let textColor = styling?.textColor {
            textField.textColor = UIColor(textColor)
        }
        textField.textContentType = .none // Prevent autofill

        // Apply custom placeholder styling or use defaults
        let placeholderFont: UIFont = {
            if let customFont = styling?.font {
                return convertSwiftUIFontToUIFont(customFont)
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
        @Binding private var isValid: Bool?
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let scope: any PrimerCardFormScope

        init(
            validationService: ValidationService,
            expiryDate: Binding<String>,
            month: Binding<String>,
            year: Binding<String>,
            isValid: Binding<Bool?>,
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
                isValid = nil
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
