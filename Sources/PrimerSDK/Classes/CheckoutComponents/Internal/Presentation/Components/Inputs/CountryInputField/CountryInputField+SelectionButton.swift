//
//  CountryInputField+SelectionButton.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct CountrySelectionButton: View {
    // MARK: - Properties

    let countryName: String
    let placeholder: String
    let styling: PrimerFieldStyling?
    let tokens: DesignTokens?
    let scope: any PrimerCardFormScope

    @Binding var isNavigating: Bool

    // MARK: - Computed Properties

    private var countryTextColor: Color {
        guard !countryName.isEmpty else {
            return styling?.placeholderColor ?? CheckoutColors.textPlaceholder(tokens: tokens)
        }
        return styling?.textColor ?? CheckoutColors.textPrimary(tokens: tokens)
    }

    private var fieldFont: Font {
        styling?.resolvedFont(tokens: tokens) ?? PrimerFont.bodyLarge(tokens: tokens)
    }

    // MARK: - Body

    var body: some View {
        Button(action: handleNavigation) {
            HStack(spacing: 0) {
                Text(countryName.isEmpty ? placeholder : countryName)
                    .font(fieldFont)
                    .foregroundColor(countryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: PrimerSize.xxlarge(tokens: tokens))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isNavigating)
    }

    // MARK: - Private Methods

    private func handleNavigation() {
        guard !isNavigating else {
            return
        }
        isNavigating = true
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        scope.navigateToCountrySelection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isNavigating = false
        }
    }
}
