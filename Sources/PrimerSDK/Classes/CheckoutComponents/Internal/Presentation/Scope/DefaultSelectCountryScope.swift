//
//  DefaultSelectCountryScope.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default implementation of PrimerSelectCountryScope
@available(iOS 15.0, *)
@MainActor
internal final class DefaultSelectCountryScope: PrimerSelectCountryScope, ObservableObject, LogReporter {
    // MARK: - Properties

    /// The current country selection state
    @Published private var internalState = PrimerSelectCountryScope.State()

    /// State stream for external observation
    public var state: AsyncStream<PrimerSelectCountryScope.State> {
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

    public var container: (@ViewBuilder (_ content: @escaping () -> any View) -> any View)?
    public var searchBar: (@ViewBuilder (_ searchText: @escaping (String) -> Void) -> any View)?
    public var countryItem: (@ViewBuilder (_ country: PrimerCountry) -> any View)?
    public var emptyStateView: (@ViewBuilder () -> any View)?

    // MARK: - Private Properties

    private var onCountrySelected: ((PrimerCountry) -> Void)?
    private let allCountries: [PrimerCountry]

    // MARK: - Initialization

    init(onCountrySelected: ((PrimerCountry) -> Void)? = nil) {
        self.onCountrySelected = onCountrySelected

        // Load all countries
        self.allCountries = CountryCode.allCases.map { countryCode in
            PrimerCountry(
                code: countryCode.rawValue,
                name: countryCode.localizedName,
                flag: countryCode.flag,
                dialCode: countryCode.dialCode
            )
        }.sorted { $0.name < $1.name }

        // Set initial state
        internalState.countries = allCountries
        internalState.filteredCountries = allCountries
    }

    // MARK: - Public Methods

    public func searchCountries(_ query: String) {
        log(logLevel: .debug, message: "Searching countries with query: \\(query)")

        internalState.searchQuery = query

        if query.isEmpty {
            internalState.filteredCountries = allCountries
        } else {
            let lowercasedQuery = query.lowercased()
            internalState.filteredCountries = allCountries.filter { country in
                country.name.lowercased().contains(lowercasedQuery) ||
                    country.code.lowercased().contains(lowercasedQuery) ||
                    (country.dialCode?.contains(query) ?? false)
            }
        }
    }

    public func selectCountry(_ country: PrimerCountry) {
        log(logLevel: .debug, message: "Country selected: \\(country.code) - \\(country.name)")

        internalState.selectedCountry = country
        onCountrySelected?(country)
    }
}

// MARK: - PrimerCountry Model

/// Represents a country for selection
@available(iOS 15.0, *)
public struct PrimerCountry: Identifiable {
    public let id: String
    public let code: String
    public let name: String
    public let flag: String?
    public let dialCode: String?

    public init(code: String, name: String, flag: String? = nil, dialCode: String? = nil) {
        self.id = code
        self.code = code
        self.name = name
        self.flag = flag
        self.dialCode = dialCode
    }
}

// MARK: - CountryCode Extension

extension CountryCode {
    var localizedName: String {
        let locale = Locale.current
        return locale.localizedString(forRegionCode: self.rawValue) ?? self.rawValue
    }

    var flag: String {
        // Convert country code to flag emoji
        let base: UInt32 = 127397
        var flag = ""
        for scalar in self.rawValue.unicodeScalars {
            if let unicodeScalar = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicodeScalar))
            }
        }
        return flag
    }

    var dialCode: String? {
        // This would need a proper mapping of country codes to dial codes
        // For now, return some common ones
        switch self {
        case .US: return "+1"
        case .GB: return "+44"
        case .FR: return "+33"
        case .DE: return "+49"
        case .ES: return "+34"
        case .IT: return "+39"
        case .CA: return "+1"
        case .AU: return "+61"
        case .JP: return "+81"
        case .CN: return "+86"
        case .IN: return "+91"
        case .BR: return "+55"
        case .MX: return "+52"
        case .NL: return "+31"
        case .BE: return "+32"
        case .CH: return "+41"
        case .SE: return "+46"
        case .NO: return "+47"
        case .DK: return "+45"
        case .FI: return "+358"
        case .PL: return "+48"
        default: return nil
        }
    }
}
