//
//  PrimerCheckoutSheet.swift
//
//
//  Created by Boris on 17.3.25..
//

import SwiftUI

/// Default sheet UI for the Primer checkout experience.
@available(iOS 14.0, *)
struct PrimerCheckoutSheet: View {
    @ObservedObject var viewModel: PrimerCheckoutViewModel

    @State private var paymentMethods: [any PaymentMethodProtocol] = []
    @State private var selectedMethod: (any PaymentMethodProtocol)?

    @Environment(\.designTokens) private var tokens

    var body: some View {
        if #available(iOS 15.0, *) {
            mainContent
        } else {
            // Fallback for iOS 14
            legacyContent
        }
    }

    // Break down the view into smaller components
    @available(iOS 15.0, *)
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView

            if let selectedMethod = selectedMethod {
                selectedMethodView(selectedMethod)
            } else {
                paymentMethodsList
            }
        }
        .padding(16)
        .background(tokens?.primerColorBackground ?? .white)
        .task {
            for await methods in viewModel.paymentMethods() {
                paymentMethods = methods
            }
        }
        .task {
            for await method in viewModel.selectedPaymentMethod() {
                selectedMethod = method
            }
        }
    }

    private var headerView: some View {
        Text("Select Payment Method")
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
    }

    @available(iOS 15.0, *)
    private func selectedMethodView(_ method: any PaymentMethodProtocol) -> some View {
        VStack {
            HStack {
                Button(action: {
                    Task {
                        await viewModel.selectPaymentMethod(nil)
                    }
                }, label: {
                    HStack {
                        Image(systemName: "arrow.backward")
                        Text("Back")
                    }
                    .foregroundColor(tokens?.primerColorBrand ?? .blue)
                })
                Spacer()
            }
            .padding(.bottom, 16)

            method.defaultContent()
        }
        .padding(16)
        .background(tokens?.primerColorGray000 ?? .white)
        .cornerRadius(12)
    }

    private var paymentMethodsList: some View {
        ScrollView {
            PaymentMethodListContent(
                paymentMethods: paymentMethods,
                tokens: tokens,
                onSelect: { method in
                    Task {
                        await viewModel.selectPaymentMethod(method)
                    }
                }
            )
            .padding(16)
        }
    }

    // Fallback content for iOS 14
    private var legacyContent: some View {
        VStack {
            Text("Payment Methods")
                .font(.title)
                .padding()

            Text("Please update to iOS 15 or later for the full experience")
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct IdentifiablePaymentMethod: Identifiable {
    let id: String
    let method: any PaymentMethodProtocol

    init(_ method: any PaymentMethodProtocol) {
        // Safely convert any Hashable ID to a String
        self.id = String(describing: method.id)
        self.method = method
    }
}

struct PaymentMethodListContent: View {
    let paymentMethods: [any PaymentMethodProtocol]
    let tokens: DesignTokens?
    let onSelect: (any PaymentMethodProtocol) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(paymentMethods.map { IdentifiablePaymentMethod($0) }) { wrapper in
                Button {
                    onSelect(wrapper.method)
                } label: {
                    HStack {
                        Text(wrapper.method.name ?? "Payment Method")
                            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(tokens?.primerColorIconPrimary ?? .gray)
                    }
                    .padding(16)
                    .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
}
