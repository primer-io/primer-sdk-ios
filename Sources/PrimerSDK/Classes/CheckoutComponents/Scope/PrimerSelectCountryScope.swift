//
//  PrimerSelectCountryScope.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Scope interface for country selection functionality with search capabilities.
@MainActor
@available(iOS 15.0, *)
public protocol PrimerSelectCountryScope: AnyObject {

    /// The current state of the country selection as an async stream.
    var state: AsyncStream<PrimerSelectCountryState> { get }

    // MARK: - Navigation Methods

    /// Called when a country is selected by the user.
    /// - Parameters:
    ///   - countryCode: The ISO country code (e.g., "US", "GB").
    ///   - countryName: The localized country name.
    func onCountrySelected(countryCode: String, countryName: String)

    /// Cancels country selection and returns to the previous screen.
    func onCancel()

    /// Updates the search query to filter countries.
    /// - Parameter query: The search text entered by the user.
    func onSearch(query: String)

    // MARK: - Customizable UI Components

    /// The entire country selection screen.
    var screen: ((_ scope: PrimerSelectCountryScope) -> AnyView)? { get set }

    /// Search bar component for filtering countries.
    var searchBar: ((_ query: String, _ onQueryChange: @escaping (String) -> Void, _ placeholder: String) -> AnyView)? { get set }

    /// Individual country row/item component.
    @available(iOS 15.0, *)
    var countryItem: ((_ country: PrimerCountry, _ onSelect: @escaping () -> Void) -> AnyView)? { get set }

}

// MARK: - State Definition

/// Represents the current state of countries and search functionality.
@available(iOS 15.0, *)
public struct PrimerSelectCountryState: Equatable {
    /// Complete list of all available countries.
    public var countries: [PrimerCountry] = []

    /// Filtered list based on current search query.
    public var filteredCountries: [PrimerCountry] = []

    /// Current search query text.
    public var searchQuery: String = ""

    /// Indicates if countries are being loaded.
    public var isLoading: Bool = false

    /// The currently selected country (nil if none selected yet).
    /// This is set when the user selects a country and can be observed by providers.
    public var selectedCountry: PrimerCountry?

    public init(
        countries: [PrimerCountry] = [],
        filteredCountries: [PrimerCountry] = [],
        searchQuery: String = "",
        isLoading: Bool = false,
        selectedCountry: PrimerCountry? = nil
    ) {
        self.countries = countries
        self.filteredCountries = filteredCountries
        self.searchQuery = searchQuery
        self.isLoading = isLoading
        self.selectedCountry = selectedCountry
    }
}
