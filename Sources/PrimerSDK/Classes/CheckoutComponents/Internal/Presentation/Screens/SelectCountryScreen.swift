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
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
        .navigationTitle("Select Country")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button("Cancel") {
                onDismiss?()
            }
            .foregroundColor(.blue)
        )
    }

    @MainActor
    private var searchBarSection: some View {
        Group {
            if let customSearchBar = scope.searchBar {
                customSearchBar(countryState.searchQuery, { query in
                    scope.onSearch(query: query)
                }, "Search countries...")
            } else {
                defaultSearchBar
            }
        }
    }

    @MainActor
    private var defaultSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            TextField("Search countries...", text: Binding(
                get: { countryState.searchQuery },
                set: { scope.onSearch(query: $0) }
            ))
            .textFieldStyle(PlainTextFieldStyle())

            if !countryState.searchQuery.isEmpty {
                Button(action: {
                    scope.onSearch(query: "")
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                })
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
        .cornerRadius(8)
        .padding()
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

    @MainActor
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

    @MainActor
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
                        .font(.title2)
                }

                // Country name
                VStack(alignment: .leading, spacing: 2) {
                    Text(country.name)
                        .font(.body)
                        .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

                    if let dialCode = country.dialCode {
                        Text("\(country.code) • \(dialCode)")
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
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
