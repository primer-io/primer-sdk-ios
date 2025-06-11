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
            if let selectedMethod = selectedMethod {
                VStack(spacing: 0) {
                    headerView
                    selectedMethodView(selectedMethod)
                }
                .padding(16)
            } else {
                paymentMethodsListView
            }
        }
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

    private var paymentMethodsListView: some View {
        PaymentMethodsListView(
            amount: "Pay $99.00", // TODO: Get from viewModel
            onPaymentMethodSelected: { displayModel in
                logger.info(message: "🎯 [PrimerCheckoutSheet] Payment method selected: \(displayModel.name) (ID: \(displayModel.id))")
                logger.debug(message: "🔍 [PrimerCheckoutSheet] Available payment methods: \(paymentMethods.count)")
                for (index, pm) in paymentMethods.enumerated() {
                    logger.debug(message: "   \(index): \(pm.name ?? "Unknown") - Type: \(pm.type.rawValue) - ID: \(String(describing: pm.id))")
                }

                // Convert display model back to protocol method by finding matching payment method
                let method: (any PaymentMethodProtocol)? = {
                    switch displayModel.id {
                    case "payment_card":
                        logger.debug(message: "🔍 [PrimerCheckoutSheet] Looking for payment card...")
                        let found = paymentMethods.first(where: { $0.type == .paymentCard })
                        logger.debug(message: "🔍 [PrimerCheckoutSheet] Found card method: \(found != nil)")
                        return found
                    case "apple_pay":
                        logger.debug(message: "🔍 [PrimerCheckoutSheet] Looking for Apple Pay...")
                        return paymentMethods.first(where: { $0.type == .applePay })
                    case "paypal":
                        logger.debug(message: "🔍 [PrimerCheckoutSheet] Looking for PayPal...")
                        return paymentMethods.first(where: { $0.type == .payPal })
                    default:
                        logger.debug(message: "🔍 [PrimerCheckoutSheet] Using fallback matching for: \(displayModel.id)")
                        // Fallback: try to match by name or ID string representation
                        return paymentMethods.first(where: {
                            String(describing: $0.id) == displayModel.id || $0.name == displayModel.name
                        })
                    }
                }()

                if let method = method {
                    logger.info(message: "✅ [PrimerCheckoutSheet] Found matching payment method: \(method.name ?? "Unknown")")
                    Task {
                        logger.debug(message: "🚀 [PrimerCheckoutSheet] Calling viewModel.selectPaymentMethod...")
                        await viewModel.selectPaymentMethod(method)
                        logger.info(message: "✅ [PrimerCheckoutSheet] selectPaymentMethod completed")
                    }
                } else {
                    logger.warn(message: "⚠️ [PrimerCheckoutSheet] Could not find matching payment method for: \(displayModel.name) (ID: \(displayModel.id))")
                }
            }
        )
    }
}
