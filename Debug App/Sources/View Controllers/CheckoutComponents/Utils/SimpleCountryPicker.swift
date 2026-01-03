//
//  SimpleCountryPicker.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Country Model

/// Simple country model with essential information
struct SimpleCountry: Identifiable, Equatable {
    let id: String // ISO country code
    let name: String
    let flag: String

    var code: String { id }
}

// MARK: - Country Data Provider

/// Provides a list of countries with their codes, names, and flags
enum CountryDataProvider {

    /// Returns all available countries sorted alphabetically by name
    static var allCountries: [SimpleCountry] {
        // Use NSLocale API which is available on iOS 13+
        let countryCodes = NSLocale.isoCountryCodes

        return countryCodes.compactMap { code in
            guard let name = Locale.current.localizedString(forRegionCode: code),
                  !name.isEmpty,
                  name != code else {
                return nil
            }
            let flag = flagEmoji(for: code)
            return SimpleCountry(id: code, name: name, flag: flag)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Converts country code to flag emoji
    private static func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                emoji.append(String(unicode))
            }
        }
        return emoji
    }

    /// Find a country by its code
    static func country(for code: String) -> SimpleCountry? {
        allCountries.first { $0.code.uppercased() == code.uppercased() }
    }
}

// MARK: - Country Picker View

/// A simple, plug-and-play country picker sheet
@available(iOS 15.0, *)
struct SimpleCountryPicker: View {
    @SwiftUI.Environment(\.presentationMode) private var presentationMode

    let selectedCountryCode: String?
    let onSelect: (SimpleCountry) -> Void

    @State private var searchText = ""
    @State private var countries: [SimpleCountry] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCountries) { country in
                    Button(action: {
                        onSelect(country)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Text(country.flag)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(country.name)
                                    .foregroundColor(.primary)
                                Text(country.code)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if country.code == selectedCountryCode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            countries = CountryDataProvider.allCountries
        }
    }

    private var filteredCountries: [SimpleCountry] {
        guard !searchText.isEmpty else {
            return countries
        }

        let normalizedSearch = searchText.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)

        return countries.filter { country in
            let normalizedName = country.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            let normalizedCode = country.code.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)

            return normalizedName.contains(normalizedSearch) || normalizedCode.contains(normalizedSearch)
        }
    }
}

// MARK: - Country Picker Button

/// A button that displays the selected country and opens the picker
@available(iOS 15.0, *)
struct CountryPickerButton: View {
    @Binding var selectedCountryCode: String?
    let placeholder: String

    @State private var showPicker = false

    var body: some View {
        Button(action: {
            showPicker = true
        }) {
            HStack {
                if let code = selectedCountryCode,
                   let country = CountryDataProvider.country(for: code) {
                    Text(country.flag)
                    Text(country.name)
                        .foregroundColor(.primary)
                } else {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPicker) {
            SimpleCountryPicker(
                selectedCountryCode: selectedCountryCode,
                onSelect: { country in
                    selectedCountryCode = country.code
                }
            )
        }
    }
}

// MARK: - Themed Country Picker Button

/// A country picker button that uses the demo theme colors
@available(iOS 15.0, *)
struct ThemedCountryPickerButton: View {
    @Binding var selectedCountryCode: String?
    let placeholder: String

    @State private var showPicker = false

    var body: some View {
        Button(action: {
            showPicker = true
        }) {
            HStack {
                if let code = selectedCountryCode,
                   let country = CountryDataProvider.country(for: code) {
                    Text(country.flag)
                    Text(country.name)
                        .foregroundColor(Color(red: 31/255, green: 41/255, blue: 55/255))
                } else {
                    Text(placeholder)
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPicker) {
            SimpleCountryPicker(
                selectedCountryCode: selectedCountryCode,
                onSelect: { country in
                    selectedCountryCode = country.code
                }
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 15.0, *)
#Preview("Country Picker") {
    SimpleCountryPicker(
        selectedCountryCode: "US",
        onSelect: { country in
            print("Selected: \(country.name) (\(country.code))")
        }
    )
}

@available(iOS 15.0, *)
#Preview("Country Button") {
    struct PreviewWrapper: View {
        @State private var selectedCode: String? = "RS"

        var body: some View {
            VStack(spacing: 20) {
                CountryPickerButton(
                    selectedCountryCode: $selectedCode,
                    placeholder: "Select a country"
                )

                if let code = selectedCode {
                    Text("Selected: \(code)")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}
#endif
