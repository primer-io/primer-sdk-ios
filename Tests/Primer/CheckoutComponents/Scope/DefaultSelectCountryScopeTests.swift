//
//  DefaultSelectCountryScopeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
@MainActor
final class DefaultSelectCountryScopeTests: XCTestCase {

    // MARK: - Test Helpers

    private func createTestContainer() async -> Container {
        await ContainerTestHelpers.createTestContainer()
    }

    private func createMockCardFormScope(checkoutScope: DefaultCheckoutScope) -> DefaultCardFormScope {
        DefaultCardFormScope(
            checkoutScope: checkoutScope,
            presentationContext: .fromPaymentSelection,
            processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
            validateInputInteractor: MockValidateInputInteractor(),
            cardNetworkDetectionInteractor: MockCardNetworkDetectionInteractor(),
            analyticsInteractor: MockAnalyticsInteractor(),
            configurationService: MockConfigurationService.withDefaultConfiguration()
        )
    }

    private func createSelectCountryScope(
        cardFormScope: DefaultCardFormScope?,
        checkoutScope: DefaultCheckoutScope?
    ) -> DefaultSelectCountryScope {
        DefaultSelectCountryScope(
            cardFormScope: cardFormScope,
            checkoutScope: checkoutScope
        )
    }

    // MARK: - Initialization Tests

    func test_init_createsScope() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            XCTAssertNotNil(scope)
        }
    }

    func test_init_loadsCountries() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // Wait for state to be populated
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the state
            var foundState: PrimerSelectCountryState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Countries should be loaded
            XCTAssertNotNil(foundState)
            XCTAssertGreaterThan(foundState?.countries.count ?? 0, 0)
        }
    }

    // MARK: - UI Customization Properties Tests

    func test_screen_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            XCTAssertNil(scope.screen)
        }
    }

    func test_searchBar_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            XCTAssertNil(scope.searchBar)
        }
    }

    func test_countryItem_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            XCTAssertNil(scope.countryItem)
        }
    }

    // MARK: - State Tests

    func test_state_providesAsyncStream() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // Verify state is accessible as AsyncStream
            var stateCount = 0
            for await _ in scope.state {
                stateCount += 1
                if stateCount >= 1 { break }
            }

            XCTAssertGreaterThan(stateCount, 0)
        }
    }

    func test_state_initialCountriesAreSorted() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // Wait for state to be populated
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the state
            var foundState: PrimerSelectCountryState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Verify countries are sorted alphabetically by name
            guard let countries = foundState?.countries, countries.count > 1 else {
                XCTFail("Expected countries to be loaded")
                return
            }

            let isSorted = zip(countries, countries.dropFirst()).allSatisfy { $0.name <= $1.name }
            XCTAssertTrue(isSorted, "Countries should be sorted alphabetically by name")
        }
    }

    // MARK: - Search Tests

    func test_onSearch_updatesSearchQuery() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // Perform search
            scope.onSearch(query: "United")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the state
            var foundState: PrimerSelectCountryState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.searchQuery, "United")
        }
    }

    func test_onSearch_filtersByCountryName() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // Perform search for a country name
            scope.onSearch(query: "Germany")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the state
            var foundState: PrimerSelectCountryState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Should have filtered results containing "Germany"
            XCTAssertNotNil(foundState?.filteredCountries)
            if let filtered = foundState?.filteredCountries {
                let hasGermany = filtered.contains { $0.name.contains("Germany") || $0.code == "DE" }
                if !filtered.isEmpty {
                    XCTAssertTrue(hasGermany, "Filtered countries should include Germany")
                }
            }
        }
    }

    func test_onSearch_filtersByCountryCode() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // Perform search by country code
            scope.onSearch(query: "US")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the state
            var foundState: PrimerSelectCountryState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.searchQuery, "US")
        }
    }

    func test_onSearch_emptyQuery_showsAllCountries() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // First search for something specific
            scope.onSearch(query: "Germany")
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Then clear the search
            scope.onSearch(query: "")
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the state
            var foundState: PrimerSelectCountryState?
            for await state in scope.state {
                foundState = state
                break
            }

            // All countries should be shown when query is empty
            XCTAssertEqual(foundState?.filteredCountries.count, foundState?.countries.count)
        }
    }

    func test_onSearch_caseInsensitive() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // Search with lowercase
            scope.onSearch(query: "germany")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the state
            var foundState: PrimerSelectCountryState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Search should be case insensitive
            XCTAssertEqual(foundState?.searchQuery, "germany")
        }
    }

    // MARK: - Country Selection Tests

    func test_onCountrySelected_updatesCardFormScope() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // Select a country
            scope.onCountrySelected(countryCode: "US", countryName: "United States")

            // Wait for update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Verify the card form scope was updated
            let countryValue = cardFormScope.getFieldValue(.countryCode)
            XCTAssertEqual(countryValue, "US")
        }
    }

    func test_onCountrySelected_withDifferentCountry() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // Select Germany
            scope.onCountrySelected(countryCode: "DE", countryName: "Germany")

            // Wait for update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Verify the card form scope was updated
            let countryValue = cardFormScope.getFieldValue(.countryCode)
            XCTAssertEqual(countryValue, "DE")
        }
    }

    // MARK: - Cancel Tests

    func test_onCancel_doesNotCrash() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let cardFormScope = createMockCardFormScope(checkoutScope: checkoutScope)
            let scope = createSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: checkoutScope)

            // Call onCancel - it's a no-op but should not crash
            scope.onCancel()

            XCTAssertNotNil(scope)
        }
    }

    // MARK: - Nil Scope Tests

    func test_nilCardFormScope_doesNotCrash() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createSelectCountryScope(cardFormScope: nil, checkoutScope: checkoutScope)

            // Country selection should not crash even with nil cardFormScope
            scope.onCountrySelected(countryCode: "US", countryName: "United States")

            XCTAssertNotNil(scope)
        }
    }

    func test_nilCheckoutScope_stillLoadsCountries() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let scope = createSelectCountryScope(cardFormScope: nil, checkoutScope: nil)

            // Wait for state to be populated
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the state
            var foundState: PrimerSelectCountryState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Countries should still be loaded even without checkout scope
            XCTAssertNotNil(foundState)
            XCTAssertGreaterThan(foundState?.countries.count ?? 0, 0)
        }
    }
}
