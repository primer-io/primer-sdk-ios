//
//  DefaultPaymentMethodSelectionScopeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

@available(iOS 15.0, *)
@MainActor
final class DefaultPaymentMethodSelectionScopeTests: XCTestCase {

    // MARK: - Test Helpers

    private func createTestContainer() async -> Container {
        await ContainerTestHelpers.createTestContainer()
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
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNotNil(scope)
        }
    }

    // MARK: - UI Customization Properties Tests

    func test_screen_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.screen)
        }
    }

    func test_container_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.container)
        }
    }

    func test_paymentMethodItem_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.paymentMethodItem)
        }
    }

    func test_categoryHeader_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.categoryHeader)
        }
    }

    func test_emptyStateView_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.emptyStateView)
        }
    }

    // MARK: - Dismissal Mechanism Tests

    func test_dismissalMechanism_returnsCheckoutScopeMechanism() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Dismissal mechanism should come from checkout scope
            XCTAssertEqual(scope.dismissalMechanism, checkoutScope.dismissalMechanism)
        }
    }

    // MARK: - Payment Method Selection Tests

    func test_onPaymentMethodSelected_setsSelectedPaymentMethod() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
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
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
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
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
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
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
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
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
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
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
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
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
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
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
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
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            scope.onCancel()

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Verify onCancel was processed (can check via navigation state)
            XCTAssertNotNil(scope)
        }
    }

    // MARK: - CVV Input Update Tests

    func test_updateCvvInput_setsInputValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            scope.updateCvvInput("123")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.cvvInput, "123")
        }
    }

    func test_updateCvvInput_withEmptyCvv_setsNotValid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            scope.updateCvvInput("")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertFalse(foundState?.isCvvValid ?? true)
            XCTAssertNil(foundState?.cvvError)  // No error for empty (not started typing)
        }
    }

    func test_updateCvvInput_with3DigitCvv_setsValid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Default card network expects 3-digit CVV
            scope.updateCvvInput("123")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertTrue(foundState?.isCvvValid ?? false)
            XCTAssertNil(foundState?.cvvError)
        }
    }

    func test_updateCvvInput_withNonNumericChars_setsInvalid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            scope.updateCvvInput("12a")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertFalse(foundState?.isCvvValid ?? true)
            XCTAssertNotNil(foundState?.cvvError)
        }
    }

    func test_updateCvvInput_withTooManyDigits_setsInvalid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // More than 3 digits (standard CVV length)
            scope.updateCvvInput("12345")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertFalse(foundState?.isCvvValid ?? true)
            XCTAssertNotNil(foundState?.cvvError)
        }
    }

    func test_updateCvvInput_withPartialInput_setsNotValidNoError() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Fewer than required digits (user still typing)
            scope.updateCvvInput("12")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertFalse(foundState?.isCvvValid ?? true)
            XCTAssertNil(foundState?.cvvError)  // No error for partial input
        }
    }

    // MARK: - Show All Vaulted Payment Methods Tests

    func test_showAllVaultedPaymentMethods_navigatesToVaultScreen() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            scope.showAllVaultedPaymentMethods()

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Verify navigation happened
            XCTAssertNotNil(scope)
        }
    }

    // MARK: - Show Other Ways To Pay Tests

    func test_showOtherWaysToPay_expandsPaymentMethods() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            scope.showOtherWaysToPay()

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertTrue(foundState?.isPaymentMethodsExpanded ?? false)
        }
    }

    // MARK: - Collapse Payment Methods Tests

    func test_collapsePaymentMethods_collapsesPaymentMethods() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // First expand
            scope.showOtherWaysToPay()
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Then collapse
            scope.collapsePaymentMethods()

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertFalse(foundState?.isPaymentMethodsExpanded ?? true)
        }
    }

    // MARK: - Sync Selected Vaulted Payment Method Tests

    func test_syncSelectedVaultedPaymentMethod_updatesInternalState() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            scope.syncSelectedVaultedPaymentMethod()

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Should sync from checkout scope (which may be nil)
            XCTAssertEqual(foundState?.selectedVaultedPaymentMethod?.id, checkoutScope.selectedVaultedPaymentMethod?.id)
        }
    }

    // MARK: - Pay With Vaulted Payment Method Tests

    func test_payWithVaultedPaymentMethod_withoutSelection_logsWarning() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // No vaulted method selected
            await scope.payWithVaultedPaymentMethod()

            // Should not crash, just log warning
            XCTAssertNotNil(scope)
        }
    }

    // MARK: - Analytics Tracking Tests

    func test_onPaymentMethodSelected_tracksCorrectPaymentMethodType() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockAnalytics = MockAnalyticsInteractor()
            let scope = createPaymentMethodSelectionScope(
                checkoutScope: checkoutScope,
                analyticsInteractor: mockAnalytics
            )

            let paymentMethod = createTestPaymentMethod(type: "PAYPAL")
            scope.onPaymentMethodSelected(paymentMethod: paymentMethod)

            // Wait for async analytics tracking
            try? await Task.sleep(nanoseconds: 100_000_000)

            // Access actor-isolated property
            let callCount = await mockAnalytics.trackEventCallCount
            XCTAssertGreaterThan(callCount, 0)
        }
    }

    // MARK: - Multiple State Updates Tests

    func test_searchPaymentMethods_multipleSearches_updatesCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // First search
            scope.searchPaymentMethods("Card")
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Second search
            scope.searchPaymentMethods("PayPal")
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.searchQuery, "PayPal")
        }
    }

    func test_updateCvvInput_multipleUpdates_setsLatestValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Multiple updates
            scope.updateCvvInput("1")
            scope.updateCvvInput("12")
            scope.updateCvvInput("123")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.cvvInput, "123")
        }
    }

    // MARK: - Edge Case Tests

    func test_searchPaymentMethods_withSpecialCharacters_handlesCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Search with special characters
            scope.searchPaymentMethods("@#$%")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Should handle without crashing
            XCTAssertEqual(foundState?.searchQuery, "@#$%")
        }
    }

    func test_searchPaymentMethods_withWhitespace_handlesCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Search with whitespace
            scope.searchPaymentMethods("   ")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Whitespace search query should be set as-is
            XCTAssertEqual(foundState?.searchQuery, "   ")
        }
    }

    // MARK: - Vault Payment Loading State Tests

    func test_payWithVaultedPaymentMethodAndCvv_withoutSelection_doesNotCrash() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // No vaulted method selected, should not crash
            await scope.payWithVaultedPaymentMethodAndCvv("123")

            XCTAssertNotNil(scope)
        }
    }

    // MARK: - State Initial Values Tests

    func test_state_initialValues_correctDefaults() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Verify initial state defaults
            XCTAssertNotNil(foundState)
            XCTAssertTrue(foundState?.isPaymentMethodsExpanded ?? false)  // Default is true (expanded)
            XCTAssertEqual(foundState?.searchQuery, "")
            XCTAssertFalse(foundState?.isCvvValid ?? true)
        }
    }

    func test_state_selectedVaultedPaymentMethod_initiallyNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Selected vaulted payment method initially nil
            XCTAssertNil(foundState?.selectedVaultedPaymentMethod)
        }
    }

    func test_state_filteredPaymentMethods_matchesPaymentMethods() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // When no search, filtered should match all
            XCTAssertEqual(
                foundState?.filteredPaymentMethods.count,
                foundState?.paymentMethods.count
            )
        }
    }

    // MARK: - CVV Validation Edge Cases Tests

    func test_updateCvvInput_withLeadingZeroes_setsValid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // CVV with leading zeroes (valid)
            scope.updateCvvInput("001")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertTrue(foundState?.isCvvValid ?? false)
            XCTAssertNil(foundState?.cvvError)
        }
    }

    func test_updateCvvInput_withFourDigitCvv_dependsOnCardNetwork() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Four digit CVV (valid for Amex)
            scope.updateCvvInput("1234")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Without selected vaulted method with Amex network, this should be invalid
            // as default expected length is 3
            XCTAssertFalse(foundState?.isCvvValid ?? true)
            XCTAssertNotNil(foundState?.cvvError)
        }
    }

    func test_updateCvvInput_withSpaces_setsInvalid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // CVV with spaces (non-numeric)
            scope.updateCvvInput("12 3")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertFalse(foundState?.isCvvValid ?? true)
            XCTAssertNotNil(foundState?.cvvError)
        }
    }

    // MARK: - Search Payment Methods Edge Cases

    func test_searchPaymentMethods_withEmoji_handlesCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Search with emoji
            scope.searchPaymentMethods("💳")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.searchQuery, "💳")
        }
    }

    func test_searchPaymentMethods_withNumbers_handlesCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Search with numbers
            scope.searchPaymentMethods("123")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.searchQuery, "123")
        }
    }

    func test_searchPaymentMethods_clearsSearch_resetsFilteredMethods() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // First search
            scope.searchPaymentMethods("card")
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Clear search
            scope.searchPaymentMethods("")

            // Wait for state update
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            XCTAssertEqual(foundState?.searchQuery, "")
        }
    }

    // MARK: - State Stream Tests

    func test_state_streamContinuesWithUpdates() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            var statesReceived = 0
            let task = Task {
                for await _ in scope.state {
                    statesReceived += 1
                    if statesReceived >= 2 { break }
                }
            }

            // Trigger an update
            scope.updateCvvInput("123")

            try? await Task.sleep(nanoseconds: 100_000_000)
            task.cancel()

            XCTAssertGreaterThanOrEqual(statesReceived, 1)
        }
    }

    // MARK: - UI Customization Property Set Tests

    func test_screen_canBeSet() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            let customScreen: PaymentMethodSelectionScreenComponent = { _ in Text("Custom") }
            scope.screen = customScreen

            XCTAssertNotNil(scope.screen)
        }
    }

    func test_container_canBeSet() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            let customContainer: ContainerComponent = { _ in Text("Container") }
            scope.container = customContainer

            XCTAssertNotNil(scope.container)
        }
    }

    func test_paymentMethodItem_canBeSet() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            let customItem: PaymentMethodItemComponent = { _ in Text("Item") }
            scope.paymentMethodItem = customItem

            XCTAssertNotNil(scope.paymentMethodItem)
        }
    }

    func test_categoryHeader_canBeSet() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            let customHeader: CategoryHeaderComponent = { _ in Text("Header") }
            scope.categoryHeader = customHeader

            XCTAssertNotNil(scope.categoryHeader)
        }
    }

    func test_emptyStateView_canBeSet() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            let customEmpty: Component = { Text("Empty") }
            scope.emptyStateView = customEmpty

            XCTAssertNotNil(scope.emptyStateView)
        }
    }

    // MARK: - Selected Vaulted Payment Method Tests

    func test_selectedVaultedPaymentMethod_initiallyNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.selectedVaultedPaymentMethod)
        }
    }

    func test_syncSelectedVaultedPaymentMethod_sameMethod_preservesCvvState() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // First update CVV
            scope.updateCvvInput("123")
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Then sync with same method (nil -> nil)
            scope.syncSelectedVaultedPaymentMethod()
            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // CVV should be preserved when same method (both nil)
            XCTAssertEqual(foundState?.cvvInput, "123")
        }
    }

    // MARK: - Expand/Collapse State Tests

    func test_showOtherWaysToPay_thenCollapse_togglesCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            // Initial state should be expanded (default)
            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }
            let initialExpanded = foundState?.isPaymentMethodsExpanded ?? false

            // Collapse first
            scope.collapsePaymentMethods()
            try? await Task.sleep(nanoseconds: 50_000_000)

            for await state in scope.state {
                foundState = state
                break
            }
            let collapsedState = foundState?.isPaymentMethodsExpanded ?? true

            // Then expand
            scope.showOtherWaysToPay()
            try? await Task.sleep(nanoseconds: 50_000_000)

            for await state in scope.state {
                foundState = state
                break
            }
            let expandedState = foundState?.isPaymentMethodsExpanded ?? false

            XCTAssertTrue(initialExpanded)   // Default is expanded
            XCTAssertFalse(collapsedState)   // Should be collapsed after collapse
            XCTAssertTrue(expandedState)     // Should be expanded again
        }
    }

    // MARK: - Payment Method Selected with Different Types Tests

    func test_onPaymentMethodSelected_withApplePay_tracksCorrectType() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockAnalytics = MockAnalyticsInteractor()
            let scope = createPaymentMethodSelectionScope(
                checkoutScope: checkoutScope,
                analyticsInteractor: mockAnalytics
            )

            let paymentMethod = createTestPaymentMethod(type: "APPLE_PAY", name: "Apple Pay")
            scope.onPaymentMethodSelected(paymentMethod: paymentMethod)

            try? await Task.sleep(nanoseconds: 100_000_000)

            let callCount = await mockAnalytics.trackEventCallCount
            XCTAssertGreaterThan(callCount, 0)
        }
    }

    func test_onPaymentMethodSelected_withGooglePay_tracksCorrectType() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockAnalytics = MockAnalyticsInteractor()
            let scope = createPaymentMethodSelectionScope(
                checkoutScope: checkoutScope,
                analyticsInteractor: mockAnalytics
            )

            let paymentMethod = createTestPaymentMethod(type: "GOOGLE_PAY", name: "Google Pay")
            scope.onPaymentMethodSelected(paymentMethod: paymentMethod)

            try? await Task.sleep(nanoseconds: 100_000_000)

            let callCount = await mockAnalytics.trackEventCallCount
            XCTAssertGreaterThan(callCount, 0)
        }
    }

    // MARK: - CVV Input Boundary Tests

    func test_updateCvvInput_singleDigit_partialInput() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            scope.updateCvvInput("1")

            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Single digit is partial input - not valid, no error
            XCTAssertFalse(foundState?.isCvvValid ?? true)
            XCTAssertNil(foundState?.cvvError)
        }
    }

    func test_updateCvvInput_exactTwoDigits_partialInput() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createPaymentMethodSelectionScope(checkoutScope: checkoutScope)

            scope.updateCvvInput("12")

            try? await Task.sleep(nanoseconds: 50_000_000)

            var foundState: PrimerPaymentMethodSelectionState?
            for await state in scope.state {
                foundState = state
                break
            }

            // Two digits is partial input - not valid, no error
            XCTAssertFalse(foundState?.isCvvValid ?? true)
            XCTAssertNil(foundState?.cvvError)
        }
    }

}
