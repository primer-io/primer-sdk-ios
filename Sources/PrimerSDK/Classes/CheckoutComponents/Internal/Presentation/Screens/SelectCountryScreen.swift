//
//  SelectCountryScreen.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default country selection screen for CheckoutComponents
@available(iOS 15.0, *)
struct SelectCountryScreen: View {
    let scope: PrimerSelectCountryScope
    let onDismiss: (() -> Void)?

    @Environment(\.designTokens) private var tokens
    @State private var countryState: PrimerSelectCountryState = .init()

    var body: some View {
        NavigationView {
            mainContent
        }
        .onAppear {
            observeState()
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            searchBarSection
            countryListSection
        }
        .background(PrimerCheckoutColors.background(tokens: tokens))
        .navigationTitle(CheckoutComponentsStrings.selectCountryTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button(CheckoutComponentsStrings.cancelButton) {
                onDismiss?()
            }
            .foregroundColor(PrimerCheckoutColors.blue(tokens: tokens))
        )
    }

    private var searchBarSection: some View {
        Group {
            if let customSearchBar = scope.searchBar {
                customSearchBar(countryState.searchQuery, { query in
                    scope.onSearch(query: query)
                }, CheckoutComponentsStrings.searchCountriesPlaceholder)
            } else {
                defaultSearchBar
            }
        }
    }

    private var defaultSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))

            TextField(CheckoutComponentsStrings.searchCountriesPlaceholder, text: Binding(
                get: { countryState.searchQuery },
                set: { scope.onSearch(query: $0) }
            ))
            .textFieldStyle(PlainTextFieldStyle())

            if !countryState.searchQuery.isEmpty {
                Button(action: {
                    scope.onSearch(query: "")
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))
                })
            }
        }
        .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
        .padding(.vertical, PrimerSpacing.small(tokens: tokens))
        .background(PrimerCheckoutColors.gray100(tokens: tokens))
        .cornerRadius(PrimerRadius.small(tokens: tokens))
        .padding(PrimerSpacing.large(tokens: tokens))
    }

    private var countryListSection: some View {
        Group {
            if countryState.filteredCountries.isEmpty {
                emptyStateView
            } else {
                countryListView
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            Image(systemName: "globe")
                .font(PrimerFont.largeIcon(tokens: tokens))
                .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))

            Text(CheckoutComponentsStrings.noCountriesFound)
                .font(PrimerFont.body(tokens: tokens))
                .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var countryListView: some View {
        List {
            ForEach(countryState.filteredCountries, id: \.code) { country in
                Group {
                    if let customCountryItem = scope.countryItem {
                        customCountryItem(country) {
                            selectCountry(country)
                        }
                    } else {
                        AnyView(
                            CountryItemView(
                                country: country,
                                isSelected: false, // No selection state in current scope
                                onTap: {
                                    selectCountry(country)
                                }
                            )
                        )
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    private func selectCountry(_ country: PrimerCountry) {
        scope.onCountrySelected(countryCode: country.code, countryName: country.name)
        onDismiss?()
    }

    private func observeState() {
        Task {
            for await state in await scope.state {
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
                        .font(PrimerFont.title2(tokens: tokens))
                }

                // Country name
                VStack(alignment: .leading, spacing: PrimerSpacing.xxsmall(tokens: tokens)) {
                    Text(country.name)
                        .font(PrimerFont.body(tokens: tokens))
                        .foregroundColor(PrimerCheckoutColors.textPrimary(tokens: tokens))

                    if let dialCode = country.dialCode {
                        Text("\(country.code) • \(dialCode)")
                            .font(PrimerFont.caption(tokens: tokens))
                            .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))
                    } else {
                        Text(country.code)
                            .font(PrimerFont.caption(tokens: tokens))
                            .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(PrimerCheckoutColors.blue(tokens: tokens))
                }
            }
            .padding(.vertical, PrimerSpacing.small(tokens: tokens))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
