//
//  DefaultSelectCountryScope.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// NOTE: Currently card-specific - holds reference to DefaultCardFormScope for billing address.
/// If other payment methods require country selection in the future, this should be refactored
/// to accept a generic payment method context instead of being tied to card payments.
@available(iOS 15.0, *)
@MainActor
final class DefaultSelectCountryScope: PrimerSelectCountryScope, LogReporter {

    // MARK: - Properties

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
        if let cardFormScope {
            cardFormScope.updateCountryCode(countryCode)
        }

        if let checkoutScope {
            if !checkoutScope.availablePaymentMethods.isEmpty {
                if checkoutScope.availablePaymentMethods.count == 1,
                   let singleMethod = checkoutScope.availablePaymentMethods.first {
                    let previousState = DefaultCheckoutScope.NavigationState.paymentMethod(singleMethod.type)
                    checkoutScope.updateNavigationState(previousState, syncToNavigator: false)
                } else {
                    // NOTE: Country selection is currently card-specific (see cardFormScope property)
                    // TODO: If other payment methods need country selection in the future, store the
                    // originating payment method type instead of hardcoding to cards
                    let cardMethodType = PrimerPaymentMethodType.paymentCard.rawValue
                    let previousState = DefaultCheckoutScope.NavigationState.paymentMethod(cardMethodType)
                    checkoutScope.updateNavigationState(previousState, syncToNavigator: false)
                }
            } else {
                checkoutScope.updateNavigationState(.paymentMethodSelection, syncToNavigator: false)
            }
        }
    }

    public func onCancel() {
        if let checkoutScope {
            if !checkoutScope.availablePaymentMethods.isEmpty {
                if checkoutScope.availablePaymentMethods.count == 1,
                   let singleMethod = checkoutScope.availablePaymentMethods.first {
                    let previousState = DefaultCheckoutScope.NavigationState.paymentMethod(singleMethod.type)
                    checkoutScope.updateNavigationState(previousState, syncToNavigator: false)
                } else {
                    // NOTE: Country selection is currently card-specific (see cardFormScope property)
                    // TODO: If other payment methods need country selection in the future, store the
                    // originating payment method type instead of hardcoding to cards
                    let cardMethodType = PrimerPaymentMethodType.paymentCard.rawValue
                    let previousState = DefaultCheckoutScope.NavigationState.paymentMethod(cardMethodType)
                    checkoutScope.updateNavigationState(previousState, syncToNavigator: false)
                }
            } else {
                checkoutScope.updateNavigationState(.paymentMethodSelection, syncToNavigator: false)
            }
        }
    }

    public func onSearch(query: String) {
        internalState.searchQuery = query
        filterCountries(with: query)
    }

    // MARK: - Private Methods

    private func loadAvailableCountries() {
        let allCountries = CountryCode.allCases.compactMap { countryCode in
            convertCountryCodeToPrimerCountry(countryCode)
        }.sorted { $0.name < $1.name }

        internalState.countries = allCountries
        internalState.filteredCountries = allCountries
    }

    private func convertCountryCodeToPrimerCountry(_ countryCode: CountryCode) -> PrimerCountry? {
        let code = countryCode.rawValue
        let localizedName = countryCode.country
        let flagEmoji = countryCode.flag

        let dialCode = CountryCode.phoneNumberCountryCodes
            .first { $0.code.uppercased() == code.uppercased() }?
            .dialCode

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
            let normalizedQuery = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)

            internalState.filteredCountries = internalState.countries.filter { country in
                let normalizedCountryName = country.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
                let normalizedCountryCode = country.code.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)

                return normalizedCountryName.contains(normalizedQuery) ||
                    normalizedCountryCode.contains(normalizedQuery) ||
                    (country.dialCode?.contains(query) ?? false)
            }
        }
    }
}
