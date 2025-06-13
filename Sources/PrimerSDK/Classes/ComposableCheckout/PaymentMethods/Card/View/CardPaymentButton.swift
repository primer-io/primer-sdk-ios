//
//  CardPaymentButton.swift
//  PrimerSDK
//
//  Created by Claude Code on 25.03.2025.
//

import SwiftUI

@available(iOS 15.0, *)
internal struct CardPaymentButton: View {
    let enabled: Bool
    let isLoading: Bool
    let amount: String?
    let action: () -> Void
    let animationConfig: CardPaymentAnimationConfiguration

    @Environment(\.designTokens) private var tokens
    @State private var isPressed = false

    init(
        enabled: Bool,
        isLoading: Bool = false,
        amount: String? = nil,
        action: @escaping () -> Void,
        animationConfig: CardPaymentAnimationConfiguration = .default
    ) {
        self.enabled = enabled
        self.isLoading = isLoading
        self.amount = amount
        self.action = action
        self.animationConfig = animationConfig
    }

    private var buttonText: String {
        if isLoading {
            return NSLocalizedString(
                "card_payment.button.processing",
                value: "Processing...",
                comment: "Pay button text when processing payment"
            )
        }

        return CardPaymentLocalizable.payButtonTextWithAmount(amount)
    }

    private var backgroundColor: Color {
        if !enabled || isLoading {
            return tokens?.primerColorGray400 ?? Color.gray
        }
        return tokens?.primerColorBrand ?? Color.blue
    }

    private var textColor: Color {
        return tokens?.primerColorGray000 ?? Color.white
    }

    var body: some View {
        Button(action: {
            guard enabled && !isLoading else { return }
            action()
        }) {
            HStack(spacing: CardPaymentDesign.fieldHorizontalSpacing(from: tokens)) {
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                // Button text
                Text(buttonText)
                    .font(CardPaymentDesign.buttonFont(from: tokens))
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: CardPaymentDesign.buttonHeight(from: tokens))
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CardPaymentDesign.buttonCornerRadius(from: tokens))
                    .fill(backgroundColor)
            )
            .overlay(
                // Loading state overlay
                RoundedRectangle(cornerRadius: CardPaymentDesign.buttonCornerRadius(from: tokens))
                    .stroke(
                        isLoading ? (tokens?.primerColorBrand ?? Color.blue).opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
                    .animation(animationConfig.layoutTransitionAnimation(), value: isLoading)
            )
        }
        .disabled(!enabled || isLoading)
        .cardPaymentButtonPress(isPressed: isPressed, config: animationConfig)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            guard enabled && !isLoading else { return }
            isPressed = pressing
        }, perform: {})
        .animation(animationConfig.layoutTransitionAnimation(), value: enabled)
        .animation(animationConfig.layoutTransitionAnimation(), value: isLoading)
        .accessibilityIdentifier("card_payment_button_pay")
        .accessibilityLabel(buttonText)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isLoading ? [.updatesFrequently] : [])
    }

    private var accessibilityHint: String {
        if isLoading {
            return CardPaymentLocalizable.paymentProcessingAnnouncement
        } else if enabled {
            return CardPaymentLocalizable.payButtonHintEnabled
        } else {
            return CardPaymentLocalizable.payButtonHintDisabled
        }
    }
}

// MARK: - Specialized Button Variants
@available(iOS 15.0, *)
internal struct CardPaymentSubmitButton: View {
    let enabled: Bool
    let isLoading: Bool
    let onSubmit: () -> Void
    let animationConfig: CardPaymentAnimationConfiguration

    init(
        enabled: Bool,
        isLoading: Bool = false,
        onSubmit: @escaping () -> Void,
        animationConfig: CardPaymentAnimationConfiguration = .default
    ) {
        self.enabled = enabled
        self.isLoading = isLoading
        self.onSubmit = onSubmit
        self.animationConfig = animationConfig
    }

    var body: some View {
        CardPaymentButton(
            enabled: enabled,
            isLoading: isLoading,
            amount: nil,
            action: onSubmit,
            animationConfig: animationConfig
        )
    }
}

// MARK: - Button with Custom Styling
@available(iOS 15.0, *)
internal struct CustomCardPaymentButton: View {
    let enabled: Bool
    let isLoading: Bool
    let title: String
    let backgroundColor: Color?
    let textColor: Color?
    let action: () -> Void
    let animationConfig: CardPaymentAnimationConfiguration

    @Environment(\.designTokens) private var tokens
    @State private var isPressed = false

    init(
        enabled: Bool,
        isLoading: Bool = false,
        title: String,
        backgroundColor: Color? = nil,
        textColor: Color? = nil,
        action: @escaping () -> Void,
        animationConfig: CardPaymentAnimationConfiguration = .default
    ) {
        self.enabled = enabled
        self.isLoading = isLoading
        self.title = title
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.action = action
        self.animationConfig = animationConfig
    }

    private var resolvedBackgroundColor: Color {
        if let backgroundColor = backgroundColor {
            return backgroundColor
        }

        if !enabled || isLoading {
            return tokens?.primerColorGray400 ?? Color.gray
        }
        return tokens?.primerColorBrand ?? Color.blue
    }

    private var resolvedTextColor: Color {
        return textColor ?? tokens?.primerColorGray000 ?? Color.white
    }

    var body: some View {
        Button(action: {
            guard enabled && !isLoading else { return }
            action()
        }) {
            HStack(spacing: CardPaymentDesign.fieldHorizontalSpacing(from: tokens)) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: resolvedTextColor))
                        .scaleEffect(0.8)
                }

                Text(title)
                    .font(CardPaymentDesign.buttonFont(from: tokens))
                    .fontWeight(.medium)
                    .foregroundColor(resolvedTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: CardPaymentDesign.buttonHeight(from: tokens))
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CardPaymentDesign.buttonCornerRadius(from: tokens))
                    .fill(resolvedBackgroundColor)
            )
        }
        .disabled(!enabled || isLoading)
        .cardPaymentButtonPress(isPressed: isPressed, config: animationConfig)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            guard enabled && !isLoading else { return }
            isPressed = pressing
        }, perform: {})
        .animation(animationConfig.layoutTransitionAnimation(), value: enabled)
        .animation(animationConfig.layoutTransitionAnimation(), value: isLoading)
    }
}

// MARK: - Button State Management Helper
@available(iOS 15.0, *)
internal class CardPaymentButtonState: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            errorMessage = nil
        }
    }

    func setError(_ error: String?) {
        errorMessage = error
        isLoading = false
    }

    func reset() {
        isEnabled = false
        isLoading = false
        errorMessage = nil
    }
}

// MARK: - Preview Provider
@available(iOS 15.0, *)
struct CardPaymentButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Enabled button
            CardPaymentButton(
                enabled: true,
                action: { print("Pay tapped") }
            )

            // Disabled button
            CardPaymentButton(
                enabled: false,
                action: { print("Pay tapped") }
            )

            // Loading button
            CardPaymentButton(
                enabled: true,
                isLoading: true,
                action: { print("Pay tapped") }
            )

            // Button with amount
            CardPaymentButton(
                enabled: true,
                amount: "$99.00",
                action: { print("Pay tapped") }
            )

            // Custom button
            CustomCardPaymentButton(
                enabled: true,
                title: "Custom Pay",
                backgroundColor: .green,
                textColor: .white,
                action: { print("Custom pay tapped") }
            )

            // No animations
            CardPaymentButton(
                enabled: true,
                action: { print("Pay tapped") },
                animationConfig: .disabled
            )
        }
        .padding()
        .previewDisplayName("Card Payment Buttons")

        VStack(spacing: 20) {
            CardPaymentButton(
                enabled: true,
                action: { print("Pay tapped") }
            )

            CardPaymentButton(
                enabled: false,
                action: { print("Pay tapped") }
            )
        }
        .padding()
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
