//
//  PrimerInputField.swift
//
//
//  Created by Boris on 24.3.25..
//

import SwiftUI

/**
 A customizable text input field that conforms to Primer's design system.
 Use it to add custom fields to the payment method list or in your custom card form implementation.
 */
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
    let validationError: String?

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
        validationError: String? = nil,
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
                    .font(.caption)
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

                    // The actual text field
                    TextField("", text: Binding(
                        get: { value },
                        set: { onValueChange($0) }
                    ))
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
                    .disabled(!enabled || readOnly)
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
            .padding()
            // Separate the background styling into its own sub-expression to help the compiler.
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(backgroundColor)
                    )
            )

            // Error text or supporting text below the input field
            if isError, let validationError = validationError {
                Text(validationError)
                    .font(.caption)
                    .foregroundColor(tokens?.primerColorBorderOutlinedError ?? .red)
            } else if let supportingText = supportingText {
                Text(supportingText)
                    .font(.caption)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            }
        }
    }
}

// MARK: - Preview

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
                validationError: "Please enter a valid email address.",
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
