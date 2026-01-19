//
//  PrimerInputFieldContainer+PreviewHelpers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

#if DEBUG
@available(iOS 15.0, *)
struct PreviewContainer: View {
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
struct PreviewContainerWithRightComponent: View {
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
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            }
        )
    }
}
#endif
