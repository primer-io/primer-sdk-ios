//
//  PrimerInputField.swift
//  CheckoutComponents
//
//  Modern CheckoutComponents input field with validation
//

import SwiftUI

/**
 A customizable text input field that conforms to Primer's design system.
 Use it to add custom fields to the payment method list or in your custom card form implementation.
 */
@available(iOS 15.0, *)
struct PrimerInputField: View {
    // MARK: - Properties

    /// The input text to be shown in the text field
    let value: String

    /// The callback that is triggered when the input service updates the text
    let onValueChange: (String) -> Void

    /// The optional label to be displayed inside the text field container
    let labelText: String?

    /// The optional placeholder to be displayed when the text field is in focus and the input text is empty
    let placeholderText: String?

    /// The optional leading icon to be displayed at the beginning of the text field container
    let leadingIcon: Image?

    /// The optional trailing icon to be displayed at the end of the text field container
    let trailingIcon: Image?

    /// The supporting text to be displayed below the text field
    let supportingText: String?

    /// Indicates if the text field's current value is in error
    let isError: Bool

    /// Error message to display if isError is true
    /// Can be either a String or ValidationError object for Android parity
    let validationError: Any?

    /// Controls the enabled state of this text field
    let enabled: Bool

    /// Controls the read-only state of the text field
    let readOnly: Bool

    /// The keyboard type
    let keyboardType: UIKeyboardType

    /// The return key type
    let keyboardReturnKey: UIReturnKeyType

    // MARK: - Private State

    @State private var isFocused: Bool = false
    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(
        value: String,
        onValueChange: @escaping (String) -> Void,
        labelText: String? = nil,
        placeholderText: String? = nil,
        leadingIcon: Image? = nil,
        trailingIcon: Image? = nil,
        supportingText: String? = nil,
        isError: Bool = false,
        validationError: Any? = nil,
        enabled: Bool = true,
        readOnly: Bool = false,
        keyboardType: UIKeyboardType = .default,
        keyboardReturnKey: UIReturnKeyType = .default
    ) {
        self.value = value
        self.onValueChange = onValueChange
        self.labelText = labelText
        self.placeholderText = placeholderText
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.supportingText = supportingText
        self.isError = isError
        self.validationError = validationError
        self.enabled = enabled
        self.readOnly = readOnly
        self.keyboardType = keyboardType
        self.keyboardReturnKey = keyboardReturnKey
    }

    // MARK: - Computed Properties

    /// Determines the label color based on error state.
    private var labelColor: Color {
        isError ? (tokens?.primerColorBorderOutlinedError ?? .red) : (tokens?.primerColorTextSecondary ?? .secondary)
    }

    /// Determines the label font using design tokens.
    private var labelFont: Font {
        if let fontName = tokens?.primerTypographyBodyMediumFont,
           let fontSize = tokens?.primerTypographyBodyMediumSize,
           let fontWeight = tokens?.primerTypographyBodyMediumWeight {
            return Font.custom(fontName, size: fontSize)
                .weight(mapCGFloatToFontWeight(fontWeight))
        }
        return .caption
    }

    /// Determines the color for the leading icon.
    private var leadingIconColor: Color {
        isError ? (tokens?.primerColorBorderOutlinedError ?? .red) : (tokens?.primerColorIconPrimary ?? .gray)
    }

    /// Determines the color for the trailing icon.
    private var trailingIconColor: Color {
        isError ? (tokens?.primerColorBorderOutlinedError ?? .red) : (tokens?.primerColorIconPrimary ?? .gray)
    }

    /// Determines the border color based on error and focus state.
    private var borderColor: Color {
        if isError {
            return tokens?.primerColorBorderOutlinedError ?? .red
        } else if isFocused {
            return tokens?.primerColorBrand ?? .blue
        } else {
            return tokens?.primerColorTextPrimary ?? Color(.systemGray4)
        }
    }

    /// Determines the border width based on focus and error.
    private var borderWidth: CGFloat {
        (isFocused || isError) ? 2 : 1
    }

    /// Determines the background color for the input field.
    private var backgroundColor: Color {
        tokens?.primerColorTextSecondary ?? Color(.systemBackground)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label (if provided)
            if let labelText = labelText {
                Text(labelText)
                    .font(labelFont)
                    .foregroundColor(labelColor)
            }

            // Input field container
            HStack(spacing: 8) {
                // Leading icon (if provided)
                if let leadingIcon = leadingIcon {
                    leadingIcon
                        .foregroundColor(leadingIconColor)
                }

                // TextField container with placeholder support
                ZStack(alignment: .leading) {
                    // Show placeholder when field is empty and not focused
                    if value.isEmpty && !isFocused {
                        Text(placeholderText ?? "")
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .gray)
                    }

                    // The actual text field with basic configuration
                    TextField("", text: Binding(
                        get: { value },
                        set: { onValueChange($0) }
                    ))
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
                    .disabled(!enabled || readOnly)
                    .accessibilityLabel(labelText ?? placeholderText ?? "Text input")
                    .accessibilityHint(isError ? resolveErrorMessage() ?? "Error" : supportingText ?? "")
                    // Update focus state when editing begins and ends
                    .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                        if (obj.object as? UITextField) != nil {
                            isFocused = true
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidEndEditingNotification)) { obj in
                        if (obj.object as? UITextField) != nil {
                            isFocused = false
                        }
                    }
                }

                // Trailing icon (if provided)
                if let trailingIcon = trailingIcon {
                    trailingIcon
                        .foregroundColor(trailingIconColor)
                }
            }
            .padding(tokens?.primerSpaceMedium ?? 12)
            .frame(height: tokens?.primerSizeXxxlarge ?? 56)
            // Separate the background styling into its own sub-expression to help the compiler.
            .background(
                RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
                    .stroke(borderColor, lineWidth: borderWidth)
                    .background(
                        RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
                            .fill(backgroundColor)
                    )
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .animation(.easeInOut(duration: 0.3), value: isError)

            // Error text or supporting text below the input field
            if isError, let errorMessage = resolveErrorMessage() {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(tokens?.primerColorBorderOutlinedError ?? .red)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else if let supportingText = supportingText {
                Text(supportingText)
                    .font(.caption)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Helper Functions

    /// Resolves error message using ErrorMessageResolver for ValidationError objects or falls back to string
    private func resolveErrorMessage() -> String? {
        guard let validationError = validationError else { return nil }

        // Check if it's a ValidationError object for Android parity resolution
        if let error = validationError as? ValidationError {
            return ErrorMessageResolver.resolveErrorMessage(for: error)
        }

        // Fall back to direct string for backward compatibility
        return validationError as? String
    }

    /// Maps CGFloat font weight values to SwiftUI Font.Weight enum cases
    private func mapCGFloatToFontWeight(_ weight: CGFloat) -> Font.Weight {
        switch weight {
        case ...200: return .ultraLight
        case 200..<300: return .thin
        case 300..<400: return .light
        case 400..<500: return .regular
        case 500..<600: return .medium
        case 600..<700: return .semibold
        case 700..<800: return .bold
        case 800..<900: return .heavy
        default: return .black
        }
    }
}

// MARK: - Configuration Helpers

@available(iOS 15.0, *)
extension PrimerInputField {

    /// Pre-configured PrimerInputField for first name input with Android parity validation
    static func firstName(
        value: String,
        onValueChange: @escaping (String) -> Void,
        onValidationChange: ((Bool) -> Void)? = nil
    ) -> PrimerInputField {
        return PrimerInputField(
            value: value,
            onValueChange: { newValue in
                onValueChange(newValue)
                // Validate and call validation change if provided
                let error = validateFirstName(newValue)
                onValidationChange?(error == nil)
            },
            labelText: CheckoutComponentsStrings.firstNameFieldName,
            placeholderText: CheckoutComponentsStrings.firstNamePlaceholder,
            isError: validateFirstName(value) != nil,
            validationError: validateFirstName(value),
            keyboardType: .default
        )
    }

    /// Pre-configured PrimerInputField for last name input with Android parity validation
    static func lastName(
        value: String,
        onValueChange: @escaping (String) -> Void,
        onValidationChange: ((Bool) -> Void)? = nil
    ) -> PrimerInputField {
        return PrimerInputField(
            value: value,
            onValueChange: { newValue in
                onValueChange(newValue)
                let error = validateLastName(newValue)
                onValidationChange?(error == nil)
            },
            labelText: CheckoutComponentsStrings.lastNameFieldName,
            placeholderText: CheckoutComponentsStrings.lastNamePlaceholder,
            isError: validateLastName(value) != nil,
            validationError: validateLastName(value),
            keyboardType: .default
        )
    }

    /// Pre-configured PrimerInputField for email input with Android parity validation
    static func email(
        value: String,
        onValueChange: @escaping (String) -> Void,
        onValidationChange: ((Bool) -> Void)? = nil
    ) -> PrimerInputField {
        return PrimerInputField(
            value: value,
            onValueChange: { newValue in
                onValueChange(newValue)
                let error = validateEmail(newValue)
                onValidationChange?(error == nil)
            },
            labelText: CheckoutComponentsStrings.emailFieldName,
            placeholderText: CheckoutComponentsStrings.emailPlaceholder,
            leadingIcon: Image(systemName: "envelope"),
            isError: validateEmail(value) != nil,
            validationError: validateEmail(value),
            keyboardType: .emailAddress
        )
    }

    /// Pre-configured PrimerInputField for phone number input with Android parity validation
    static func phoneNumber(
        value: String,
        onValueChange: @escaping (String) -> Void,
        onValidationChange: ((Bool) -> Void)? = nil
    ) -> PrimerInputField {
        return PrimerInputField(
            value: value,
            onValueChange: { newValue in
                onValueChange(newValue)
                let error = validatePhoneNumber(newValue)
                onValidationChange?(error == nil)
            },
            labelText: CheckoutComponentsStrings.phoneNumberFieldName,
            placeholderText: CheckoutComponentsStrings.phoneNumberPlaceholder,
            leadingIcon: Image(systemName: "phone"),
            isError: validatePhoneNumber(value) != nil,
            validationError: validatePhoneNumber(value),
            keyboardType: .phonePad
        )
    }

    /// Pre-configured PrimerInputField for address line input with Android parity validation
    static func addressLine(
        value: String,
        onValueChange: @escaping (String) -> Void,
        labelText: String,
        placeholderText: String,
        inputElementType: ValidationError.InputElementType,
        isRequired: Bool = true,
        onValidationChange: ((Bool) -> Void)? = nil
    ) -> PrimerInputField {
        return PrimerInputField(
            value: value,
            onValueChange: { newValue in
                onValueChange(newValue)
                let error = validateAddressField(newValue, inputType: inputElementType, isRequired: isRequired)
                onValidationChange?(error == nil)
            },
            labelText: labelText,
            placeholderText: placeholderText,
            isError: validateAddressField(value, inputType: inputElementType, isRequired: isRequired) != nil,
            validationError: validateAddressField(value, inputType: inputElementType, isRequired: isRequired),
            keyboardType: .default
        )
    }

    // MARK: - Validation Helpers

    private static func validateFirstName(_ value: String) -> ValidationError? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ErrorMessageResolver.createRequiredFieldError(for: .firstName)
        }
        if trimmed.count < 2 {
            return ErrorMessageResolver.createInvalidFieldError(for: .firstName)
        }
        return nil
    }

    private static func validateLastName(_ value: String) -> ValidationError? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ErrorMessageResolver.createRequiredFieldError(for: .lastName)
        }
        if trimmed.count < 2 {
            return ErrorMessageResolver.createInvalidFieldError(for: .lastName)
        }
        return nil
    }

    private static func validateEmail(_ value: String) -> ValidationError? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ErrorMessageResolver.createRequiredFieldError(for: .email)
        }

        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: trimmed) {
            return ErrorMessageResolver.createInvalidFieldError(for: .email)
        }
        return nil
    }

    private static func validatePhoneNumber(_ value: String) -> ValidationError? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ErrorMessageResolver.createRequiredFieldError(for: .phoneNumber)
        }

        // Basic phone number validation - digits, spaces, dashes, parentheses, plus
        let phoneRegex = "^[+]?[0-9\\s\\-\\(\\)]+$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        if !phonePredicate.evaluate(with: trimmed) || trimmed.count < 8 {
            return ErrorMessageResolver.createInvalidFieldError(for: .phoneNumber)
        }
        return nil
    }

    private static func validateAddressField(_ value: String, inputType: ValidationError.InputElementType, isRequired: Bool) -> ValidationError? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if isRequired && trimmed.isEmpty {
            return ErrorMessageResolver.createRequiredFieldError(for: inputType)
        }

        // Optional fields can be empty
        if !isRequired && trimmed.isEmpty {
            return nil
        }

        // Basic length validation for non-empty fields
        if !trimmed.isEmpty && trimmed.count < 2 {
            return ErrorMessageResolver.createInvalidFieldError(for: inputType)
        }

        return nil
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct PrimerInputField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PrimerInputField(
                value: "",
                onValueChange: { _ in },
                labelText: "Email",
                placeholderText: "Enter your email",
                leadingIcon: Image(systemName: "envelope"),
                supportingText: "We'll never share your email with anyone else.",
                keyboardType: .emailAddress
            )

            PrimerInputField(
                value: "John",
                onValueChange: { _ in },
                labelText: "First Name",
                placeholderText: "Enter your first name",
                leadingIcon: Image(systemName: "person")
            )

            PrimerInputField(
                value: "johndoe@example",
                onValueChange: { _ in },
                labelText: "Email",
                placeholderText: "Enter your email",
                leadingIcon: Image(systemName: "envelope"),
                isError: true,
                validationError: "Please enter a valid email address.", // Legacy string error
                keyboardType: .emailAddress
            )

            PrimerInputField(
                value: "Disabled Field",
                onValueChange: { _ in },
                labelText: "Disabled",
                enabled: false
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
