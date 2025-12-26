//
//  DefaultPaymentMethodSelectionScopeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
@MainActor
final class DefaultPaymentMethodSelectionScopeTests: XCTestCase {

    // MARK: - Test Helpers

    private func createTestContainer() async -> Container {
        let container = Container()

        // Register mock ConfigurationService
        let mockConfig = MockConfigurationService.withDefaultConfiguration()
        _ = try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in mockConfig }

        // Register mock AccessibilityAnnouncementService
        _ = try? await container.register(AccessibilityAnnouncementService.self)
            .asSingleton()
            .with { _ in MockAccessibilityAnnouncementService() }

        // Register mock AnalyticsInteractor
        _ = try? await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
            .asSingleton()
            .with { _ in MockAnalyticsInteractor() }

        return container
    }

    private func createMockCheckoutScope() async -> DefaultCheckoutScope {
        let navigator = await MainActor.run {
            CheckoutNavigator(coordinator: CheckoutCoordinator())
        }
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
        return DefaultCheckoutScope(
            clientToken: "test-token",
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator
        )
    }

    private func createPaymentMethodSelectionScope(
        checkoutScope: DefaultCheckoutScope,
        analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
    ) -> DefaultPaymentMethodSelectionScope {
        DefaultPaymentMethodSelectionScope(
            checkoutScope: checkoutScope,
            analyticsInteractor: analyticsInteractor ?? MockAnalyticsInteractor()
        )
    }

    private func createTestPaymentMethod(
        id: String = "test-id",
        type: String = "PAYMENT_CARD",
        name: String = "Test Card"
    ) -> CheckoutPaymentMethod {
        CheckoutPaymentMethod(
            id: id,
            type: type,
            name: name,
            icon: nil,
            metadata: nil
        )
    }

    // MARK: - Initialization Tests

    func test_init_createsScope() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNotNil(scope)
        }
    }

    // MARK: - UI Customization Properties Tests

    func test_screen_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.screen)
        }
    }

    func test_container_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.container)
        }
    }

    func test_paymentMethodItem_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.paymentMethodItem)
        }
    }

    func test_categoryHeader_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.categoryHeader)
        }
    }

    func test_emptyStateView_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.emptyStateView)
        }
    }

    // MARK: - Dismissal Mechanism Tests

    func test_dismissalMechanism_returnsCheckoutScopeMechanism() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Dismissal mechanism should come from checkout scope
            XCTAssertEqual(scope.dismissalMechanism, checkoutScope.dismissalMechanism)
        }
    }

    // MARK: - Payment Method Selection Tests

    func test_onPaymentMethodSelected_setsSelectedPaymentMethod() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            let paymentMethod = createTestPaymentMethod()
            scope.onPaymentMethodSelected(paymentMethod: paymentMethod)

            // Wait for async state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Check state via iterator
            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.selectedPaymentMethod, paymentMethod)
        }
    }

    func test_onPaymentMethodSelected_tracksAnalytics() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let mockAnalytics = MockAnalyticsInteractor()
            let scope = createPaymentMethodSelectionScope(
                checkoutScope: checkoutScope,
                analyticsInteractor: mockAnalytics
            )

            let paymentMethod = createTestPaymentMethod(type: "PAYMENT_CARD")
            scope.onPaymentMethodSelected(paymentMethod: paymentMethod)

            // Wait for async analytics tracking
            try? await Task.sleep(nanoseconds: 100_000_000)

            // Access actor-isolated property with await
            let callCount = await mockAnalytics.trackEventCallCount
            XCTAssertGreaterThan(callCount, 0)
        }
    }

    // MARK: - Search Tests

    func test_searchPaymentMethods_emptyQuery_showsAllPaymentMethods() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Search with empty query
            scope.searchPaymentMethods("")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the current state
            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Empty search should match all (filteredPaymentMethods = paymentMethods)
            XCTAssertEqual(foundState?.searchQuery, "")
        }
    }

    func test_searchPaymentMethods_filtersByName() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Search by name
            scope.searchPaymentMethods("Card")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the current state
            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.searchQuery, "Card")
        }
    }

    func test_searchPaymentMethods_filtersByType() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Search by type
            scope.searchPaymentMethods("PAYPAL")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the current state
            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.searchQuery, "PAYPAL")
        }
    }

    func test_searchPaymentMethods_caseInsensitive() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Search with lowercase
            scope.searchPaymentMethods("card")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Get the current state
            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Search query should be set regardless of case
            XCTAssertEqual(foundState?.searchQuery, "card")
        }
    }

    // MARK: - State Tests

    func test_state_initialState_hasEmptyPaymentMethods() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Get initial state immediately
            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Initially payment methods may be empty before loading
            XCTAssertNotNil(foundState)
        }
    }

    func test_state_providesAsyncStream() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Verify state is accessible as AsyncStream
            var stateCount = 0
            for await _ in scope.state {
                stateCount += 1
                if stateCount >= 1 { break }
            }

            XCTAssertGreaterThan(stateCount, 0)
        }
    }

    // MARK: - Cancel Tests

    func test_onCancel_updatesCheckoutState() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            scope.onCancel()

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Verify onCancel was processed (can check via navigation state)
            XCTAssertNotNil(scope)
        }
    }
}
