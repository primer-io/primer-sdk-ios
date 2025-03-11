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
    @StateObject private var tokensManager = DesignTokensManager()
    @Environment(\.colorScheme) private var colorScheme

    init(clientToken: String,
         onPaymentFinished: @escaping (PaymentResult) -> Void) {
        self.clientToken = clientToken
        self.onPaymentFinished = onPaymentFinished
        self.customContent = nil
        // TODO: Validate the client token if necessary.
    }

    init(clientToken: String,
         onPaymentFinished: @escaping (PaymentResult) -> Void,
         customContent: @escaping (any PaymentMethodContentScope) -> AnyView) {
        self.clientToken = clientToken
        self.onPaymentFinished = onPaymentFinished
        self.customContent = customContent
        // TODO: Validate the client token if necessary.
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Payment Method")
                    .font(.headline)

                // Display a list of available payment methods.
                List(viewModel.paymentMethods, id: \.id, rowContent: { method in
                    Button(
                        action: {
                            Task {
                                await viewModel.selectMethod(method)
                            }
                        },
                        label: {
                            Text(method.name)
                        }
                    )
                })
                .frame(height: 200)

                // When a payment method is selected, render its content.
                if let selectedMethod = viewModel.selectedMethod {
                    viewModel.paymentFlow.paymentMethodContent(for: selectedMethod) { scope in
                        VStack(spacing: 16) {
                            // Use custom content if provided; otherwise, use default UI.
                            if let customContent = customContent {
                                customContent(scope)
                            } else {
                                scope.defaultContent()
                            }

                            // Button to submit payment.
                            Button("Submit Payment") {
                                Task {
                                    let result = await scope.submit()
                                    switch result {
                                    case .success(let paymentResult):
                                        onPaymentFinished(paymentResult)
                                    case .failure(let error):
                                        // Handle error by finishing with a failed PaymentResult.
                                        let failedResult = PaymentResult(success: false, message: error.localizedDescription)
                                        onPaymentFinished(failedResult)
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            // Disable button if input is invalid or the scope is loading.
                            .disabled(!scope.validationState.isValid || scope.isLoading)
                        }
                        .padding()
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding()
            .task {
                // Load payment methods and design tokens concurrently.
                async let _ = viewModel.loadPaymentMethods()
                do {
                    try await tokensManager.fetchTokens(for: colorScheme)
                } catch {
                    print("Error loading tokens: \(error)")
                }
            }
            .navigationTitle("Primer Checkout")
        }
        // Inject the fetched tokens into the environment for downstream views.
        .environment(\.designTokens, tokensManager.tokens)
    }
}
