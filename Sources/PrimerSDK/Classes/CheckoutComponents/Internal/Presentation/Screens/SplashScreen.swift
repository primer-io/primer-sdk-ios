//
//  SplashScreen.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default splash screen for CheckoutComponents
@available(iOS 15.0, *)
struct SplashScreen: View {
    @Environment(\.designTokens) private var tokens

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2.0)
                    .frame(width: 56, height: 56)

                VStack(spacing: 4) {
                    // Primary loading message
                    Text(CheckoutComponentsStrings.loadingSecureCheckout)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(tokens?.primerColorTextPrimary ?? .defaultTextPrimary)
                        .multilineTextAlignment(.center)

                    // Secondary loading message
                    Text(CheckoutComponentsStrings.loadingWontTakeLong)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor((tokens?.primerColorTextPrimary ?? .defaultTextPrimary).opacity(0.62))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
        }
    }
}
