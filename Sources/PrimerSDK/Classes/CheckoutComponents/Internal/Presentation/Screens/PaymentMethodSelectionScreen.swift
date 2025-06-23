//
//  PaymentMethodSelectionScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default payment method selection screen for CheckoutComponents
@available(iOS 15.0, *)
internal struct PaymentMethodSelectionScreen: View {
    let scope: PrimerPaymentMethodSelectionScope

    @Environment(\.designTokens) private var tokens
    @State private var selectionState: PrimerPaymentMethodSelectionState = .init()
    var body: some View {
        mainContent
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            titleSection
            paymentMethodsList
        }
        .onAppear {
            observeState()
        }
    }

    private var titleSection: some View {
        Text("Select Payment Method")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }

    private var paymentMethodsList: some View {
        VStack(spacing: 0) {
            ScrollView {
                if selectionState.categorizedPaymentMethods.isEmpty {
                    emptyStateView
                } else {
                    paymentMethodsContent
                }
            }

            errorSection
        }
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if let customEmptyState = scope.emptyStateView {
            customEmptyState()
        } else {
            VStack(spacing: 16) {
                Image(systemName: "creditcard.slash")
                    .font(.system(size: 48))
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

                Text("No payment methods available")
                    .font(.body)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
        }
    }

    private var paymentMethodsContent: some View {
        VStack(spacing: 24) {
            ForEach(selectionState.categorizedPaymentMethods, id: \.category) { categoryData in
                categorySection(categoryData)
            }
        }
        .padding(.vertical)
    }

    private func categorySection(_ categoryData: (category: String, methods: [PrimerComposablePaymentMethod])) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryHeader(categoryData.category)
            categoryMethods(categoryData.methods)
        }
    }

    @ViewBuilder
    private func categoryHeader(_ category: String) -> some View {
        if let customCategoryHeader = scope.categoryHeader {
            customCategoryHeader(category)
        } else {
            Text(category)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .textCase(.uppercase)
                .padding(.horizontal)
        }
    }

    private func categoryMethods(_ methods: [PrimerComposablePaymentMethod]) -> some View {
        VStack(spacing: 8) {
            ForEach(methods) { method in
                methodItem(method)
            }
        }
    }

    @ViewBuilder
    private func methodItem(_ method: PrimerComposablePaymentMethod) -> some View {
        if let customPaymentMethodItem = scope.paymentMethodItem {
            customPaymentMethodItem(method)
                .onTapGesture {
                    scope.onPaymentMethodSelected(paymentMethod: method)
                }
        } else {
            PaymentMethodItemView(
                method: method,
                isSelected: selectionState.selectedPaymentMethod?.id == method.id,
                onTap: {
                    scope.onPaymentMethodSelected(paymentMethod: method)
                }
            )
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = selectionState.error {
            Text(error)
                .font(.caption)
                .foregroundColor(tokens?.primerColorBorderOutlinedError ?? .red)
                .padding()
        }
    }

    private func observeState() {
        Task {
            for await state in scope.state {
                await MainActor.run {
                    self.selectionState = state
                }
            }
        }
    }
}

/// Payment method item view
@available(iOS 15.0, *)
private struct PaymentMethodItemView: View {
    let method: PrimerComposablePaymentMethod
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.designTokens) private var tokens

    var body: some View {
        Button(action: onTap) {
            contentView
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var contentView: some View {
        HStack(spacing: 16) {
            logoPlaceholder
            nameText
            Spacer()
            selectionIndicator
        }
        .padding()
        .background(backgroundView)
    }

    private var logoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(tokens?.primerColorGray200 ?? Color(.systemGray4))
            .frame(width: 40, height: 24)
            .overlay(logoText)
    }

    private var logoText: some View {
        Text(method.type.prefix(2))
            .font(.caption2)
            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
    }

    private var nameText: some View {
        Text(method.name)
            .font(.body)
            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(tokens?.primerColorTextPrimary ?? .blue)
        }
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(tokens?.primerColorGray100 ?? Color(.systemGray6))
            .overlay(borderOverlay)
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(
                isSelected ? (tokens?.primerColorTextPrimary ?? .blue) : Color.clear,
                lineWidth: 2
            )
    }
}
