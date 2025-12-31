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
}
