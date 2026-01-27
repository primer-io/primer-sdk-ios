//
//  CountryInputField+SelectionButton.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
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

  @State private var showCountryPicker: Bool = false

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
    Button(
      action: {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        showCountryPicker = true
      },
      label: {
        HStack(spacing: 0) {
          Text(countryName.isEmpty ? placeholder : countryName)
            .font(fieldFont)
            .foregroundColor(countryTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: PrimerSize.xxlarge(tokens: tokens))
        .contentShape(Rectangle())
      }
    )
    .buttonStyle(PlainButtonStyle())
    .sheet(isPresented: $showCountryPicker) {
      SelectCountryScreen(
        scope: scope.selectCountry,
        onDismiss: {
          showCountryPicker = false
        }
      )
    }
  }
}
