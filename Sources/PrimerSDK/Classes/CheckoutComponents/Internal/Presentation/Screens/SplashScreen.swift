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
            PrimerCheckoutColors.background(tokens: tokens)
                .ignoresSafeArea()

            VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: PrimerCheckoutColors.borderFocus(tokens: tokens)))
                    .scaleEffect(PrimerScale.large)
                    .frame(width: PrimerComponentHeight.progressIndicator, height: PrimerComponentHeight.progressIndicator)

                VStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                    // Primary loading message
                    Text(CheckoutComponentsStrings.loadingSecureCheckout)
                        .font(PrimerFont.bodyLarge(tokens: tokens))
                        .foregroundColor(PrimerCheckoutColors.textPrimary(tokens: tokens))
                        .multilineTextAlignment(.center)

                    // Secondary loading message
                    Text(CheckoutComponentsStrings.loadingWontTakeLong)
                        .font(PrimerFont.bodyMedium(tokens: tokens))
                        .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))
        }
    }
}
