//
//  CardType.swift
//  
//
//  Created by Boris on 12.3.25..
//

import SwiftUI

/// A SwiftUI card number input field with real-time card network detection,
/// auto-formatting, validation, and design token integration.
@available(iOS 15.0, *)
struct CardNumberInputField: View {
    // MARK: - Private Properties

    /// The formatted text for display (with spaces)
    @State private var displayText: String = ""

    /// The detected card network
    @State private var cardNetwork: CardNetwork = .unknown

    /// Whether to show an error message
    @State private var showError: Bool = false

    /// Focus state for the text field
    @FocusState private var isFocused: Bool

    // MARK: - Environment

    /// Inject design tokens via environment
    @Environment(\.designTokens) var tokens: DesignTokens?

    // MARK: - Public Properties

    /// Callback when card network is detected
    var onCardNetworkChange: ((CardNetwork) -> Void)?

    /// Callback when validation state changes
    var onValidationChange: ((Bool?) -> Void)?

    /// Label to display above the field
    let label: String

    /// Placeholder text when field is empty
    let placeholder: String

    // MARK: - Initialization

    /// Creates a new CardNumberInputField
    /// - Parameters:
    ///   - label: The label displayed above the field
    ///   - placeholder: Placeholder text when the field is empty
    ///   - onCardNetworkChange: Optional callback when card network changes
    ///   - onValidationChange: Optional callback when validation state changes
    init(
        label: String,
        placeholder: String,
        onCardNetworkChange: ((CardNetwork) -> Void)? = nil,
        onValidationChange: ((Bool?) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.onCardNetworkChange = onCardNetworkChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        // 1) Extract optional token values into constants (with defaults).
        let spacing = tokens?.primerSpaceXsmall ?? 4
        let paddingValue = tokens?.primerSpaceSmall ?? 8
        let cornerRadius = tokens?.primerRadiusBase ?? 4
        let borderColor = showError
            ? (tokens?.primerColorBorderOutlinedError ?? .red)
            : (tokens?.primerColorBorderOutlinedActive ?? .blue)
        let backgroundColor = tokens?.primerColorBackground ?? .white
        let textColor = tokens?.primerColorTextPrimary ?? .primary
        let iconColor = tokens?.primerColorGray500 ?? .gray

        // 2) Build the view hierarchy with a VStack
        VStack(alignment: .leading, spacing: spacing) {
            // Top label (always visible)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .accessibilityIdentifier("CardNumberLabel")

            // Text field row in a HStack
            HStack {
                // Card Icon
                Image(uiImage: cardNetwork.icon ?? UIImage(systemName: "creditcard")!)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 16)
                    .padding(.leading, paddingValue)

                // Actual text field
                TextField(placeholder, text: $displayText)
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
                            processCardNumberInput(String(digits.prefix(19)))
                        } else {
                            processCardNumberInput(digits)
                        }
                    }
                    .onChange(of: isFocused) { focused in
                        // Only validate when focus is lost, but don't mask
                        if !focused {
                            validateCardNumber()
                        } else {
                            // Clear error state when focused
                            showError = false
                        }
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .background(backgroundColor)
            .cornerRadius(cornerRadius)

            // Bottom line indicator
            Rectangle()
                .fill(borderColor)
                .frame(height: 1)

            // Error message
            if showError {
                Text("Invalid card number")
                    .foregroundColor(tokens?.primerColorTextNegative ?? .red)
                    .padding(.leading, paddingValue)
                    .font(.system(size: 10, weight: .medium))
                    .accessibilityIdentifier("CardNumberErrorMessage")
            }
        }
        // 4) Animate error changes
        .animation(.easeInOut, value: showError)
    }

    // MARK: - Helper Methods

    /// Process card number input with formatting and card network detection
    private func processCardNumberInput(_ digits: String) {
        // Format for display
        let formatted = formatCardNumber(digits)

        // Only update if different to avoid loop
        if formatted != displayText {
            displayText = formatted
        }

        // Detect card network
        // Note: Use the existing CardNetwork functionality here
        let newNetwork = CardNetwork(cardNumber: digits)
        if newNetwork != cardNetwork {
            cardNetwork = newNetwork
            onCardNetworkChange?(cardNetwork)
        }
    }

    /// Validate the card number
    private func validateCardNumber() {
        let cardNumber = displayText.filter(\.isNumber)

        if cardNumber.isEmpty {
            showError = false
            onValidationChange?(nil)
            return
        }

        // Here we would use the existing card validation logic
        let isValid = cardNumber.isValidCardNumber
        showError = !isValid
        onValidationChange?(isValid)
    }

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

    // MARK: - Public API

    /// Gets the card number without formatting
    /// - Returns: The raw card number
    func getCardNumber() -> String {
        return displayText.filter(\.isNumber)
    }
}
