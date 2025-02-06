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
    /// The closure receives an object conforming to PaymentMethodContentScope and returns an AnyView.
    private let customContent: ((any PaymentMethodContentScope) -> AnyView)?

    /// View model bridging the PaymentFlow actor with SwiftUI.
    @StateObject private var viewModel = PaymentFlowViewModel()

    /// Default initializer using the default UI.
    init(clientToken: String,
         onPaymentFinished: @escaping (PaymentResult) -> Void) {
        self.clientToken = clientToken
        self.onPaymentFinished = onPaymentFinished
        self.customContent = nil
        // TODO: Validate the client token if necessary.
    }

    /// Custom initializer that accepts a custom content closure.
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
                            // If a custom content closure was provided, use it;
                            // otherwise, render the default UI.
                            if let customContent = customContent {
                                customContent(scope)
                            } else {
                                scope.defaultContent()
                            }

                            // Button to submit payment.
                            Button("Submit Payment") {
                                Task {
                                    let result = await scope.submit()
                                    // NOTE: Replace force-unwrapping with proper error handling.
                                    try onPaymentFinished(result.get())
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
            // Using the default UI:
            PrimerCheckout(clientToken: "mock-token") { result in
                print("Payment finished with result: \(result)")
            }

            // Example of using a custom UI:
            /*
            PrimerCheckout(clientToken: "mock-token", onPaymentFinished: { result in
                print("Payment finished with result: \(result)")
            }) { scope in
                AnyView(
                    VStack {
                        Text("Custom UI for \(scope.method.name)")
                            .font(.title)
                            .foregroundColor(.blue)
                        // Add your custom form fields or elements here.
                    }
                    .padding()
                )
            }
            */
        } else {
            // Fallback on earlier versions
            Text("iOS 15 or newer is required.")
        }
    }
}
