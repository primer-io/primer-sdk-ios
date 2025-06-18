//
//  DefaultErrorScreen.swift
//
//
//  Created on 17.06.2025.
//

import SwiftUI

/// Default error screen shown when payment fails
@available(iOS 15.0, *)
internal struct DefaultErrorScreen: View {

    // MARK: - Properties

    let errorMessage: String

    // MARK: - State

    @Environment(\.designTokens) private var tokens
    @Environment(\.presentationMode) private var presentationMode
    @State private var isAnimating = false

    // MARK: - Initialization

    init(errorMessage: String = "An unexpected error occurred") {
        self.errorMessage = errorMessage
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Error Animation
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(0.2), value: isAnimating)
            }

            // Error Message
            VStack(spacing: 16) {
                Text("Payment Failed")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Additional Help Text
            VStack(spacing: 8) {
                Text("Common solutions:")
                    .font(.headline)
                    .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

                VStack(alignment: .leading, spacing: 6) {
                    HelpTextItem(text: "Check your card details and try again")
                    HelpTextItem(text: "Ensure you have sufficient funds")
                    HelpTextItem(text: "Contact your bank if the issue persists")
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(tokens?.primerColorGray100 ?? Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(tokens?.primerColorBorderOutlinedDefault ?? Color(.separator), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                Button("Try Again") {
                    // Handle retry logic
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(PrimaryButtonStyle(tokens: tokens))

                Button("Change Payment Method") {
                    // Handle payment method change
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(SecondaryButtonStyle(tokens: tokens))

                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .font(.body)
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Help Text Item

@available(iOS 15.0, *)
private struct HelpTextItem: View {
    let text: String
    @Environment(\.designTokens) private var tokens

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .font(.body)

            Text(text)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .font(.body)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}

// MARK: - Button Styles

@available(iOS 15.0, *)
private struct PrimaryButtonStyle: ButtonStyle {
    let tokens: DesignTokens?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(tokens?.primerColorBrand ?? .blue)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

@available(iOS 15.0, *)
private struct SecondaryButtonStyle: ButtonStyle {
    let tokens: DesignTokens?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(tokens?.primerColorBrand ?? .blue)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tokens?.primerColorBrand ?? .blue, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                    )
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct DefaultErrorScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DefaultErrorScreen(errorMessage: "Your card was declined. Please try a different payment method.")

            DefaultErrorScreen(errorMessage: "Network connection failed. Please check your internet connection and try again.")
        }
    }
}
