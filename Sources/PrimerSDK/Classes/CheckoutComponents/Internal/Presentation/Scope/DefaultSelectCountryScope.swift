//
//  DefaultSelectCountryScope.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default implementation of PrimerSelectCountryScope with navigation integration
@available(iOS 15.0, *)
@MainActor
internal final class DefaultSelectCountryScope: PrimerSelectCountryScope, LogReporter {

    // MARK: - Properties

    @Published private var internalState = PrimerSelectCountryState()
    private weak var cardFormScope: DefaultCardFormScope?
    private weak var checkoutScope: DefaultCheckoutScope?

    /// State stream for external observation
    public var state: AsyncStream<PrimerSelectCountryState> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for await value in $internalState.values {
                    continuation.yield(value)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - UI Customization Properties

    public var screen: ((_ scope: PrimerSelectCountryScope) -> AnyView)?
    public var searchBar: ((_ query: String, _ onQueryChange: @escaping (String) -> Void, _ placeholder: String) -> AnyView)?
    public var countryItem: ((_ country: PrimerCountry, _ onSelect: @escaping () -> Void) -> AnyView)?

    // MARK: - Initialization

    init(cardFormScope: DefaultCardFormScope?, checkoutScope: DefaultCheckoutScope?) {
        self.cardFormScope = cardFormScope
        self.checkoutScope = checkoutScope
        loadAvailableCountries()
    }

    // MARK: - Navigation Methods

    public func onCountrySelected(countryCode: String, countryName: String) {
        logger.debug(message: "Country selected: \(countryName) (\(countryCode))")

        // Update the card form scope with selected country
        cardFormScope?.updateCountryCode(countryCode)

        // Navigate back to card form
        if let checkoutScope = checkoutScope {
            checkoutScope.checkoutNavigator.navigateBack()
        } else {
            // For sheet presentation, the sheet will be dismissed by the onDismiss callback
            logger.debug(message: "Country selection completed - sheet will be dismissed externally")
        }
    }

    public func onCancel() {
        logger.debug(message: "Country selection cancelled")
        if let checkoutScope = checkoutScope {
            checkoutScope.checkoutNavigator.navigateBack()
        } else {
            // For sheet presentation, the sheet will be dismissed by the onDismiss callback
            logger.debug(message: "Country selection cancelled - sheet will be dismissed externally")
        }
    }

    public func onSearch(query: String) {
        logger.debug(message: "Country search: \(query)")
        internalState.searchQuery = query
        filterCountries(with: query)
    }

    // MARK: - Private Methods

    private func loadAvailableCountries() {
        // Debug: Check if phone number country codes are loaded
        logger.debug(message: "Phone number country codes available: \(CountryCode.phoneNumberCountryCodes.count)")
        
        // Load all available countries from CountryCode enum with localization and dial codes
        let allCountries = CountryCode.allCases.compactMap { countryCode in
            convertCountryCodeToPrimerCountry(countryCode)
        }.sorted { $0.name < $1.name } // Sort alphabetically by localized name

        logger.debug(message: "Loaded \(allCountries.count) countries for selection")
        
        // Debug: Show first few countries with their dial codes
        let sampleCountries = allCountries.prefix(5)
        for country in sampleCountries {
            logger.debug(message: "Sample country: \(country.name) (\(country.code)) - \(country.dialCode ?? "no dial code")")
        }
        
        internalState.countries = allCountries
        internalState.filteredCountries = allCountries
    }
    
    /// Converts a CountryCode enum value to PrimerCountry model
    private func convertCountryCodeToPrimerCountry(_ countryCode: CountryCode) -> PrimerCountry? {
        let code = countryCode.rawValue
        let localizedName = countryCode.country
        let flagEmoji = countryCode.flag
        
        // Find matching dial code from phone number country codes
        let dialCode = CountryCode.phoneNumberCountryCodes
            .first { $0.code.uppercased() == code.uppercased() }?
            .dialCode
        
        // Debug logging for dial code matching
        if dialCode == nil {
            logger.debug(message: "No dial code found for country: \(code)")
        }
        
        // Only include countries that have valid localized names
        guard localizedName != "N/A" && !localizedName.isEmpty else {
            return nil
        }
        
        return PrimerCountry(
            code: code,
            name: localizedName,
            flag: flagEmoji,
            dialCode: dialCode
        )
    }

    private func filterCountries(with query: String) {
        if query.isEmpty {
            internalState.filteredCountries = internalState.countries
        } else {
            // Enhanced search with diacritic-insensitive and comprehensive filtering
            let normalizedQuery = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            
            internalState.filteredCountries = internalState.countries.filter { country in
                let normalizedCountryName = country.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
                let normalizedCountryCode = country.code.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
                
                // Search by country name, country code, or dial code
                return normalizedCountryName.contains(normalizedQuery) ||
                       normalizedCountryCode.contains(normalizedQuery) ||
                       (country.dialCode?.contains(query) ?? false)
            }
            
            logger.debug(message: "Filtered \(internalState.filteredCountries.count) countries for query: '\(query)'")
        }
    }
}
