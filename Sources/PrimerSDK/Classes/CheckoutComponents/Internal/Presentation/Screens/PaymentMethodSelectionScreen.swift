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
    @State private var selectionState: PrimerPaymentMethodSelectionScope.State = .init()
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Select Payment Method")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            // Search bar
            if selectionState.paymentMethods.count > 5 { // Only show search if many methods
                if let customSearchBar = scope.searchBar {
                    customSearchBar { query in
                        scope.searchPaymentMethods(query)
                    }
                } else {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                        
                        TextField("Search payment methods...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: searchText) { newValue in
                                scope.searchPaymentMethods(newValue)
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                scope.searchPaymentMethods("")
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            
            // Payment methods list
            ScrollView {
                if selectionState.categorizedPaymentMethods.isEmpty {
                    // Empty state
                    if let customEmptyState = scope.emptyStateView {
                        customEmptyState()
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard.slash")
                                .font(.system(size: 48))
                                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                            
                            Text(searchText.isEmpty ? "No payment methods available" : "No results found")
                                .font(.body)
                                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    }
                } else {
                    VStack(spacing: 24) {
                        ForEach(selectionState.categorizedPaymentMethods, id: \.category) { categoryData in
                            VStack(alignment: .leading, spacing: 12) {
                                // Category header
                                if let customCategoryHeader = scope.categoryHeader {
                                    customCategoryHeader(categoryData.category)
                                } else {
                                    Text(categoryData.category)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                                        .textCase(.uppercase)
                                        .padding(.horizontal)
                                }
                                
                                // Payment methods in category
                                VStack(spacing: 8) {
                                    ForEach(categoryData.methods) { method in
                                        if let customPaymentMethodItem = scope.paymentMethodItem {
                                            customPaymentMethodItem(method)
                                                .onTapGesture {
                                                    scope.onPaymentMethodSelected(method)
                                                }
                                        } else {
                                            PaymentMethodItemView(
                                                method: method,
                                                isSelected: selectionState.selectedPaymentMethod?.id == method.id,
                                                onTap: {
                                                    scope.onPaymentMethodSelected(method)
                                                }
                                            )
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Error message
            if let error = selectionState.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(tokens?.primerColorError ?? .red)
                    .padding()
            }
        }
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
        .onAppear {
            observeState()
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
            HStack(spacing: 16) {
                // Logo placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(tokens?.primerColorGray200 ?? Color(.systemGray4))
                    .frame(width: 40, height: 24)
                    .overlay(
                        Text(method.type.prefix(2))
                            .font(.caption2)
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    )
                
                // Name
                Text(method.displayName)
                    .font(.body)
                    .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(tokens?.primerColorPrimary ?? .blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(tokens?.primerColorGray50 ?? Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? (tokens?.primerColorPrimary ?? .blue) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}