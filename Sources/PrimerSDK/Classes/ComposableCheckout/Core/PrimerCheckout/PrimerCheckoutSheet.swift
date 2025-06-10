//
//  PrimerCheckoutSheet.swift
//
//
//  Created by Boris on 17.3.25..
//

import SwiftUI

/// Default sheet UI for the Primer checkout experience.
@available(iOS 15.0, *)
struct PrimerCheckoutSheet: View, LogReporter {
    @ObservedObject var viewModel: PrimerCheckoutViewModel

    @State private var paymentMethods: [any PaymentMethodProtocol] = []
    @State private var selectedMethod: (any PaymentMethodProtocol)?

    @Environment(\.designTokens) private var tokens

    var body: some View {
        logger.debug(message: "🎨 [PrimerCheckoutSheet] Rendering body - payment methods: \(paymentMethods.count), selected: \(selectedMethod?.name ?? "none")")
        return VStack(spacing: 0) {
            headerView

            if let selectedMethod = selectedMethod {
                selectedMethodView(selectedMethod)
            } else {
                paymentMethodsList
            }
        }
        .padding(16)
        .background(tokens?.primerColorBackground ?? .white)
        .cornerRadius(12)
        .task {
            logger.info(message: "🌊 [PrimerCheckoutSheet] Starting payment methods stream task")
            for await methods in viewModel.paymentMethods() {
                logger.info(message: "📋 [PrimerCheckoutSheet] Received \(methods.count) payment methods from stream")
                for (index, method) in methods.enumerated() {
                    logger.debug(message: "📋 [PrimerCheckoutSheet] Method \(index + 1): \(method.name ?? "Unknown") (ID: \(method.id))")
                }
                paymentMethods = methods
            }
            logger.warn(message: "⚠️ [PrimerCheckoutSheet] Payment methods stream ended")
        }
        .task {
            logger.debug(message: "🌊 [PrimerCheckoutSheet] Starting selected payment method stream task")
            for await method in viewModel.selectedPaymentMethod() {
                logger.debug(message: "🎯 [PrimerCheckoutSheet] Selected method changed: \(method?.name ?? "nil")")
                selectedMethod = method
            }
            logger.warn(message: "⚠️ [PrimerCheckoutSheet] Selected payment method stream ended")
        }
        .onAppear {
            logger.info(message: "👁️ [PrimerCheckoutSheet] View appeared")
        }
        .onDisappear {
            logger.info(message: "👋 [PrimerCheckoutSheet] View disappeared")
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

    @ViewBuilder
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
