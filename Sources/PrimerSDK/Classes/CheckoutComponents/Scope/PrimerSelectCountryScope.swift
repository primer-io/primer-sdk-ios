//
//  PrimerSelectCountryScope.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Scope interface for country selection functionality with search capabilities.
/// This protocol matches the Android Composable API exactly.
@MainActor
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
    /// Default implementation provides searchable country list.
    var screen: ((_ scope: PrimerSelectCountryScope) -> AnyView)? { get set }

    /// Search bar component for filtering countries.
    /// Default implementation provides standard search input.
    var searchBar: ((_ query: String, _ onQueryChange: @escaping (String) -> Void, _ placeholder: String) -> AnyView)? { get set }

    /// Individual country row/item component.
    /// Default implementation shows flag and country name.
    var countryItem: ((_ country: PrimerCountry, _ onSelect: @escaping () -> Void) -> AnyView)? { get set }

}

// MARK: - State Definition

/// Represents the current state of countries and search functionality.
public struct PrimerSelectCountryState: Equatable {
    /// Complete list of all available countries.
    public var countries: [PrimerCountry] = []

    /// Filtered list based on current search query.
    public var filteredCountries: [PrimerCountry] = []

    /// Current search query text.
    public var searchQuery: String = ""

    /// Indicates if countries are being loaded.
    public var isLoading: Bool = false

    public init(
        countries: [PrimerCountry] = [],
        filteredCountries: [PrimerCountry] = [],
        searchQuery: String = "",
        isLoading: Bool = false
    ) {
        self.countries = countries
        self.filteredCountries = filteredCountries
        self.searchQuery = searchQuery
        self.isLoading = isLoading
    }
}

// MARK: - Country Model

/// Represents a country available for selection.
/// This is the public model exposed through the scope interface.
public struct PrimerCountry: Equatable, Identifiable {
    /// ISO 3166-1 alpha-2 country code (e.g., "US", "GB").
    public let code: String

    /// Localized country name.
    public let name: String

    /// Optional flag emoji or image.
    public let flag: String?

    /// Dial code for phone numbers (e.g., "+1", "+44").
    public let dialCode: String?

    public var id: String { code }

    public init(
        code: String,
        name: String,
        flag: String? = nil,
        dialCode: String? = nil
    ) {
        self.code = code
        self.name = name
        self.flag = flag
        self.dialCode = dialCode
    }
}
