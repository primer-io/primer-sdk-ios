//
//  SuccessScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 27.6.25.
//

import SwiftUI

/// Success screen for CheckoutComponents with auto-dismiss functionality
@available(iOS 15.0, *)
struct SuccessScreen: View {
    let result: CheckoutPaymentResult
    let onDismiss: (() -> Void)?

    @Environment(\.designTokens) private var tokens
    @State private var dismissTimer: Timer?

    init(result: CheckoutPaymentResult, onDismiss: (() -> Void)? = nil) {
        self.result = result
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            // Clean white background to match Figma design
            Color.white
                .ignoresSafeArea()

            // Content container matching Figma layout
            VStack(spacing: 8) {
                // Success checkmark icon (56x56 to match Figma)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)

                VStack(spacing: 4) {
                    // Primary success message
                    Text(CheckoutComponentsStrings.paymentSuccessful)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(tokens?.primerColorTextPrimary ?? Color(red: 0x21/255, green: 0x21/255, blue: 0x21/255))
                        .multilineTextAlignment(.center)

                    // Secondary redirect message
                    Text(CheckoutComponentsStrings.redirectConfirmationMessage)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor((tokens?.primerColorTextPrimary ?? Color(red: 0x21/255, green: 0x21/255, blue: 0x21/255)).opacity(0.62))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            startAutoDismissTimer()
        }
        .onDisappear {
            dismissTimer?.invalidate()
            dismissTimer = nil
        }
    }

    private func startAutoDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            onDismiss?()
        }
    }
}
