//
//  SelectCountryStateTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for PrimerSelectCountryState struct.
@available(iOS 15.0, *)
final class SelectCountryStateTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_defaultInit_hasEmptyCountries() {
        let state = PrimerSelectCountryState()

        XCTAssertTrue(state.countries.isEmpty)
    }

    func test_defaultInit_hasEmptyFilteredCountries() {
        let state = PrimerSelectCountryState()

        XCTAssertTrue(state.filteredCountries.isEmpty)
    }

    func test_defaultInit_hasEmptySearchQuery() {
        let state = PrimerSelectCountryState()

        XCTAssertEqual(state.searchQuery, "")
    }

    func test_defaultInit_isNotLoading() {
        let state = PrimerSelectCountryState()

        XCTAssertFalse(state.isLoading)
    }

    func test_defaultInit_hasNoSelectedCountry() {
        let state = PrimerSelectCountryState()

        XCTAssertNil(state.selectedCountry)
    }

    func test_customInit_setsAllProperties() {
        // Given
        let countries = [
            PrimerCountry(code: "US", name: "United States", flag: "🇺🇸", dialCode: "+1"),
            PrimerCountry(code: "GB", name: "United Kingdom", flag: "🇬🇧", dialCode: "+44")
        ]
        let filteredCountries = [countries[0]]
        let selectedCountry = countries[0]

        // When
        let state = PrimerSelectCountryState(
            countries: countries,
            filteredCountries: filteredCountries,
            searchQuery: "united",
            isLoading: true,
            selectedCountry: selectedCountry
        )

        // Then
        XCTAssertEqual(state.countries.count, 2)
        XCTAssertEqual(state.filteredCountries.count, 1)
        XCTAssertEqual(state.searchQuery, "united")
        XCTAssertTrue(state.isLoading)
        XCTAssertEqual(state.selectedCountry?.code, "US")
    }

    // MARK: - Equatable Tests

    func test_equality_sameProperties_areEqual() {
        // Note: PrimerCountry uses UUID for id, so we must use same instances
        let countries = [
            PrimerCountry(code: "US", name: "United States")
        ]

        let state1 = PrimerSelectCountryState(
            countries: countries,
            filteredCountries: countries,
            searchQuery: "test",
            isLoading: false,
            selectedCountry: countries[0]
        )

        let state2 = PrimerSelectCountryState(
            countries: countries,
            filteredCountries: countries,
            searchQuery: "test",
            isLoading: false,
            selectedCountry: countries[0]
        )

        XCTAssertEqual(state1, state2)
    }

    func test_equality_differentSearchQuery_areNotEqual() {
        let state1 = PrimerSelectCountryState(searchQuery: "usa")
        let state2 = PrimerSelectCountryState(searchQuery: "uk")

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentLoadingState_areNotEqual() {
        let state1 = PrimerSelectCountryState(isLoading: true)
        let state2 = PrimerSelectCountryState(isLoading: false)

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentCountryCount_areNotEqual() {
        let state1 = PrimerSelectCountryState(
            countries: [PrimerCountry(code: "US", name: "United States")]
        )
        let state2 = PrimerSelectCountryState(countries: [])

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_emptyStates_areEqual() {
        let state1 = PrimerSelectCountryState()
        let state2 = PrimerSelectCountryState()

        XCTAssertEqual(state1, state2)
    }
}

// MARK: - PrimerCountry Tests

@available(iOS 15.0, *)
final class PrimerCountryTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_setsRequiredProperties() {
        let country = PrimerCountry(code: "US", name: "United States")

        XCTAssertEqual(country.code, "US")
        XCTAssertEqual(country.name, "United States")
    }

    func test_init_optionalPropertiesDefaultToNil() {
        let country = PrimerCountry(code: "US", name: "United States")

        XCTAssertNil(country.flag)
        XCTAssertNil(country.dialCode)
    }

    func test_init_setsAllProperties() {
        let country = PrimerCountry(
            code: "US",
            name: "United States",
            flag: "🇺🇸",
            dialCode: "+1"
        )

        XCTAssertEqual(country.code, "US")
        XCTAssertEqual(country.name, "United States")
        XCTAssertEqual(country.flag, "🇺🇸")
        XCTAssertEqual(country.dialCode, "+1")
    }

    // MARK: - Identifiable Tests

    func test_identifiable_generatesUniqueId() {
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "US", name: "United States")

        // Each instance gets a unique UUID
        XCTAssertNotEqual(country1.id, country2.id)
    }

    func test_id_isValidUUID() {
        let country = PrimerCountry(code: "GB", name: "United Kingdom")

        // Just verify id exists and has proper UUID format
        XCTAssertFalse(country.id.uuidString.isEmpty)
    }

    // MARK: - Equatable Tests

    func test_equality_sameInstance_isEqual() {
        let country = PrimerCountry(code: "US", name: "United States")

        XCTAssertEqual(country, country)
    }

    func test_equality_differentInstances_sameData_areNotEqual() {
        // Note: Due to UUID id, two instances are never equal even with same data
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "US", name: "United States")

        // Default synthesized Equatable compares all properties including id
        XCTAssertNotEqual(country1, country2)
    }

    // MARK: - Common Countries Tests

    func test_usCountry() {
        let country = PrimerCountry(code: "US", name: "United States", flag: "🇺🇸", dialCode: "+1")

        XCTAssertEqual(country.code, "US")
        XCTAssertEqual(country.flag, "🇺🇸")
        XCTAssertEqual(country.dialCode, "+1")
    }

    func test_ukCountry() {
        let country = PrimerCountry(code: "GB", name: "United Kingdom", flag: "🇬🇧", dialCode: "+44")

        XCTAssertEqual(country.code, "GB")
        XCTAssertEqual(country.flag, "🇬🇧")
        XCTAssertEqual(country.dialCode, "+44")
    }

    func test_germanyCountry() {
        let country = PrimerCountry(code: "DE", name: "Germany", flag: "🇩🇪", dialCode: "+49")

        XCTAssertEqual(country.code, "DE")
        XCTAssertEqual(country.flag, "🇩🇪")
        XCTAssertEqual(country.dialCode, "+49")
    }

    func test_franceCountry() {
        let country = PrimerCountry(code: "FR", name: "France", flag: "🇫🇷", dialCode: "+33")

        XCTAssertEqual(country.code, "FR")
        XCTAssertEqual(country.flag, "🇫🇷")
        XCTAssertEqual(country.dialCode, "+33")
    }

    // MARK: - Edge Cases

    func test_countryWithEmptyCode() {
        let country = PrimerCountry(code: "", name: "Unknown")

        XCTAssertEqual(country.code, "")
        XCTAssertEqual(country.name, "Unknown")
    }

    func test_countryWithLongName() {
        let longName = "The United Kingdom of Great Britain and Northern Ireland"
        let country = PrimerCountry(code: "GB", name: longName)

        XCTAssertEqual(country.name, longName)
    }

    func test_countryWithSpecialCharactersInName() {
        let country = PrimerCountry(code: "CI", name: "Côte d'Ivoire")

        XCTAssertEqual(country.name, "Côte d'Ivoire")
    }
}
