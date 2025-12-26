//
//  ApplePayScreen.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import PassKit

/// Default Apple Pay screen for CheckoutComponents.
/// Displays the Apple Pay button with loading and error states.
@available(iOS 15.0, *)
struct ApplePayScreen: View {

    // MARK: - Properties

    @ObservedObject private var scope: DefaultApplePayScope
    private let presentationContext: PresentationContext

    // MARK: - Initialization

    init(scope: DefaultApplePayScope, presentationContext: PresentationContext = .fromPaymentSelection) {
        self.scope = scope
        self.presentationContext = presentationContext
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            navigationBar

            // Content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Navigation Bar

    @ViewBuilder
    private var navigationBar: some View {
        HStack {
            // Back button (only show if from payment selection)
            if presentationContext.shouldShowBackButton {
                Button(action: {
                    scope.onBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.leading, 16)
            }

            Spacer()

            // Title
            Text("Apple Pay")
                .font(.headline)

            Spacer()

            // Cancel button
            Button(action: {
                scope.onDismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 16)
        }
        .frame(height: 56)
        .background(Color(.systemBackground))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if scope.isAvailable {
            availableContent
        } else {
            unavailableContent
        }
    }

    // MARK: - Available Content

    @ViewBuilder
    private var availableContent: some View {
        VStack(spacing: 24) {
            Spacer()

            // Apple Pay icon
            Image(systemName: "apple.logo")
                .font(.system(size: 60))
                .foregroundColor(.primary)

            // Instructions
            Text("Pay securely with Apple Pay")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Apple Pay button or loading
            if scope.structuredState.isLoading {
                loadingView
            } else {
                applePayButton
            }

            Spacer()
                .frame(height: 32)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Apple Pay Button

    @ViewBuilder
    private var applePayButton: some View {
        Group {
            if let customButton = scope.applePayButton {
                AnyView(customButton {
                    scope.pay()
                })
            } else {
                scope.PrimerApplePayButton {
                    scope.pay()
                }
            }
        }
        .frame(height: 50)
        .padding(.horizontal, 16)
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())

            Text("Processing...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(height: 50)
    }

    // MARK: - Unavailable Content

    @ViewBuilder
    private var unavailableContent: some View {
        VStack(spacing: 16) {
            Spacer()

            // Error icon
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            // Error message
            Text("Apple Pay Unavailable")
                .font(.headline)

            if let error = scope.availabilityError {
                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Back button
            if presentationContext.shouldShowBackButton {
                Button(action: {
                    scope.onBack()
                }) {
                    Text("Choose Another Payment Method")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
            }

            Spacer()
                .frame(height: 32)
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 15.0, *)
struct ApplePayScreen_Previews: PreviewProvider {
    static var previews: some View {
        // Preview would require mock scope
        Text("Apple Pay Screen Preview")
    }
}
#endif
