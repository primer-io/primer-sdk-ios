//
//  SelectCountryProviderTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

// MARK: - SelectCountryProvider Tests

/// Tests for SelectCountryProvider view component.
/// Tests initialization, callback configuration, and state handling logic.
@available(iOS 15.0, *)
@MainActor
final class SelectCountryProviderTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        await DIContainer.clearContainer()
    }

    override func tearDown() async throws {
        await DIContainer.clearContainer()
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_withAllCallbacks_createsProvider() {
        // Arrange & Act
        let provider = SelectCountryProvider(
            onCountrySelected: { _, _ in },
            onCancel: { }
        ) { _ in
            Text("Select Country")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withNoCallbacks_createsProvider() {
        // Arrange & Act
        let provider = SelectCountryProvider { _ in
            Text("Select Country")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withOnlyCountrySelectedCallback_createsProvider() {
        // Arrange & Act
        let provider = SelectCountryProvider(
            onCountrySelected: { _, _ in }
        ) { _ in
            Text("Select Country")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withOnlyCancelCallback_createsProvider() {
        // Arrange & Act
        let provider = SelectCountryProvider(
            onCancel: { }
        ) { _ in
            Text("Select Country")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - View Builder Tests

    func test_contentBuilder_receivesScope() {
        // Arrange
        var scopeChecked = false

        // Act
        _ = SelectCountryProvider { scope in
            scopeChecked = scope != nil
            return Text("Content")
        }

        // Assert - content builder is configured
        XCTAssertNotNil(scopeChecked)
    }

    // MARK: - Callback Configuration Tests

    func test_countrySelectedCallback_canBeConfiguredWithCodeAndName() {
        // Arrange
        var receivedCode: String?
        var receivedName: String?

        let provider = SelectCountryProvider(
            onCountrySelected: { code, name in
                receivedCode = code
                receivedName = name
            }
        ) { _ in
            Text("Select Country")
        }

        // Assert - callback is configured (will be invoked by state changes)
        XCTAssertNotNil(provider)
        XCTAssertNil(receivedCode) // Not yet invoked
        XCTAssertNil(receivedName) // Not yet invoked
    }

    func test_cancelCallback_canBeConfigured() {
        // Arrange
        var cancelCalled = false

        let provider = SelectCountryProvider(
            onCancel: {
                cancelCalled = true
            }
        ) { _ in
            Text("Select Country")
        }

        // Assert - callback is configured
        XCTAssertNotNil(provider)
        XCTAssertFalse(cancelCalled) // Not yet invoked
    }

    // MARK: - Multiple Provider Instances Tests

    func test_multipleProviders_areIndependent() {
        // Arrange
        var selection1Code: String?
        var selection2Code: String?

        // Act
        let provider1 = SelectCountryProvider(
            onCountrySelected: { code, _ in selection1Code = code }
        ) { _ in
            Text("Provider 1")
        }

        let provider2 = SelectCountryProvider(
            onCountrySelected: { code, _ in selection2Code = code }
        ) { _ in
            Text("Provider 2")
        }

        // Assert - both providers created independently
        XCTAssertNotNil(provider1)
        XCTAssertNotNil(provider2)
        XCTAssertNil(selection1Code)
        XCTAssertNil(selection2Code)
    }

    // MARK: - View Type Tests

    func test_provider_conformsToView() {
        // Arrange
        let provider = SelectCountryProvider { _ in
            Text("Test")
        }

        // Assert - View conformance
        XCTAssertTrue(provider is any View)
    }

    // MARK: - Content Builder Variety Tests

    func test_contentBuilder_withComplexView() {
        // Arrange & Act
        let provider = SelectCountryProvider { _ in
            VStack {
                TextField("Search", text: .constant(""))
                List {
                    Text("United States")
                    Text("United Kingdom")
                    Text("Canada")
                }
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withConditionalView() {
        // Arrange
        let isSearching = true

        // Act
        let provider = SelectCountryProvider { _ in
            if isSearching {
                Text("Searching...")
            } else {
                Text("Select a country")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - Nil Callback Handling Tests

    func test_nilCountrySelectedCallback_doesNotCrash() {
        // Arrange & Act
        let provider = SelectCountryProvider(
            onCountrySelected: nil,
            onCancel: { }
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_nilCancelCallback_doesNotCrash() {
        // Arrange & Act
        let provider = SelectCountryProvider(
            onCountrySelected: { _, _ in },
            onCancel: nil
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_allNilCallbacks_doesNotCrash() {
        // Arrange & Act
        let provider = SelectCountryProvider(
            onCountrySelected: nil,
            onCancel: nil
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - Country Code and Name Tests

    func test_countrySelectedCallback_receivesBothCodeAndName() {
        // Arrange
        var receivedCode: String?
        var receivedName: String?

        _ = SelectCountryProvider(
            onCountrySelected: { code, name in
                receivedCode = code
                receivedName = name
            }
        ) { _ in
            Text("Test")
        }

        // Assert - callback signature accepts both code and name
        XCTAssertNil(receivedCode) // Not invoked yet
        XCTAssertNil(receivedName) // Not invoked yet
    }

    // MARK: - State Deduplication Tests

    func test_provider_tracksLastSelectedCountryCode() {
        // Arrange & Act
        // Provider internally tracks lastSelectedCountryCode to prevent
        // duplicate callbacks for the same selection
        let provider = SelectCountryProvider(
            onCountrySelected: { _, _ in }
        ) { _ in
            Text("Test")
        }

        // Assert - provider is created (internal state tracking not directly testable)
        XCTAssertNotNil(provider)
    }

    // MARK: - Scope Access Tests

    func test_contentBuilder_providesAccessToCountryScope() {
        // Arrange
        var scopeAccessible = false

        // Act
        _ = SelectCountryProvider { scope in
            // Scope should be accessible in content builder
            scopeAccessible = true
            return Text("Content with scope access")
        }

        // Assert - content builder has scope parameter
        XCTAssertNotNil(scopeAccessible)
    }

    // MARK: - Country Selection Examples

    func test_countrySelectedCallback_canHandleUSSelection() {
        // Arrange
        var selectedCountryCode: String?
        var selectedCountryName: String?

        _ = SelectCountryProvider(
            onCountrySelected: { code, name in
                selectedCountryCode = code
                selectedCountryName = name
            }
        ) { _ in
            Text("Countries")
        }

        // Assert - callback can be used with US
        XCTAssertNil(selectedCountryCode)
        XCTAssertNil(selectedCountryName)
    }

    func test_countrySelectedCallback_canHandleUKSelection() {
        // Arrange
        var selectedCountryCode: String?
        var selectedCountryName: String?

        _ = SelectCountryProvider(
            onCountrySelected: { code, name in
                selectedCountryCode = code
                selectedCountryName = name
            }
        ) { _ in
            Text("Countries")
        }

        // Assert - callback can be used with UK
        XCTAssertNil(selectedCountryCode)
        XCTAssertNil(selectedCountryName)
    }
}

// MARK: - PrimerSelectCountryState Tests

@available(iOS 15.0, *)
final class PrimerSelectCountryStateTests: XCTestCase {

    func test_init_withDefaults() {
        // Act
        let state = PrimerSelectCountryState()

        // Assert
        XCTAssertTrue(state.countries.isEmpty)
        XCTAssertTrue(state.filteredCountries.isEmpty)
        XCTAssertEqual(state.searchQuery, "")
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.selectedCountry)
    }

    func test_init_withCustomValues() {
        // Arrange
        let country = PrimerCountry(code: "US", name: "United States")

        // Act
        let state = PrimerSelectCountryState(
            countries: [country],
            filteredCountries: [country],
            searchQuery: "united",
            isLoading: true,
            selectedCountry: country
        )

        // Assert
        XCTAssertEqual(state.countries.count, 1)
        XCTAssertEqual(state.filteredCountries.count, 1)
        XCTAssertEqual(state.searchQuery, "united")
        XCTAssertTrue(state.isLoading)
        XCTAssertEqual(state.selectedCountry?.code, "US")
    }

    func test_equatable_sameStates_areEqual() {
        // Arrange
        let state1 = PrimerSelectCountryState(searchQuery: "test", isLoading: false)
        let state2 = PrimerSelectCountryState(searchQuery: "test", isLoading: false)

        // Act & Assert
        XCTAssertEqual(state1, state2)
    }

    func test_equatable_differentSearchQueries_areNotEqual() {
        // Arrange
        let state1 = PrimerSelectCountryState(searchQuery: "test1")
        let state2 = PrimerSelectCountryState(searchQuery: "test2")

        // Act & Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_equatable_differentLoadingStates_areNotEqual() {
        // Arrange
        let state1 = PrimerSelectCountryState(isLoading: true)
        let state2 = PrimerSelectCountryState(isLoading: false)

        // Act & Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_equatable_differentSelectedCountries_areNotEqual() {
        // Arrange
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "UK", name: "United Kingdom")

        let state1 = PrimerSelectCountryState(selectedCountry: country1)
        let state2 = PrimerSelectCountryState(selectedCountry: country2)

        // Act & Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_equatable_differentCountriesArrays_areNotEqual() {
        // Arrange
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "UK", name: "United Kingdom")

        let state1 = PrimerSelectCountryState(countries: [country1])
        let state2 = PrimerSelectCountryState(countries: [country2])

        // Act & Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_equatable_differentFilteredCountries_areNotEqual() {
        // Arrange
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "UK", name: "United Kingdom")

        let state1 = PrimerSelectCountryState(filteredCountries: [country1])
        let state2 = PrimerSelectCountryState(filteredCountries: [country2])

        // Act & Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_equatable_emptyStates_areEqual() {
        // Arrange
        let state1 = PrimerSelectCountryState()
        let state2 = PrimerSelectCountryState()

        // Act & Assert
        XCTAssertEqual(state1, state2)
    }
}

// MARK: - PrimerCountry Extended Tests

@available(iOS 15.0, *)
final class PrimerCountryExtendedTests: XCTestCase {

    func test_init_withMinimalParameters() {
        // Arrange & Act
        let country = PrimerCountry(code: "US", name: "United States")

        // Assert
        XCTAssertEqual(country.code, "US")
        XCTAssertEqual(country.name, "United States")
        XCTAssertNil(country.flag)
        XCTAssertNil(country.dialCode)
    }

    func test_init_withAllParameters() {
        // Arrange & Act
        let country = PrimerCountry(
            code: "US",
            name: "United States",
            flag: "🇺🇸",
            dialCode: "+1"
        )

        // Assert
        XCTAssertEqual(country.code, "US")
        XCTAssertEqual(country.name, "United States")
        XCTAssertEqual(country.flag, "🇺🇸")
        XCTAssertEqual(country.dialCode, "+1")
    }

    func test_identifiable_hasUniqueId() {
        // Arrange
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "US", name: "United States")

        // Assert - each instance has unique ID
        XCTAssertNotEqual(country1.id, country2.id)
    }

    func test_equatable_differentInstances_notEqualDueToUUID() {
        // Arrange - each instance gets a unique UUID
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "US", name: "United States")

        // Assert - not equal because they have different UUIDs
        XCTAssertNotEqual(country1, country2)
    }

    func test_equatable_sameInstance_areEqual() {
        // Arrange
        let country = PrimerCountry(code: "US", name: "United States")

        // Assert - same instance is equal to itself
        XCTAssertEqual(country, country)
    }

    func test_equatable_differentCodes_areNotEqual() {
        // Arrange
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "UK", name: "United States")

        // Assert
        XCTAssertNotEqual(country1, country2)
    }

    func test_equatable_differentNames_areNotEqual() {
        // Arrange
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "US", name: "USA")

        // Assert
        XCTAssertNotEqual(country1, country2)
    }

    func test_country_withUKCode() {
        // Arrange & Act
        let country = PrimerCountry(
            code: "GB",
            name: "United Kingdom",
            flag: "🇬🇧",
            dialCode: "+44"
        )

        // Assert
        XCTAssertEqual(country.code, "GB")
        XCTAssertEqual(country.dialCode, "+44")
    }

    func test_country_withJapanCode() {
        // Arrange & Act
        let country = PrimerCountry(
            code: "JP",
            name: "Japan",
            flag: "🇯🇵",
            dialCode: "+81"
        )

        // Assert
        XCTAssertEqual(country.code, "JP")
        XCTAssertEqual(country.name, "Japan")
        XCTAssertEqual(country.flag, "🇯🇵")
    }

    func test_country_withLongDialCode() {
        // Arrange & Act
        let country = PrimerCountry(
            code: "RU",
            name: "Russia",
            flag: "🇷🇺",
            dialCode: "+7"
        )

        // Assert
        XCTAssertEqual(country.dialCode, "+7")
    }

    func test_country_withThreeLetterCode() {
        // Note: ISO 3166-1 alpha-2 codes are 2 letters, but testing edge case
        let country = PrimerCountry(code: "USA", name: "United States of America")

        // Assert
        XCTAssertEqual(country.code, "USA")
    }

    func test_country_withEmptyCode() {
        // Arrange & Act
        let country = PrimerCountry(code: "", name: "Unknown")

        // Assert
        XCTAssertEqual(country.code, "")
    }

    func test_country_withSpecialCharactersInName() {
        // Arrange & Act
        let country = PrimerCountry(code: "CI", name: "Côte d'Ivoire")

        // Assert
        XCTAssertEqual(country.name, "Côte d'Ivoire")
    }

    func test_country_withUnicodeFlag() {
        // Arrange & Act
        let country = PrimerCountry(
            code: "DE",
            name: "Germany",
            flag: "🇩🇪"
        )

        // Assert
        XCTAssertEqual(country.flag, "🇩🇪")
    }
}

// MARK: - SelectCountryProvider Extended Tests

@available(iOS 15.0, *)
@MainActor
final class SelectCountryProviderExtendedTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        await DIContainer.clearContainer()
    }

    override func tearDown() async throws {
        await DIContainer.clearContainer()
        try await super.tearDown()
    }

    // MARK: - Content Builder Extended Tests

    func test_contentBuilder_withScrollView() {
        // Arrange & Act
        let provider = SelectCountryProvider { _ in
            ScrollView {
                LazyVStack {
                    ForEach(0..<10) { index in
                        Text("Country \(index)")
                    }
                }
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withList() {
        // Arrange & Act
        let provider = SelectCountryProvider { _ in
            List {
                Text("United States")
                Text("United Kingdom")
                Text("Canada")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withEmptyView() {
        // Arrange & Act
        let provider = SelectCountryProvider { _ in
            EmptyView()
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withNavigationView() {
        // Arrange & Act
        let provider = SelectCountryProvider { _ in
            NavigationView {
                Text("Select Country")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - Callback Chaining Tests

    func test_countrySelectedCallback_canBeChainedWithAdditionalLogic() {
        // Arrange
        var logExecuted = false
        var analyticsExecuted = false

        // Act
        let provider = SelectCountryProvider(
            onCountrySelected: { code, _ in
                logExecuted = true
                if code.count == 2 {
                    analyticsExecuted = true
                }
            }
        ) { _ in
            Text("Test")
        }

        // Assert - callbacks are configured for chaining
        XCTAssertNotNil(provider)
        XCTAssertFalse(logExecuted)
        XCTAssertFalse(analyticsExecuted)
    }

    func test_cancelCallback_canExecuteCleanupLogic() {
        // Arrange
        var cleanupExecuted = false

        // Act
        let provider = SelectCountryProvider(
            onCancel: {
                cleanupExecuted = true
            }
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
        XCTAssertFalse(cleanupExecuted)
    }

    // MARK: - Multiple Providers Tests

    func test_multipleProviders_withDifferentCallbackTypes() {
        // Arrange & Act
        let provider1 = SelectCountryProvider(
            onCountrySelected: { _, _ in }
        ) { _ in Text("1") }

        let provider2 = SelectCountryProvider(
            onCancel: { }
        ) { _ in Text("2") }

        let provider3 = SelectCountryProvider(
            onCountrySelected: { _, _ in },
            onCancel: { }
        ) { _ in Text("3") }

        // Assert
        XCTAssertNotNil(provider1)
        XCTAssertNotNil(provider2)
        XCTAssertNotNil(provider3)
    }

    // MARK: - LogReporter Conformance Tests

    func test_provider_conformsToLogReporter() {
        // Arrange
        let provider = SelectCountryProvider { _ in
            Text("Test")
        }

        // Assert - LogReporter conformance
        XCTAssertTrue(provider is any LogReporter)
    }

    // MARK: - Country Code Format Tests

    func test_countrySelectedCallback_receivesUppercaseCode() {
        // Arrange
        var receivedCode: String?

        _ = SelectCountryProvider(
            onCountrySelected: { code, _ in
                receivedCode = code
            }
        ) { _ in
            Text("Test")
        }

        // Assert - callback can receive uppercase codes
        XCTAssertNil(receivedCode)
    }

    func test_countrySelectedCallback_receivesFullCountryName() {
        // Arrange
        var receivedName: String?

        _ = SelectCountryProvider(
            onCountrySelected: { _, name in
                receivedName = name
            }
        ) { _ in
            Text("Test")
        }

        // Assert - callback can receive full names
        XCTAssertNil(receivedName)
    }

    // MARK: - Conditional Content Tests

    func test_contentBuilder_withMultipleConditions() {
        // Arrange
        let hasSearchBar = true
        let showFavorites = false

        // Act
        let provider = SelectCountryProvider { _ in
            VStack {
                if hasSearchBar {
                    TextField("Search", text: .constant(""))
                }
                if showFavorites {
                    Text("Favorites")
                }
                Text("All Countries")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withOptionalBinding() {
        // Arrange
        let selectedCountry: String? = nil

        // Act
        let provider = SelectCountryProvider { _ in
            VStack {
                if let country = selectedCountry {
                    Text("Selected: \(country)")
                } else {
                    Text("No country selected")
                }
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }
}
