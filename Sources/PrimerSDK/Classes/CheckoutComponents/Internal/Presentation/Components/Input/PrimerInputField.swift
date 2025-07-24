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
        guard let tokens = tokens else { return .caption }
        return PrimerFont.bodyMedium(tokens: tokens)
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
            return tokens?.primerColorBorderOutlinedFocus ?? .blue
        } else {
            return tokens?.primerColorBorderOutlinedDefault ?? Color(.systemGray4)
        }
    }

    /// Determines the background color for the input field.
    private var backgroundColor: Color {
        tokens?.primerColorBackground ?? Color.white
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaDesignConstants.labelInputSpacing) {
            // Label (if provided) with label-specific modifier targeting
            if let labelText = labelText {
                Text(labelText)
                    .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 12, weight: .medium))
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            }

            // Input field with ZStack architecture
            ZStack {
                // Background and border styling
                RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
                            .stroke(borderColor, lineWidth: 1)
                            .animation(.easeInOut(duration: 0.2), value: borderColor)
                    )

                // Input field content
                HStack {
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
                            .onTapGesture {
                                isFocused = true
                            }
                            .onSubmit {
                                isFocused = false
                            }
                            .keyboardType(keyboardType)
                            .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                            .autocorrectionDisabled(keyboardType == .emailAddress)
                            .disabled(!enabled || readOnly)
                            .accessibilityLabel(labelText ?? placeholderText ?? "Text input")
                            .accessibilityHint(isError ? resolveErrorMessage() ?? "Error" : supportingText ?? "")
                        }
                    }
                    .padding(.leading, tokens?.primerSpaceLarge ?? 16)
                    .padding(.trailing, (isError || trailingIcon != nil) ? (tokens?.primerSizeXxlarge ?? 60) : (tokens?.primerSpaceLarge ?? 16))
                    .padding(.vertical, tokens?.primerSpaceMedium ?? 12)

                    Spacer()
                }

                // Right side overlay (error icon or trailing icon)
                HStack {
                    Spacer()

                    if isError {
                        // Error icon when validation fails (takes precedence over trailing icon)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: tokens?.primerSizeMedium ?? 20, height: tokens?.primerSizeMedium ?? 20)
                            .foregroundColor(tokens?.primerColorIconNegative ?? Color(red: 1.0, green: 0.45, blue: 0.47))
                            .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    } else if let trailingIcon = trailingIcon {
                        // Trailing icon when no error
                        trailingIcon
                            .foregroundColor(trailingIconColor)
                            .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    }
                }
            }
            .frame(height: tokens?.primerSizeXxxlarge ?? 48)

            // Error text or supporting text below the input field
            if isError, let errorMessage = resolveErrorMessage() {
                Text(errorMessage)
                    .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 11, weight: .regular))
                    .foregroundColor(tokens?.primerColorTextNegative ?? .red)
                    .padding(.top, tokens?.primerSpaceXsmall ?? 4)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else if let supportingText = supportingText {
                Text(supportingText)
                    .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 11, weight: .regular))
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    .padding(.top, tokens?.primerSpaceXsmall ?? 4)
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

        // Fall back to direct string handling
        return validationError as? String
    }

}

// MARK: - Configuration Helpers

@available(iOS 15.0, *)
extension PrimerInputField {

    /// Pre-configured PrimerInputField for first name input
    /// Note: Validation should be handled externally via ValidationService
    static func firstName(
        value: String,
        onValueChange: @escaping (String) -> Void,
        isError: Bool = false,
        validationError: Any? = nil
    ) -> PrimerInputField {
        return PrimerInputField(
            value: value,
            onValueChange: onValueChange,
            labelText: CheckoutComponentsStrings.firstNameLabel,
            placeholderText: CheckoutComponentsStrings.firstNamePlaceholder,
            isError: isError,
            validationError: validationError,
            keyboardType: .default
        )
    }

    /// Pre-configured PrimerInputField for last name input
    /// Note: Validation should be handled externally via ValidationService
    static func lastName(
        value: String,
        onValueChange: @escaping (String) -> Void,
        isError: Bool = false,
        validationError: Any? = nil
    ) -> PrimerInputField {
        return PrimerInputField(
            value: value,
            onValueChange: onValueChange,
            labelText: CheckoutComponentsStrings.lastNameLabel,
            placeholderText: CheckoutComponentsStrings.lastNamePlaceholder,
            isError: isError,
            validationError: validationError,
            keyboardType: .default
        )
    }

    /// Pre-configured PrimerInputField for email input
    /// Note: Validation should be handled externally via ValidationService
    static func email(
        value: String,
        onValueChange: @escaping (String) -> Void,
        isError: Bool = false,
        validationError: Any? = nil
    ) -> PrimerInputField {
        return PrimerInputField(
            value: value,
            onValueChange: onValueChange,
            labelText: CheckoutComponentsStrings.emailLabel,
            placeholderText: CheckoutComponentsStrings.emailPlaceholder,
            leadingIcon: Image(systemName: "envelope"),
            isError: isError,
            validationError: validationError,
            keyboardType: .emailAddress
        )
    }

    /// Pre-configured PrimerInputField for phone number input
    /// Note: Validation should be handled externally via ValidationService
    static func phoneNumber(
        value: String,
        onValueChange: @escaping (String) -> Void,
        isError: Bool = false,
        validationError: Any? = nil
    ) -> PrimerInputField {
        return PrimerInputField(
            value: value,
            onValueChange: onValueChange,
            labelText: CheckoutComponentsStrings.phoneNumberLabel,
            placeholderText: CheckoutComponentsStrings.phoneNumberPlaceholder,
            leadingIcon: Image(systemName: "phone"),
            isError: isError,
            validationError: validationError,
            keyboardType: .phonePad
        )
    }

    /// Pre-configured PrimerInputField for address line input
    /// Note: Validation should be handled externally via ValidationService
    static func addressLine(
        value: String,
        onValueChange: @escaping (String) -> Void,
        labelText: String,
        placeholderText: String,
        isError: Bool = false,
        validationError: Any? = nil
    ) -> PrimerInputField {
        return PrimerInputField(
            value: value,
            onValueChange: onValueChange,
            labelText: labelText,
            placeholderText: placeholderText,
            isError: isError,
            validationError: validationError,
            keyboardType: .default
        )
    }

    // MARK: - Validation Helpers
    // Note: Validation methods removed to follow clean architecture
    // Validation should be handled by ValidationService and proper validation rules
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
                validationError: "Please enter a valid email address.", // String error example
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
