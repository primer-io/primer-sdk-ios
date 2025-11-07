//
//  DefaultSelectCountryScope.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default implementation of PrimerSelectCountryScope with navigation integration
@available(iOS 15.0, *)
@MainActor
final class DefaultSelectCountryScope: PrimerSelectCountryScope, LogReporter {

    // MARK: - Properties

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

    // MARK: - Private Properties

    @Published private var internalState = PrimerSelectCountryState()
    private weak var cardFormScope: DefaultCardFormScope?
    private weak var checkoutScope: DefaultCheckoutScope?

    // MARK: - Initialization

    init(cardFormScope: DefaultCardFormScope?, checkoutScope: DefaultCheckoutScope?) {
        self.cardFormScope = cardFormScope
        self.checkoutScope = checkoutScope
        loadAvailableCountries()
    }

    // MARK: - Navigation Methods

    public func onCountrySelected(countryCode: String, countryName: String) {
        // Country selected

        // Update the card form scope with selected country
        if let cardFormScope {
            cardFormScope.updateCountryCode(countryCode)
        } else {
            // CardFormScope is nil, cannot update country code
        }

        // For modal presentation, dismiss by restoring previous navigation state
        if let checkoutScope {
            // Find the previous payment method state to return to
            if !checkoutScope.availablePaymentMethods.isEmpty {
                if checkoutScope.availablePaymentMethods.count == 1,
                   let singleMethod = checkoutScope.availablePaymentMethods.first {
                    // Return to single payment method
                    let previousState = DefaultCheckoutScope.NavigationState.paymentMethod(singleMethod.type)
                    checkoutScope.updateNavigationState(previousState, syncToNavigator: false)
                } else {
                    // Assume we came from a payment method form, find which one
                    let cardMethodType = "PAYMENT_CARD"
                    let previousState = DefaultCheckoutScope.NavigationState.paymentMethod(cardMethodType)
                    checkoutScope.updateNavigationState(previousState, syncToNavigator: false)
                }
            } else {
                // Fallback to payment method selection
                checkoutScope.updateNavigationState(.paymentMethodSelection, syncToNavigator: false)
            }
        }
    }

    public func onCancel() {
        // Country selection cancelled
        if let checkoutScope {
            // For modal presentation, dismiss by restoring previous navigation state (same logic as onCountrySelected)
            if !checkoutScope.availablePaymentMethods.isEmpty {
                if checkoutScope.availablePaymentMethods.count == 1,
                   let singleMethod = checkoutScope.availablePaymentMethods.first {
                    // Return to single payment method
                    let previousState = DefaultCheckoutScope.NavigationState.paymentMethod(singleMethod.type)
                    checkoutScope.updateNavigationState(previousState, syncToNavigator: false)
                } else {
                    // Assume we came from a payment method form, find which one
                    let cardMethodType = "PAYMENT_CARD"
                    let previousState = DefaultCheckoutScope.NavigationState.paymentMethod(cardMethodType)
                    checkoutScope.updateNavigationState(previousState, syncToNavigator: false)
                }
            } else {
                // Fallback to payment method selection
                checkoutScope.updateNavigationState(.paymentMethodSelection, syncToNavigator: false)
            }
        } else {
            // For sheet presentation, the sheet will be dismissed by the onDismiss callback
        }
    }

    public func onSearch(query: String) {
        // Country search
        internalState.searchQuery = query
        filterCountries(with: query)
    }

    // MARK: - Private Methods

    private func loadAvailableCountries() {
        // Load all available countries from CountryCode enum with localization and dial codes
        let allCountries = CountryCode.allCases.compactMap { countryCode in
            convertCountryCodeToPrimerCountry(countryCode)
        }.sorted { $0.name < $1.name } // Sort alphabetically by localized name

        // Loaded countries for selection

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

        // Only include countries that have valid localized names
        guard localizedName != "N/A", !localizedName.isEmpty else {
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
        }
    }
}
