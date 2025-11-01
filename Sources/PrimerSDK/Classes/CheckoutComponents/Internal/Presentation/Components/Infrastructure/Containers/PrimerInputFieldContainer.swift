//
//  PrimerInputFieldContainer.swift
//  PrimerSDK
//
//  Created by Primer on 25/10/2025.
//

import SwiftUI

/// Generic container for Primer input fields that provides consistent styling, layout, and error handling
@available(iOS 15.0, *)
struct PrimerInputFieldContainer<Content: View, RightContent: View>: View {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?

    /// Binding to the text value
    @Binding var text: String

    /// Binding to the validation state
    @Binding var isValid: Bool

    /// Binding to the error message
    @Binding var errorMessage: String?

    /// Binding to the focus state
    @Binding var isFocused: Bool

    /// Builder for the actual text field content
    @ViewBuilder let textFieldBuilder: () -> Content

    /// Optional builder for custom right component (shows when no error)
    let rightComponent: (() -> RightContent)?

    // MARK: - Private Properties

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
            labelView
            textFieldContainerView
            errorMessageView
        }
        .padding(.bottom, PrimerSpacing.medium(tokens: tokens))
    }

    // MARK: - Computed Properties

    /// Dynamic border color based on field state
    private var borderColor: Color {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return styling?.errorBorderColor ?? PrimerCheckoutColors.borderError(tokens: tokens)
        } else if isFocused {
            return styling?.focusedBorderColor ?? PrimerCheckoutColors.borderFocus(tokens: tokens)
        } else {
            return styling?.borderColor ?? PrimerCheckoutColors.borderDefault(tokens: tokens)
        }
    }

    /// Whether the field currently has an error message
    private var hasError: Bool {
        errorMessage != nil && !(errorMessage?.isEmpty ?? true)
    }

    /// Label view displayed above the input field
    @ViewBuilder
    private var labelView: some View {
        if let label {
            Text(label)
                .font(styling?.labelFont ?? PrimerFont.bodySmall(tokens: tokens))
                .foregroundColor(styling?.labelColor ?? PrimerCheckoutColors.textPrimary(tokens: tokens))
                .frame(height: PrimerComponentHeight.label)
        }
    }

    /// Text field container with border and styling
    private var textFieldContainerView: some View {
        HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
            textFieldBuilder()
            Spacer()

            // Right components: custom component + error icon (both can show)
            if let rightComponent {
                rightComponent()
            }

            if let errorMessage, !errorMessage.isEmpty {
                let iconSize = PrimerSize.medium(tokens: tokens)
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(PrimerCheckoutColors.iconNegative(tokens: tokens))
                    .offset(x: hasError ? 0 : -10)
                    .opacity(hasError ? 1.0 : 0.0)
            }
        }
        .padding(.leading, styling?.padding?.leading ?? PrimerSpacing.medium(tokens: tokens))
        .padding(.trailing, styling?.padding?.trailing ?? PrimerSpacing.medium(tokens: tokens))
        .frame(height: styling?.fieldHeight ?? PrimerSize.xxlarge(tokens: tokens))
        .background(
            RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
                .strokeBorder(borderColor, lineWidth: styling?.borderWidth ?? PrimerBorderWidth.standard)
                .background(
                    RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
                        .fill(styling?.backgroundColor ?? PrimerCheckoutColors.background(tokens: tokens))
                )
                .animation(AnimationConstants.focusAnimation, value: isFocused)
        )
    }

    /// Error message view with animated appearance
    private var errorMessageView: some View {
        Text(errorMessage ?? "")
            .font(PrimerFont.bodySmall(tokens: tokens))
            .foregroundColor(PrimerCheckoutColors.textNegative(tokens: tokens))
            .frame(height: hasError ? PrimerComponentHeight.errorMessage : 0)
            .offset(y: hasError ? 0 : -10)
            .opacity(hasError ? 1.0 : 0.0)
            .padding(.top, hasError ? PrimerSpacing.xsmall(tokens: tokens) : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasError)
    }

    // MARK: - Initializer

    /// Full initializer with custom right component
    init(
        label: String?,
        styling: PrimerFieldStyling?,
        text: Binding<String>,
        isValid: Binding<Bool>,
        errorMessage: Binding<String?>,
        isFocused: Binding<Bool>,
        @ViewBuilder textFieldBuilder: @escaping () -> Content,
        @ViewBuilder rightComponent: @escaping () -> RightContent
    ) {
        self.label = label
        self.styling = styling
        self._text = text
        self._isValid = isValid
        self._errorMessage = errorMessage
        self._isFocused = isFocused
        self.textFieldBuilder = textFieldBuilder
        self.rightComponent = { rightComponent() }
    }
}

// MARK: - Convenience Initializer

@available(iOS 15.0, *)
extension PrimerInputFieldContainer where RightContent == EmptyView {
    /// Convenience initializer for containers without custom right component
    init(
        label: String?,
        styling: PrimerFieldStyling?,
        text: Binding<String>,
        isValid: Binding<Bool>,
        errorMessage: Binding<String?>,
        isFocused: Binding<Bool>,
        @ViewBuilder textFieldBuilder: @escaping () -> Content
    ) {
        self.label = label
        self.styling = styling
        self._text = text
        self._isValid = isValid
        self._errorMessage = errorMessage
        self._isFocused = isFocused
        self.textFieldBuilder = textFieldBuilder
        self.rightComponent = nil
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 15.0, *)
struct PrimerInputFieldContainer_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode
            VStack(spacing: 16) {
                // Default state
                PreviewContainer(
                    label: "Field Label",
                    text: "Sample text",
                    errorMessage: nil
                )
                .background(Color.gray.opacity(0.1))

                // No label
                PreviewContainer(
                    label: nil,
                    text: "",
                    errorMessage: nil
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                PreviewContainer(
                    label: "Field with Error",
                    text: "Invalid input",
                    errorMessage: "Please enter a valid value"
                )
                .background(Color.gray.opacity(0.1))

                // With right component
                PreviewContainerWithRightComponent(
                    label: "Field with Right Component",
                    text: "With custom icon"
                )
                .background(Color.gray.opacity(0.1))
            }
            .padding()
            .environment(\.designTokens, MockDesignTokens.light)
            .environment(\.diContainer, MockDIContainer())
            .previewDisplayName("Light Mode")

            // Dark mode
            VStack(spacing: 16) {
                // Default state
                PreviewContainer(
                    label: "Field Label",
                    text: "Sample text",
                    errorMessage: nil
                )
                .background(Color.gray.opacity(0.1))

                // No label
                PreviewContainer(
                    label: nil,
                    text: "",
                    errorMessage: nil
                )
                .background(Color.gray.opacity(0.1))

                // Error state
                PreviewContainer(
                    label: "Field with Error",
                    text: "Invalid input",
                    errorMessage: "Please enter a valid value"
                )
                .background(Color.gray.opacity(0.1))

                // With right component
                PreviewContainerWithRightComponent(
                    label: "Field with Right Component",
                    text: "With custom icon"
                )
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

@available(iOS 15.0, *)
private struct PreviewContainer: View {
    let label: String?
    let text: String
    let errorMessage: String?

    @State private var currentText: String
    @State private var isValid = true
    @State private var currentErrorMessage: String?
    @State private var isFocused = false

    init(label: String?, text: String, errorMessage: String?) {
        self.label = label
        self.text = text
        self.errorMessage = errorMessage
        self._currentText = State(initialValue: text)
        self._currentErrorMessage = State(initialValue: errorMessage)
    }

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: nil,
            text: $currentText,
            isValid: $isValid,
            errorMessage: $currentErrorMessage,
            isFocused: $isFocused
        ) {
            TextField("Placeholder", text: $currentText, onEditingChanged: { focused in
                isFocused = focused
            })
            .textFieldStyle(.plain)
        }
    }
}

@available(iOS 15.0, *)
private struct PreviewContainerWithRightComponent: View {
    let label: String?
    let text: String

    @State private var currentText: String
    @State private var isValid = true
    @State private var errorMessage: String?
    @State private var isFocused = false
    @Environment(\.designTokens) private var tokens

    init(label: String?, text: String) {
        self.label = label
        self.text = text
        self._currentText = State(initialValue: text)
    }

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: nil,
            text: $currentText,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            textFieldBuilder: {
                TextField("Placeholder", text: $currentText, onEditingChanged: { focused in
                    isFocused = focused
                })
                .textFieldStyle(.plain)
            },
            rightComponent: {
                let iconSize = PrimerSize.medium(tokens: tokens)
                Image(systemName: "info.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))
            }
        )
    }
}
#endif
