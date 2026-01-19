//
//  PrimerSelectCountryScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
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

    func onCancel()

    /// Updates the search query to filter countries.
    /// - Parameter query: The search text entered by the user.
    func onSearch(query: String)

    // MARK: - Customizable UI Components

    var screen: ((_ scope: PrimerSelectCountryScope) -> AnyView)? { get set }
    var searchBar: ((_ query: String, _ onQueryChange: @escaping (String) -> Void, _ placeholder: String) -> AnyView)? { get set }

    @available(iOS 15.0, *)
    var countryItem: CountryItemComponent? { get set }

}

// MARK: - State Definition

@available(iOS 15.0, *)
public struct PrimerSelectCountryState: Equatable {
    public var countries: [PrimerCountry] = []
    public var filteredCountries: [PrimerCountry] = []
    public var searchQuery: String = ""
    public var isLoading: Bool = false
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
