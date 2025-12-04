//
//  PrimerInputFieldContainer.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Generic container for Primer input fields that provides consistent styling, layout, and error handling
@available(iOS 15.0, *)
struct PrimerInputFieldContainer<Content: View, RightContent: View>: View {
    let label: String?
    let styling: PrimerFieldStyling?
    let textFieldBuilder: () -> Content
    let rightComponent: (() -> RightContent)?

    @Binding var text: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    @Environment(\.designTokens) var tokens
    @Environment(\.sizeCategory) private var sizeCategory // Observes Dynamic Type changes

    var hasError: Bool { errorMessage?.isEmpty == false }

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
        _text = text
        _isValid = isValid
        _errorMessage = errorMessage
        _isFocused = isFocused
        self.textFieldBuilder = textFieldBuilder
        self.rightComponent = rightComponent
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: PrimerSpacing.xsmall(tokens: tokens),
            content: makeContent
        )
        .padding(.bottom, PrimerSpacing.medium(tokens: tokens))
    }

    func makeContent() -> some View {
        Group {
            label.map(makeLabel)
            makeTextFieldContainer()
            errorMessage.map(makeErrorMessage)
        }
    }
}

// MARK: - Convenience Initializer

@available(iOS 15.0, *)
extension PrimerInputFieldContainer where RightContent == Never {
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
        _text = text
        _isValid = isValid
        _errorMessage = errorMessage
        _isFocused = isFocused
        self.textFieldBuilder = textFieldBuilder
        rightComponent = nil
    }
}

// MARK: - Preview

#if DEBUG
    @available(iOS 15.0, *)
    #Preview("Light Mode") {
        VStack(spacing: 16) {
            PreviewContainer(
                label: "Field Label",
                text: "Sample text",
                errorMessage: nil
            )
            .background(Color.gray.opacity(0.1))

            PreviewContainer(
                label: nil,
                text: "",
                errorMessage: nil
            )
            .background(Color.gray.opacity(0.1))

            PreviewContainer(
                label: "Field with Error",
                text: "Invalid input",
                errorMessage: "Please enter a valid value"
            )
            .background(Color.gray.opacity(0.1))

            PreviewContainerWithRightComponent(
                label: "Field with Right Component",
                text: "With custom icon"
            )
            .background(Color.gray.opacity(0.1))
        }
        .padding()
        .environment(\.designTokens, MockDesignTokens.light)
        .environment(\.diContainer, MockDIContainer())
    }

    @available(iOS 15.0, *)
    #Preview("Dark Mode") {
        VStack(spacing: 16) {
            PreviewContainer(
                label: "Field Label",
                text: "Sample text",
                errorMessage: nil
            )
            .background(Color.gray.opacity(0.1))

            PreviewContainer(
                label: nil,
                text: "",
                errorMessage: nil
            )
            .background(Color.gray.opacity(0.1))

            PreviewContainer(
                label: "Field with Error",
                text: "Invalid input",
                errorMessage: "Please enter a valid value"
            )
            .background(Color.gray.opacity(0.1))

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
    }

#endif
