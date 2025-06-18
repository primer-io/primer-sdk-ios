//
//  DefaultSuccessScreen.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI

/// Default success screen shown after successful payment
@available(iOS 15.0, *)
internal struct DefaultSuccessScreen: View {
    
    @Environment(\.designTokens) private var tokens
    @Environment(\.presentationMode) private var presentationMode
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(0.2), value: isAnimating)
            }
            
            // Success Message
            VStack(spacing: 16) {
                Text("Payment Successful!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(tokens?.primerColorText ?? .primary)
                
                Text("Your payment has been processed successfully. You will receive a confirmation email shortly.")
                    .font(.body)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button("Continue") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(PrimaryButtonStyle(tokens: tokens))
                
                Button("View Receipt") {
                    // Handle receipt view
                }
                .buttonStyle(SecondaryButtonStyle(tokens: tokens))
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
struct DefaultSuccessScreen_Previews: PreviewProvider {
    static var previews: some View {
        DefaultSuccessScreen()
    }
}