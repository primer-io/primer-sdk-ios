//
//  PrimerCheckout.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// A top‑level SwiftUI view for the Primer Checkout SDK.
@available(iOS 15.0, *)
struct PrimerCheckout: View {
    /// A valid client token used to initialize the payment flow.
    let clientToken: String
    /// Closure invoked when the payment process finishes.
    let onPaymentFinished: (PaymentResult) -> Void
    /// Optional custom content closure for merchants to build their own UI.
    private let customContent: ((any PaymentMethodContentScope) -> AnyView)?

    /// View model bridging the PaymentFlow actor with SwiftUI.
    @StateObject private var viewModel = PaymentFlowViewModel()
    /// Manages dynamic design tokens for light/dark mode or other themes.
    @StateObject private var tokensManager = DesignTokensManager()
    /// Reflects the system’s color scheme (light or dark).
    @Environment(\.colorScheme) private var colorScheme

    init(clientToken: String,
         onPaymentFinished: @escaping (PaymentResult) -> Void) {
        self.clientToken = clientToken
        self.onPaymentFinished = onPaymentFinished
        self.customContent = nil
    }

    init(clientToken: String,
         onPaymentFinished: @escaping (PaymentResult) -> Void,
         customContent: @escaping (any PaymentMethodContentScope) -> AnyView) {
        self.clientToken = clientToken
        self.onPaymentFinished = onPaymentFinished
        self.customContent = customContent
    }

    var body: some View {
        NavigationView {
            // Use a ScrollView to allow content to expand while still being scrollable.
            ScrollView {
                // Main container with styling
                VStack(alignment: .leading, spacing: 20) {
                    // Title / Header
                    Text("Select Payment Method")
                        .font(.system(size: 18, weight: .semibold))
                        // Use a brand color from design tokens if available
                        .foregroundColor(tokensManager.tokens?.primerColorBrand ?? .primary)
                        .padding(.top, 16)

                    // List of available payment methods
                    // We can wrap the List in a container that resembles the card form styling
                    VStack(spacing: 0) {
                        List(viewModel.paymentMethods, id: \.id) { method in
                            Button {
                                Task {
                                    await viewModel.selectMethod(method)
                                }
                            } label: {
                                Text(method.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        // Plain list style to reduce extra iOS styling
                        .listStyle(.plain)
                        .frame(height: 200)
                    }
                    .background(
                        (tokensManager.tokens?.primerColorGray000 ?? Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.14), lineWidth: 1)
                    )

                    // Render content for the selected method
                    if let selectedMethod = viewModel.selectedMethod {
                        viewModel.paymentFlow.paymentMethodContent(for: selectedMethod) { scope in
                            VStack(spacing: 16) {
                                // If the merchant has provided custom content, use it; otherwise default.
                                if let customContent = customContent {
                                    customContent(scope)
                                } else {
                                    scope.defaultContent()
                                }

                                // Submit Payment Button
                                Button("Submit Payment") {
                                    Task {
                                        let result = await scope.submit()
                                        switch result {
                                        case .success(let paymentResult):
                                            onPaymentFinished(paymentResult)
                                        case .failure(let error):
                                            let failedResult = PaymentResult(
                                                success: false,
                                                message: error.localizedDescription
                                            )
                                            onPaymentFinished(failedResult)
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!scope.validationState.isValid || scope.isLoading)
                            }
                            .padding(16)
                            .background(
                                (tokensManager.tokens?.primerColorGray000
                                 ?? Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
                            )
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(16)
                // Load payment methods and design tokens concurrently on appearance
                .task {
                    async let _ = viewModel.loadPaymentMethods()
                    do {
                        try await tokensManager.fetchTokens(for: colorScheme)
                    } catch {
                        print("Error loading tokens: \(error)")
                    }
                }
            }
            .navigationTitle("Primer Checkout")
        }
        // Inject tokens into environment so child views can style themselves
        .environment(\.designTokens, tokensManager.tokens)
    }
}
