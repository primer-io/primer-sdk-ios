//
//  PrimerCheckout.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

// PrimerCheckout.swift

/// A top‑level SwiftUI view for the Primer Checkout SDK.
@available(iOS 15.0, *)
struct PrimerCheckout: View {
    /// A valid client token used to initialize the payment flow.
    let clientToken: String
    /// Closure invoked when the payment process finishes.
    let onPaymentFinished: (PaymentResult) -> Void

    /// View model bridging the PaymentFlow actor with SwiftUI.
    @StateObject private var viewModel = PaymentFlowViewModel()

    // Optionally, a custom content closure could be added here to allow merchants to build their own UI.
    // For now, the default UI is used.

    init(clientToken: String, onPaymentFinished: @escaping (PaymentResult) -> Void) {
        self.clientToken = clientToken
        self.onPaymentFinished = onPaymentFinished
        // TODO: Validate the client token if necessary.
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Payment Method")
                    .font(.headline)

                // Display a list of available payment methods.
                List(viewModel.paymentMethods, id: \.id) { method in
                    Button(action: {
                        Task {
                            await viewModel.selectMethod(method)
                        }
                    }) {
                        Text(method.name)
                    }
                }
                .frame(height: 200)

                // When a payment method is selected, render its content.
                if let selectedMethod = viewModel.selectedMethod {
                    viewModel.paymentFlow.paymentMethodContent(for: selectedMethod) { scope in
                        VStack(spacing: 16) {
                            // Render default content for the payment method.
                            scope.defaultContent()

                            // Button to submit payment.
                            Button("Submit Payment") {
                                Task {
                                    let result = await scope.submit()
                                    try onPaymentFinished(result.get())
                                    // TODO: Add proper error handling rather than force-unwrapping.
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            // TODO: Enable/disable the button based on state from getState().
                        }
                        .padding()
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Primer Checkout")
            .task {
                await viewModel.loadPaymentMethods()
            }
        }
    }
}

struct PrimerCheckout_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            PrimerCheckout(clientToken: "mock-token") { result in
                print("Payment finished with result: \(result)")
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
