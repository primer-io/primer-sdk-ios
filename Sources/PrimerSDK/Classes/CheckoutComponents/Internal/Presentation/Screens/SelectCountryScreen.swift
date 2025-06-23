//
//  SelectCountryScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default country selection screen for CheckoutComponents
@available(iOS 15.0, *)
internal struct SelectCountryScreen: View {
    let scope: PrimerSelectCountryScope
    let onDismiss: (() -> Void)?
    
    @Environment(\.designTokens) private var tokens
    @State private var countryState: PrimerSelectCountryScope.State = .init()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                if let customSearchBar = scope.searchBar {
                    customSearchBar { query in
                        scope.searchCountries(query)
                    }
                } else {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                        
                        TextField("Search countries...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: searchText) { newValue in
                                scope.searchCountries(newValue)
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                scope.searchCountries("")
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
                    .padding()
                }
                
                // Country list
                if countryState.filteredCountries.isEmpty {
                    // Empty state
                    if let customEmptyState = scope.emptyStateView {
                        customEmptyState()
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "globe")
                                .font(.system(size: 48))
                                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                            
                            Text("No countries found")
                                .font(.body)
                                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    List(countryState.filteredCountries) { country in
                        if let customCountryItem = scope.countryItem {
                            customCountryItem(country)
                                .onTapGesture {
                                    selectCountry(country)
                                }
                        } else {
                            CountryItemView(
                                country: country,
                                isSelected: countryState.selectedCountry?.code == country.code,
                                onTap: {
                                    selectCountry(country)
                                }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(tokens?.primerColorBackground ?? Color(.systemBackground))
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    onDismiss?()
                }
                .foregroundColor(tokens?.primerColorPrimary ?? .blue)
            )
        }
        .onAppear {
            observeState()
        }
    }
    
    private func selectCountry(_ country: PrimerCountry) {
        scope.selectCountry(country)
        onDismiss?()
    }
    
    private func observeState() {
        Task {
            for await state in scope.state {
                await MainActor.run {
                    self.countryState = state
                }
            }
        }
    }
}

/// Country item view
@available(iOS 15.0, *)
private struct CountryItemView: View {
    let country: PrimerCountry
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.designTokens) private var tokens
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Flag
                if let flag = country.flag {
                    Text(flag)
                        .font(.title2)
                }
                
                // Country name
                VStack(alignment: .leading, spacing: 2) {
                    Text(country.name)
                        .font(.body)
                        .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                    
                    if let dialCode = country.dialCode {
                        Text("\\(country.code) • \\(dialCode)")
                            .font(.caption)
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    } else {
                        Text(country.code)
                            .font(.caption)
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(tokens?.primerColorPrimary ?? .blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}