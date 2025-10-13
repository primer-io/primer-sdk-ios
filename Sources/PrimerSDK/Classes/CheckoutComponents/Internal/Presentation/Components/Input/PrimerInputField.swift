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
    /// Can be either a String or ValidationError object
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
                            .foregroundColor(tokens?.primerColorIconNegative ?? .defaultIconNegative)
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

        // Check if it's a ValidationError object for resolution
        if let error = validationError as? ValidationError {
            return ErrorMessageResolver.resolveErrorMessage(for: error)
        }

        // Fall back to direct string handling
        return validationError as? String
    }
}
