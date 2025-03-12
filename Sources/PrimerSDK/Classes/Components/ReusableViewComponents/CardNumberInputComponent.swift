//
//  CardType.swift
//  
//
//  Created by Boris on 12.3.25..
//
import SwiftUI

@available(iOS 15.0, *)
struct CardNumberInputField: View {
    @Binding var cardNumber: String            // raw card number (digits only)
    @State private var displayText: String = "" // formatted (and possibly masked) text for UI
    @State private var cardNetwork: CardNetwork = .unknown
    @State private var showError: Bool = false
    @FocusState private var isFocused: Bool    // focus state for the text field

    // Inject design tokens via environment
    @Environment(\.designTokens) var tokens: DesignTokens?

    var body: some View {
        // 1) Extract optional token values into constants (with defaults).
        let spacing = tokens?.primerSpaceXsmall ?? 8
        let paddingValue = tokens?.primerSpaceSmall ?? 8
        let cornerRadius = tokens?.primerRadiusBase ?? 4
        let borderColor = showError
            ? (tokens?.primerColorBorderOutlinedError ?? .red)
            : (tokens?.primerColorBorderOutlinedActive ?? .blue)
        let backgroundColor = tokens?.primerColorBackground ?? .white
        let textColor = tokens?.primerColorTextPrimary ?? .primary
        let iconColor = tokens?.primerColorGray100 ?? .gray

        // 2) Build the text field row in a separate sub-view (constant).
        let textFieldRow = HStack {
            // Card Icon
            Image(uiImage: cardNetwork.icon!)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 16)
                .padding(.leading, paddingValue)

            // Actual text field
            TextField("Card Number", text: $displayText)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .accessibilityIdentifier("CardNumberField")
                .padding(paddingValue)
                .foregroundColor(textColor)
                .onChange(of: displayText) { newValue in
                    // Filter to digits
                    let digits = newValue.filter(\.isNumber)
                    // Limit to max 19 digits
                    if digits.count > 19 {
                        cardNumber = String(digits.prefix(19))
                    } else {
                        cardNumber = digits
                    }
                    // Reformat the display text with spaces
                    displayText = formatCardNumber(cardNumber)
                }
                .onChange(of: isFocused) { focused in
                    if !focused {
                        // Lost focus -> show error, mask if needed
                        if !cardNumber.isEmpty {
                            // TODO: Validate if you have validation logic
                            showError = true // e.g. = !validateCardNumber(cardNumber, cardNetwork)
                            displayText = maskCardNumber(cardNumber)
                        }
                    } else {
                        // Gained focus -> show unmasked formatted number
                        displayText = formatCardNumber(cardNumber)
                        showError = false
                    }
                }
        }
        // Style the row with border, background, corner radius
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: 1)
        )
        .background(backgroundColor)
        .cornerRadius(cornerRadius)

        // 3) Assemble everything in a VStack
        return VStack(alignment: .leading, spacing: spacing) {
            textFieldRow

            if showError {
                Text("Invalid card number")
                    .foregroundColor(borderColor)
                    .padding(.leading, paddingValue)
                    .accessibilityIdentifier("CardNumberErrorMessage")
            }
        }
        // 4) Animate error changes
        .animation(.easeInOut, value: showError)
    }

    // MARK: - Helpers

    /// Insert spaces after every 4 digits.
    private func formatCardNumber(_ digits: String) -> String {
        var result = ""
        for (index, char) in digits.enumerated() {
            if index != 0 && index % 4 == 0 {
                result.append(" ")
            }
            result.append(char)
        }
        return result
    }

    /// Mask the card number (all but the last 4 digits).
    private func maskCardNumber(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }
        let maskCount = max(0, digits.count - 4)
        let maskedSection = String(repeating: "•", count: maskCount)
        let visibleSection = digits.suffix(4)
        // Re-format the masked string with spaces
        return formatCardNumber(maskedSection + visibleSection)
    }

    /*
    // Example validation if you want to add it back:
    private func validateCardNumber(_ digits: String, _ network: CardNetwork) -> Bool {
        // e.g. length check, Luhn check, etc.
        // return true/false
    }
    */
}
