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
        checkoutScope?.checkoutNavigator.navigateBack()
    }

    public func onCancel() {
        logger.debug(message: "Country selection cancelled")
        checkoutScope?.checkoutNavigator.navigateBack()
    }

    public func onSearch(query: String) {
        logger.debug(message: "Country search: \(query)")
        internalState.searchQuery = query
        filterCountries(with: query)
    }

    // MARK: - Private Methods

    private func loadAvailableCountries() {
        // Load available countries (this would normally come from configuration or a service)
        let sampleCountries = [
            PrimerCountry(code: "US", name: "United States", flag: "🇺🇸", dialCode: "+1"),
            PrimerCountry(code: "GB", name: "United Kingdom", flag: "🇬🇧", dialCode: "+44"),
            PrimerCountry(code: "DE", name: "Germany", flag: "🇩🇪", dialCode: "+49"),
            PrimerCountry(code: "FR", name: "France", flag: "🇫🇷", dialCode: "+33"),
            PrimerCountry(code: "ES", name: "Spain", flag: "🇪🇸", dialCode: "+34"),
            PrimerCountry(code: "IT", name: "Italy", flag: "🇮🇹", dialCode: "+39"),
            PrimerCountry(code: "CA", name: "Canada", flag: "🇨🇦", dialCode: "+1"),
            PrimerCountry(code: "AU", name: "Australia", flag: "🇦🇺", dialCode: "+61")
        ]

        internalState.countries = sampleCountries
        internalState.filteredCountries = sampleCountries
    }

    private func filterCountries(with query: String) {
        if query.isEmpty {
            internalState.filteredCountries = internalState.countries
        } else {
            internalState.filteredCountries = internalState.countries.filter { country in
                country.name.localizedCaseInsensitiveContains(query) ||
                    country.code.localizedCaseInsensitiveContains(query)
            }
        }
    }
}
