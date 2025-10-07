//
//  SplashScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default splash screen for CheckoutComponents
@available(iOS 15.0, *)
struct SplashScreen: View {
    @Environment(\.designTokens) private var tokens

    var body: some View {
        ZStack {
            // Clean white background to match Figma design
            Color.white
                .ignoresSafeArea()

            // Content container
            VStack(spacing: 16) {
                // Loading spinner (56px to match Figma)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2.0)
                    .frame(width: 56, height: 56)

                VStack(spacing: 4) {
                    // Primary loading message
                    Text(CheckoutComponentsStrings.loadingSecureCheckout)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(tokens?.primerColorTextPrimary ?? Color(red: 0x21/255, green: 0x21/255, blue: 0x21/255))
                        .multilineTextAlignment(.center)

                    // Secondary loading message
                    Text(CheckoutComponentsStrings.loadingWontTakeLong)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor((tokens?.primerColorTextPrimary ?? Color(red: 0x21/255, green: 0x21/255, blue: 0x21/255)).opacity(0.62))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
        }
    }
}
