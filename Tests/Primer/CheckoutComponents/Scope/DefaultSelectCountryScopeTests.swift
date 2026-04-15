//
//  DefaultSelectCountryScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class DefaultSelectCountryScopeTests: XCTestCase {

    // MARK: - Properties

    private var sut: DefaultSelectCountryScope!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sut = DefaultSelectCountryScope(cardFormScope: nil)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_loadsCountries() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)

        // Then
        XCTAssertFalse(state.countries.isEmpty)
        XCTAssertEqual(state.countries.count, state.filteredCountries.count)
    }

    func test_init_countriesAreSortedAlphabetically() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)

        // Then
        let names = state.countries.map(\.name)
        XCTAssertEqual(names, names.sorted())
    }

    func test_init_searchQueryIsEmpty() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)

        // Then
        XCTAssertTrue(state.searchQuery.isEmpty)
    }

    func test_init_isLoadingIsFalse() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)

        // Then
        XCTAssertFalse(state.isLoading)
    }

    func test_init_selectedCountryIsNil() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)

        // Then
        XCTAssertNil(state.selectedCountry)
    }

    func test_init_countriesHaveValidCodes() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)

        // Then
        for country in state.countries {
            XCTAssertFalse(country.code.isEmpty)
            XCTAssertEqual(country.code.count, 2, "Country code '\(country.code)' should be 2 chars")
            XCTAssertEqual(country.code, country.code.uppercased(), "Country code should be uppercase")
        }
    }

    func test_init_countriesHaveNonEmptyNames() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)

        // Then
        for country in state.countries {
            XCTAssertFalse(country.name.isEmpty)
            XCTAssertNotEqual(country.name, "N/A")
        }
    }

    func test_init_countriesExcludeInvalidEntries() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)

        // Then
        let invalidCountries = state.countries.filter { $0.name == "N/A" || $0.name.isEmpty }
        XCTAssertTrue(invalidCountries.isEmpty, "Countries with N/A or empty names should be excluded")
    }

    func test_init_filteredCountriesMatchAllCountries() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)

        // Then
        XCTAssertEqual(state.filteredCountries, state.countries)
    }

    // MARK: - Search Tests

    func test_onSearch_emptyQuery_showsAllCountries() async throws {
        // Given
        let initialState = try await awaitFirst(sut.state)
        let totalCount = initialState.countries.count

        // When
        sut.onSearch(query: "")

        // Then
        let state = try await awaitFirst(sut.state)
        XCTAssertEqual(state.filteredCountries.count, totalCount)
        XCTAssertTrue(state.searchQuery.isEmpty)
    }

    func test_onSearch_byName_filtersCorrectly() async throws {
        // Given / When
        sut.onSearch(query: "United")

        // Then
        let state = try await awaitFirst(sut.state)
        XCTAssertFalse(state.filteredCountries.isEmpty)
        for country in state.filteredCountries {
            let nameMatch = country.name.localizedCaseInsensitiveContains("United")
            let codeMatch = country.code.localizedCaseInsensitiveContains("United")
            let dialMatch = country.dialCode?.contains("United") ?? false
            XCTAssertTrue(nameMatch || codeMatch || dialMatch,
                          "Country '\(country.name)' should match 'United'")
        }
    }

    func test_onSearch_byCountryCode_filtersCorrectly() async throws {
        // Given / When
        sut.onSearch(query: "US")

        // Then
        let state = try await awaitFirst(sut.state)
        XCTAssertFalse(state.filteredCountries.isEmpty)
        let matchesByCode = state.filteredCountries.contains { $0.code == "US" }
        XCTAssertTrue(matchesByCode)
    }

    func test_onSearch_byDialCode_filtersCorrectly() async throws {
        // Given / When
        sut.onSearch(query: "+1")

        // Then
        let state = try await awaitFirst(sut.state)
        let matchesByDialCode = state.filteredCountries.contains { $0.dialCode == "+1" }
        XCTAssertTrue(matchesByDialCode)
    }

    func test_onSearch_caseInsensitive_returnsResults() async throws {
        // Given / When
        sut.onSearch(query: "germany")

        // Then
        let state = try await awaitFirst(sut.state)
        let hasGermany = state.filteredCountries.contains { $0.code == "DE" }
        XCTAssertTrue(hasGermany)
    }

    func test_onSearch_diacriticInsensitive_returnsResults() async throws {
        // Given / When
        sut.onSearch(query: "Reunion")

        // Then
        let state = try await awaitFirst(sut.state)
        let hasReunion = state.filteredCountries.contains { $0.code == "RE" }
        XCTAssertTrue(hasReunion)
    }

    func test_onSearch_noMatch_returnsEmptyFilteredList() async throws {
        // Given / When
        sut.onSearch(query: "XYZNONEXISTENT")

        // Then
        let state = try await awaitFirst(sut.state)
        XCTAssertTrue(state.filteredCountries.isEmpty)
    }

    func test_onSearch_updatesSearchQuery() async throws {
        // Given
        let query = "France"

        // When
        sut.onSearch(query: query)

        // Then
        let state = try await awaitFirst(sut.state)
        XCTAssertEqual(state.searchQuery, query)
    }

    func test_onSearch_afterClearingQuery_restoresAllCountries() async throws {
        // Given
        let initialState = try await awaitFirst(sut.state)
        let totalCount = initialState.countries.count
        sut.onSearch(query: "Germany")

        let filteredState = try await awaitFirst(sut.state)
        XCTAssertTrue(filteredState.filteredCountries.count < totalCount)

        // When
        sut.onSearch(query: "")

        // Then
        let restoredState = try await awaitFirst(sut.state)
        XCTAssertEqual(restoredState.filteredCountries.count, totalCount)
    }

    func test_onSearch_sequentialSearches_updatesCorrectly() async throws {
        // Given / When / Then
        sut.onSearch(query: "Ger")
        let state1 = try await awaitFirst(sut.state)
        let count1 = state1.filteredCountries.count

        sut.onSearch(query: "Germany")
        let state2 = try await awaitFirst(sut.state)
        let count2 = state2.filteredCountries.count

        XCTAssertGreaterThanOrEqual(count1, count2,
                                     "More specific search should return same or fewer results")
    }

    func test_onSearch_doesNotMutateCountriesList() async throws {
        // Given
        let initialState = try await awaitFirst(sut.state)
        let originalCount = initialState.countries.count

        // When
        sut.onSearch(query: "Germany")

        // Then
        let state = try await awaitFirst(sut.state)
        XCTAssertEqual(state.countries.count, originalCount)
    }

    // MARK: - Country Selection Tests

    func test_onCountrySelected_withNilCardFormScope_doesNotCrash() {
        // Given - sut created with nil cardFormScope

        // When / Then - should not crash
        sut.onCountrySelected(countryCode: "US", countryName: "United States")
    }

    // MARK: - Cancel Tests

    func test_cancel_doesNotCrash() {
        // Given / When / Then - cancel is a no-op, should not crash
        sut.cancel()
    }

    // MARK: - UI Customization Property Tests

    func test_screen_defaultsToNil() {
        XCTAssertNil(sut.screen)
    }

    func test_searchBar_defaultsToNil() {
        XCTAssertNil(sut.searchBar)
    }

    func test_countryItem_defaultsToNil() {
        XCTAssertNil(sut.countryItem)
    }

    // MARK: - State Stream Tests

    func test_state_emitsCurrentState() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)

        // Then
        XCTAssertFalse(state.countries.isEmpty)
        XCTAssertFalse(state.filteredCountries.isEmpty)
    }

    func test_state_multipleSubscribers_eachReceivesState() async throws {
        // Given / When
        async let state1 = awaitFirst(sut.state)
        async let state2 = awaitFirst(sut.state)

        // Then
        let (s1, s2) = try await (state1, state2)
        XCTAssertEqual(s1.countries.count, s2.countries.count)
    }

    // MARK: - Country Data Integrity Tests

    func test_countriesContainCommonCountries() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)
        let codes = Set(state.countries.map(\.code))

        // Then
        XCTAssertTrue(codes.contains("US"), "Should contain United States")
        XCTAssertTrue(codes.contains("GB"), "Should contain United Kingdom")
        XCTAssertTrue(codes.contains("DE"), "Should contain Germany")
        XCTAssertTrue(codes.contains("FR"), "Should contain France")
        XCTAssertTrue(codes.contains("JP"), "Should contain Japan")
    }

    func test_countriesHaveUniqueCountryCodes() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)
        let codes = state.countries.map(\.code)
        let uniqueCodes = Set(codes)

        // Then
        XCTAssertEqual(codes.count, uniqueCodes.count, "Country codes should be unique")
    }

    func test_countriesWithDialCodes_haveValidFormat() async throws {
        // Given / When
        let state = try await awaitFirst(sut.state)
        let countriesWithDialCodes = state.countries.filter { $0.dialCode != nil }

        // Then
        XCTAssertFalse(countriesWithDialCodes.isEmpty, "Some countries should have dial codes")
        for country in countriesWithDialCodes {
            guard let dialCode = country.dialCode else { continue }
            XCTAssertTrue(dialCode.hasPrefix("+"),
                          "Dial code '\(dialCode)' for \(country.code) should start with +")
        }
    }
}
