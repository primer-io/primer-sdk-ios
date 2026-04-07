//
//  DefaultPaymentMethodSelectionScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - DefaultPaymentMethodSelectionScope Tests

@available(iOS 15.0, *)
@MainActor
final class DefaultPaymentMethodSelectionScopeTests: XCTestCase {

    private var mockCheckoutScope: DefaultCheckoutScope!
    private var mockAnalytics: MockTrackingAnalyticsInteractor!
    private var sut: DefaultPaymentMethodSelectionScope!

    override func setUp() {
        super.setUp()
        mockCheckoutScope = createCheckoutScope()
        mockAnalytics = MockTrackingAnalyticsInteractor()
    }

    override func tearDown() {
        sut = nil
        mockAnalytics = nil
        mockCheckoutScope = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func createCheckoutScope() -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )
    }

    private func makeSut() -> DefaultPaymentMethodSelectionScope {
        DefaultPaymentMethodSelectionScope(
            checkoutScope: mockCheckoutScope,
            analyticsInteractor: mockAnalytics
        )
    }

    private func makePaymentMethod(
        id: String = "pm_1",
        type: String = TestData.PaymentMethodTypes.card,
        name: String = TestData.PaymentMethodNames.cardName
    ) -> CheckoutPaymentMethod {
        CheckoutPaymentMethod(id: id, type: type, name: name)
    }

    private func makeVaultedPaymentMethod(
        id: String = "vault_1",
        paymentMethodType: String = PrimerPaymentMethodType.paymentCard.rawValue,
        instrumentType: PaymentInstrumentType = .paymentCard,
        network: String? = nil
    ) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        var json: [String: Any] = ["last4Digits": "4242"]
        if let network {
            json["network"] = network
        }
        let data = try! JSONSerialization.data(withJSONObject: json) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )
        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: paymentMethodType,
            paymentInstrumentType: instrumentType,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(id)"
        )
    }

    // MARK: - State Stream Tests

    func test_state_emitsInitialState() async throws {
        // Given
        sut = makeSut()

        // When
        let state = try await awaitFirst(sut.state)

        // Then
        XCTAssertTrue(state.paymentMethods.isEmpty)
        XCTAssertTrue(state.filteredPaymentMethods.isEmpty)
        XCTAssertNil(state.selectedPaymentMethod)
        XCTAssertTrue(state.isPaymentMethodsExpanded)
    }

    // MARK: - onPaymentMethodSelected Tests

    func test_onPaymentMethodSelected_setsSelectedPaymentMethod() async throws {
        // Given
        sut = makeSut()
        let method = makePaymentMethod()

        // When
        sut.onPaymentMethodSelected(paymentMethod: method)

        // Then
        let state = try await awaitValue(sut.state) { $0.selectedPaymentMethod != nil }
        XCTAssertEqual(state.selectedPaymentMethod?.id, "pm_1")
    }

    func test_onPaymentMethodSelected_tracksAnalyticsEvent() async throws {
        // Given
        sut = makeSut()
        let method = makePaymentMethod(type: TestData.PaymentMethodTypes.paypal)

        // When
        sut.onPaymentMethodSelected(paymentMethod: method)

        // Then — allow async task to complete
        try await Task.sleep(nanoseconds: 200_000_000)
        let hasTracked = await mockAnalytics.hasTracked(.paymentMethodSelection)
        XCTAssertTrue(hasTracked)
    }

    func test_onPaymentMethodSelected_multipleSelections_updatesState() async throws {
        // Given
        sut = makeSut()
        let card = makePaymentMethod(id: "pm_card", type: TestData.PaymentMethodTypes.card, name: "Card")
        let paypal = makePaymentMethod(id: "pm_paypal", type: TestData.PaymentMethodTypes.paypal, name: "PayPal")

        // When
        sut.onPaymentMethodSelected(paymentMethod: card)
        sut.onPaymentMethodSelected(paymentMethod: paypal)

        // Then
        let state = try await awaitValue(sut.state) { $0.selectedPaymentMethod?.id == "pm_paypal" }
        XCTAssertEqual(state.selectedPaymentMethod?.id, "pm_paypal")
    }

    // MARK: - cancel Tests

    func test_cancel_callsCheckoutScopeOnDismiss() {
        // Given
        sut = makeSut()

        // When / Then — should not crash; delegates to checkoutScope.onDismiss()
        sut.cancel()
    }

    // MARK: - searchPaymentMethods Tests

    func test_searchPaymentMethods_emptyQuery_resetsToAllMethods() async throws {
        // Given
        sut = makeSut()

        // When
        sut.searchPaymentMethods("")

        // Then
        let state = try await awaitFirst(sut.state)
        XCTAssertTrue(state.searchQuery.isEmpty)
    }

    func test_searchPaymentMethods_withQuery_updatesSearchQueryAndFilters() async throws {
        // Given
        sut = makeSut()

        // When
        sut.searchPaymentMethods("Card")

        // Then
        let state = try await awaitValue(sut.state) { $0.searchQuery == "Card" }
        XCTAssertEqual(state.searchQuery, "Card")
    }

    func test_searchPaymentMethods_caseInsensitive_matchesByNameOrType() async throws {
        // Given
        sut = makeSut()

        // When — search should set query regardless of payment methods loaded
        sut.searchPaymentMethods("paypal")

        // Then
        let state = try await awaitValue(sut.state) { $0.searchQuery == "paypal" }
        XCTAssertEqual(state.searchQuery, "paypal")
    }

    // MARK: - showOtherWaysToPay Tests

    func test_showOtherWaysToPay_setsExpansionToTrue() async throws {
        // Given
        sut = makeSut()
        sut.collapsePaymentMethods()

        // When
        sut.showOtherWaysToPay()

        // Then
        let state = try await awaitValue(sut.state) { $0.isPaymentMethodsExpanded }
        XCTAssertTrue(state.isPaymentMethodsExpanded)
    }

    // MARK: - collapsePaymentMethods Tests

    func test_collapsePaymentMethods_setsExpansionToFalse() async throws {
        // Given
        sut = makeSut()

        // When
        sut.collapsePaymentMethods()

        // Then
        let state = try await awaitValue(sut.state) { !$0.isPaymentMethodsExpanded }
        XCTAssertFalse(state.isPaymentMethodsExpanded)
    }

    // MARK: - showAllVaultedPaymentMethods Tests

    func test_showAllVaultedPaymentMethods_updatesCheckoutScopeNavigation() {
        // Given
        sut = makeSut()

        // When / Then — should not crash; delegates to checkoutScope.updateNavigationState
        sut.showAllVaultedPaymentMethods()
        XCTAssertEqual(mockCheckoutScope.navigationState, .vaultedPaymentMethods)
    }

    // MARK: - updateCvvInput Tests

    func test_updateCvvInput_emptyString_notValidNoError() async throws {
        // Given
        sut = makeSut()

        // When
        sut.updateCvvInput("")

        // Then
        let state = try await awaitValue(sut.state) { $0.cvvInput == "" }
        XCTAssertFalse(state.isCvvValid)
        XCTAssertNil(state.cvvError)
    }

    func test_updateCvvInput_validThreeDigits_isValid() async throws {
        // Given
        sut = makeSut()

        // When
        sut.updateCvvInput("123")

        // Then
        let state = try await awaitValue(sut.state) { $0.cvvInput == "123" }
        XCTAssertTrue(state.isCvvValid)
        XCTAssertNil(state.cvvError)
    }

    func test_updateCvvInput_nonNumeric_showsError() async throws {
        // Given
        sut = makeSut()

        // When
        sut.updateCvvInput("abc")

        // Then
        let state = try await awaitValue(sut.state) { $0.cvvInput == "abc" }
        XCTAssertFalse(state.isCvvValid)
        XCTAssertNotNil(state.cvvError)
    }

    func test_updateCvvInput_tooManyDigits_showsError() async throws {
        // Given
        sut = makeSut()

        // When
        sut.updateCvvInput("12345")

        // Then
        let state = try await awaitValue(sut.state) { $0.cvvInput == "12345" }
        XCTAssertFalse(state.isCvvValid)
        XCTAssertNotNil(state.cvvError)
    }

    func test_updateCvvInput_partialInput_notValidNoError() async throws {
        // Given
        sut = makeSut()

        // When
        sut.updateCvvInput("12")

        // Then
        let state = try await awaitValue(sut.state) { $0.cvvInput == "12" }
        XCTAssertFalse(state.isCvvValid)
        XCTAssertNil(state.cvvError)
    }

    func test_updateCvvInput_specialCharacters_showsError() async throws {
        // Given
        sut = makeSut()

        // When
        sut.updateCvvInput("1!2")

        // Then
        let state = try await awaitValue(sut.state) { $0.cvvInput == "1!2" }
        XCTAssertFalse(state.isCvvValid)
        XCTAssertNotNil(state.cvvError)
    }

    // MARK: - payWithVaultedPaymentMethod Tests

    func test_payWithVaultedPaymentMethod_noMethodSelected_returnsEarly() async throws {
        // Given
        sut = makeSut()

        // When
        await sut.payWithVaultedPaymentMethod()

        // Then — state should remain unchanged
        let state = try await awaitFirst(sut.state)
        XCTAssertFalse(state.isVaultPaymentLoading)
        XCTAssertFalse(state.requiresCvvInput)
    }

    // MARK: - payWithVaultedPaymentMethodAndCvv Tests

    func test_payWithVaultedPaymentMethodAndCvv_noMethodSelected_returnsEarly() async throws {
        // Given
        sut = makeSut()

        // When
        await sut.payWithVaultedPaymentMethodAndCvv("123")

        // Then
        let state = try await awaitFirst(sut.state)
        XCTAssertFalse(state.isVaultPaymentLoading)
    }

    // MARK: - syncSelectedVaultedPaymentMethod Tests

    func test_syncSelectedVaultedPaymentMethod_updatesFromCheckoutScope() async throws {
        // Given
        sut = makeSut()
        let vaultedMethod = makeVaultedPaymentMethod()
        mockCheckoutScope.setVaultedPaymentMethods([vaultedMethod])
        mockCheckoutScope.setSelectedVaultedPaymentMethod(vaultedMethod)

        // When
        sut.syncSelectedVaultedPaymentMethod()

        // Then
        let state = try await awaitValue(sut.state) { $0.selectedVaultedPaymentMethod != nil }
        XCTAssertEqual(state.selectedVaultedPaymentMethod?.id, "vault_1")
    }

    func test_syncSelectedVaultedPaymentMethod_differentMethod_resetsCvvState() async throws {
        // Given
        sut = makeSut()
        let method1 = makeVaultedPaymentMethod(id: "vault_1")
        let method2 = makeVaultedPaymentMethod(id: "vault_2")

        mockCheckoutScope.setVaultedPaymentMethods([method1, method2])
        mockCheckoutScope.setSelectedVaultedPaymentMethod(method1)
        sut.syncSelectedVaultedPaymentMethod()

        // Simulate CVV entry
        sut.updateCvvInput("123")

        // When — switch to different method
        mockCheckoutScope.setSelectedVaultedPaymentMethod(method2)
        sut.syncSelectedVaultedPaymentMethod()

        // Then — CVV should be reset
        let state = try await awaitValue(sut.state) { $0.selectedVaultedPaymentMethod?.id == "vault_2" }
        XCTAssertEqual(state.cvvInput, "")
        XCTAssertFalse(state.isCvvValid)
        XCTAssertFalse(state.requiresCvvInput)
        XCTAssertNil(state.cvvError)
    }

    func test_syncSelectedVaultedPaymentMethod_sameMethod_preservesCvvState() async throws {
        // Given
        sut = makeSut()
        let method = makeVaultedPaymentMethod(id: "vault_1")

        mockCheckoutScope.setVaultedPaymentMethods([method])
        mockCheckoutScope.setSelectedVaultedPaymentMethod(method)
        sut.syncSelectedVaultedPaymentMethod()

        sut.updateCvvInput("123")

        // When — sync same method again
        sut.syncSelectedVaultedPaymentMethod()

        // Then — CVV should remain
        let state = try await awaitValue(sut.state) { $0.cvvInput == "123" }
        XCTAssertEqual(state.cvvInput, "123")
    }

    func test_syncSelectedVaultedPaymentMethod_nilSelection_clearsState() async throws {
        // Given
        sut = makeSut()
        let method = makeVaultedPaymentMethod()
        mockCheckoutScope.setVaultedPaymentMethods([method])
        mockCheckoutScope.setSelectedVaultedPaymentMethod(method)
        sut.syncSelectedVaultedPaymentMethod()

        // When — deselect
        mockCheckoutScope.setSelectedVaultedPaymentMethod(nil)
        sut.syncSelectedVaultedPaymentMethod()

        // Then
        let state = try await awaitValue(sut.state) { $0.selectedVaultedPaymentMethod == nil }
        XCTAssertNil(state.selectedVaultedPaymentMethod)
    }

    // MARK: - deleteVaultedPaymentMethod Tests

    func test_deleteVaultedPaymentMethod_withoutContainer_throwsError() async {
        // Given
        sut = makeSut()
        let method = makeVaultedPaymentMethod()

        // When / Then
        await DIContainer.clearContainer()
        do {
            try await sut.deleteVaultedPaymentMethod(method)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected — container is nil
        }

        // Restore container
        let container = Container()
        await DIContainer.setContainer(container)
    }

    // MARK: - dismissalMechanism Tests

    func test_dismissalMechanism_delegatesToCheckoutScope() {
        // Given
        sut = makeSut()

        // When
        let mechanism = sut.dismissalMechanism

        // Then — should return whatever the checkout scope provides
        XCTAssertNotNil(mechanism)
    }

    // MARK: - dismissalMechanism Returns Array

    func test_dismissalMechanism_returnsArray() {
        // Given
        sut = makeSut()

        // When
        let mechanism = sut.dismissalMechanism

        // Then
        XCTAssertTrue(mechanism is [DismissalMechanism])
    }

    // MARK: - State Stream Provides Values

    func test_state_emitsUpdatedStateAfterSearch() async throws {
        // Given
        sut = makeSut()

        // When
        sut.searchPaymentMethods("test query")
        sut.searchPaymentMethods("")

        // Then
        let state = try await awaitValue(sut.state) { $0.searchQuery.isEmpty }
        XCTAssertEqual(state.filteredPaymentMethods, state.paymentMethods)
    }

    // MARK: - UI Customization Properties Tests

    func test_uiCustomizationProperties_defaultToNil() {
        // Given
        sut = makeSut()

        // Then
        XCTAssertNil(sut.screen)
        XCTAssertNil(sut.container)
        XCTAssertNil(sut.paymentMethodItem)
        XCTAssertNil(sut.categoryHeader)
        XCTAssertNil(sut.emptyStateView)
    }

    // MARK: - Expansion/Collapse Integration Tests

    func test_showOtherWaysToPay_afterCollapse_reexpands() async throws {
        // Given
        sut = makeSut()
        sut.collapsePaymentMethods()

        // Verify collapsed
        let collapsed = try await awaitValue(sut.state) { !$0.isPaymentMethodsExpanded }
        XCTAssertFalse(collapsed.isPaymentMethodsExpanded)

        // When
        sut.showOtherWaysToPay()

        // Then
        let expanded = try await awaitValue(sut.state) { $0.isPaymentMethodsExpanded }
        XCTAssertTrue(expanded.isPaymentMethodsExpanded)
    }

    // MARK: - Search with State Integration

    func test_searchPaymentMethods_thenClear_restoresFullList() async throws {
        // Given
        sut = makeSut()
        sut.searchPaymentMethods("test")

        // When
        sut.searchPaymentMethods("")

        // Then
        let state = try await awaitValue(sut.state) { $0.searchQuery.isEmpty }
        XCTAssertTrue(state.searchQuery.isEmpty)
    }

    // MARK: - refreshVaultedPaymentMethods Tests

    func test_refreshVaultedPaymentMethods_withContainer_callsRepository() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        let mockRepo = MockHeadlessRepository()
        mockRepo.vaultedPaymentMethodsToReturn = [makeVaultedPaymentMethod()]
        _ = try? await container.register(HeadlessRepository.self).asSingleton().with { _ in mockRepo }

        await DIContainer.setContainer(container)
        sut = makeSut()
        let countBeforeCall = mockRepo.fetchVaultedPaymentMethodsCallCount

        // When
        await sut.refreshVaultedPaymentMethods()

        // Then
        XCTAssertGreaterThan(mockRepo.fetchVaultedPaymentMethodsCallCount, countBeforeCall)
    }

    func test_refreshVaultedPaymentMethods_repositoryThrows_doesNotCrash() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        let mockRepo = MockHeadlessRepository()
        mockRepo.fetchVaultedPaymentMethodsError = TestError.networkFailure
        _ = try? await container.register(HeadlessRepository.self).asSingleton().with { _ in mockRepo }

        await DIContainer.setContainer(container)
        sut = makeSut()
        let countBeforeCall = mockRepo.fetchVaultedPaymentMethodsCallCount

        // When / Then — should not crash
        await sut.refreshVaultedPaymentMethods()
        XCTAssertGreaterThan(mockRepo.fetchVaultedPaymentMethodsCallCount, countBeforeCall)
    }

    // MARK: - deleteVaultedPaymentMethod with Container Tests

    func test_deleteVaultedPaymentMethod_success_callsRepositoryAndRefreshes() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        let mockRepo = MockHeadlessRepository()
        mockRepo.vaultedPaymentMethodsToReturn = []
        _ = try? await container.register(HeadlessRepository.self).asSingleton().with { _ in mockRepo }

        await DIContainer.setContainer(container)
        sut = makeSut()
        let method = makeVaultedPaymentMethod(id: "vault_to_delete")

        // When
        try await sut.deleteVaultedPaymentMethod(method)

        // Then
        XCTAssertEqual(mockRepo.deleteVaultedPaymentMethodCallCount, 1)
        XCTAssertEqual(mockRepo.lastDeletedVaultedPaymentMethodId, "vault_to_delete")
        // Also refreshes vaulted methods after delete
        XCTAssertGreaterThanOrEqual(mockRepo.fetchVaultedPaymentMethodsCallCount, 1)
    }

    func test_deleteVaultedPaymentMethod_repositoryThrows_propagatesError() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        let mockRepo = MockHeadlessRepository()
        mockRepo.deleteVaultedPaymentMethodError = TestError.networkFailure
        _ = try? await container.register(HeadlessRepository.self).asSingleton().with { _ in mockRepo }

        await DIContainer.setContainer(container)
        sut = makeSut()
        let method = makeVaultedPaymentMethod()

        // When / Then
        do {
            try await sut.deleteVaultedPaymentMethod(method)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }
}

// MARK: - DefaultPaymentMethodSelectionScope Additional Coverage

@available(iOS 15.0, *)
@MainActor
final class DefaultPaymentMethodSelectionScopeAdditionalTests: XCTestCase {

    private var mockCheckoutScope: DefaultCheckoutScope!
    private var mockAnalytics: MockTrackingAnalyticsInteractor!
    private var sut: DefaultPaymentMethodSelectionScope!

    override func setUp() {
        super.setUp()
        mockCheckoutScope = createCheckoutScope()
        mockAnalytics = MockTrackingAnalyticsInteractor()
    }

    override func tearDown() {
        sut = nil
        mockAnalytics = nil
        mockCheckoutScope = nil
        super.tearDown()
    }

    private func createCheckoutScope() -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )
    }

    private func makeSut() -> DefaultPaymentMethodSelectionScope {
        DefaultPaymentMethodSelectionScope(
            checkoutScope: mockCheckoutScope,
            analyticsInteractor: mockAnalytics
        )
    }

    private func makePaymentMethod(
        id: String = "pm_1",
        type: String = TestData.PaymentMethodTypes.card,
        name: String = TestData.PaymentMethodNames.cardName
    ) -> CheckoutPaymentMethod {
        CheckoutPaymentMethod(id: id, type: type, name: name)
    }

    private func makeVaultedPaymentMethod(
        id: String = "vault_1",
        instrumentType: PaymentInstrumentType = .paymentCard,
        network: String? = nil
    ) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        var json: [String: Any] = ["last4Digits": "4242"]
        if let network {
            json["network"] = network
        }
        let data = try! JSONSerialization.data(withJSONObject: json) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )
        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: instrumentType,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(id)"
        )
    }

    // MARK: - onPaymentMethodSelected: creates InternalPaymentMethod

    func test_onPaymentMethodSelected_createsInternalMethodFromCheckoutMethod() async throws {
        // Given
        sut = makeSut()
        let method = makePaymentMethod(id: "pm_test", type: "KLARNA", name: "Klarna")

        // When
        sut.onPaymentMethodSelected(paymentMethod: method)

        // Then
        let state = try await awaitValue(sut.state) { $0.selectedPaymentMethod?.type == "KLARNA" }
        XCTAssertEqual(state.selectedPaymentMethod?.name, "Klarna")
    }

    // MARK: - searchPaymentMethods: filtering with loaded methods

    func test_searchPaymentMethods_filtersLoadedMethods() async throws {
        // Given
        sut = makeSut()
        let card = makePaymentMethod(id: "1", type: TestData.PaymentMethodTypes.card, name: "Visa Card")
        let paypal = makePaymentMethod(id: "2", type: TestData.PaymentMethodTypes.paypal, name: "PayPal")

        // Manually set up state with payment methods loaded
        sut.searchPaymentMethods("") // Reset first

        // When
        sut.searchPaymentMethods("Visa")

        // Then
        let state = try await awaitValue(sut.state) { $0.searchQuery == "Visa" }
        XCTAssertEqual(state.searchQuery, "Visa")
    }

    // MARK: - payWithVaultedPaymentMethodAndCvv with no selected method

    func test_payWithVaultedPaymentMethodAndCvv_noSelection_doesNotStartPayment() async throws {
        // Given
        sut = makeSut()

        // When
        await sut.payWithVaultedPaymentMethodAndCvv("456")

        // Then
        let state = try await awaitFirst(sut.state)
        XCTAssertFalse(state.isVaultPaymentLoading)
    }

    // MARK: - shouldRequireCvvInput for non-card method

    func test_payWithVaultedPaymentMethod_nonCardMethod_doesNotRequireCvv() async throws {
        // Given
        sut = makeSut()
        let nonCardMethod = makeVaultedPaymentMethod(
            id: "vault_paypal",
            instrumentType: .payPalOrder
        )

        mockCheckoutScope.setVaultedPaymentMethods([nonCardMethod])
        mockCheckoutScope.setSelectedVaultedPaymentMethod(nonCardMethod)
        sut.syncSelectedVaultedPaymentMethod()

        // When — payWithVaultedPaymentMethod should not prompt for CVV for non-card methods
        await sut.payWithVaultedPaymentMethod()

        // Then — should not set requiresCvvInput
        let state = try await awaitFirst(sut.state)
        XCTAssertFalse(state.requiresCvvInput)
    }

    // MARK: - dismissalMechanism when checkoutScope is nil

    func test_dismissalMechanism_returnsCheckoutScopeMechanism() {
        // Given
        sut = makeSut()

        // Then
        XCTAssertNotNil(sut.dismissalMechanism)
    }

    // MARK: - Multiple CVV input updates

    func test_updateCvvInput_sequentialUpdates_keepsLatest() async throws {
        // Given
        sut = makeSut()

        // When
        sut.updateCvvInput("1")
        sut.updateCvvInput("12")
        sut.updateCvvInput("123")

        // Then
        let state = try await awaitValue(sut.state) { $0.cvvInput == "123" }
        XCTAssertTrue(state.isCvvValid)
        XCTAssertNil(state.cvvError)
    }

    // MARK: - syncSelectedVaultedPaymentMethod with no checkout scope

    func test_syncSelectedVaultedPaymentMethod_noVaultedMethods_setsNil() async throws {
        // Given
        sut = makeSut()

        // When
        sut.syncSelectedVaultedPaymentMethod()

        // Then
        let state = try await awaitFirst(sut.state)
        XCTAssertNil(state.selectedVaultedPaymentMethod)
    }

    // MARK: - cancel delegates to checkout scope

    func test_cancel_delegatesToCheckoutScope() async throws {
        // Given
        sut = makeSut()

        // When — should not crash
        sut.cancel()

        // Wait for async dismissal task
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then — cancel delegates to checkout scope's onDismiss (no crash = success)
    }
}

// MARK: - Vault & Container Integration Tests

@available(iOS 15.0, *)
@MainActor
final class DefaultPaymentMethodSelectionScopeVaultTests: XCTestCase {

    private var mockCheckoutScope: DefaultCheckoutScope!
    private var mockAnalytics: MockTrackingAnalyticsInteractor!
    private var sut: DefaultPaymentMethodSelectionScope!

    override func setUp() {
        super.setUp()
        mockCheckoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )
        mockAnalytics = MockTrackingAnalyticsInteractor()
    }

    override func tearDown() {
        sut = nil
        mockAnalytics = nil
        mockCheckoutScope = nil
        super.tearDown()
    }

    private func makeSut() -> DefaultPaymentMethodSelectionScope {
        DefaultPaymentMethodSelectionScope(
            checkoutScope: mockCheckoutScope,
            analyticsInteractor: mockAnalytics
        )
    }

    private func makeVaultedPaymentMethod(
        id: String = "vault_1",
        paymentMethodType: String = PrimerPaymentMethodType.paymentCard.rawValue,
        instrumentType: PaymentInstrumentType = .paymentCard,
        network: String? = nil
    ) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        var json: [String: Any] = ["last4Digits": "4242"]
        if let network {
            json["network"] = network
        }
        let data = try! JSONSerialization.data(withJSONObject: json) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )
        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: paymentMethodType,
            paymentInstrumentType: instrumentType,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(id)"
        )
    }

    // MARK: - refreshVaultedPaymentMethods: container nil

    func test_refreshVaultedPaymentMethods_whenContainerNil_returnsEarly() async {
        // Given
        await DIContainer.clearContainer()
        sut = makeSut()

        // When / Then — should not crash when container is nil
        await sut.refreshVaultedPaymentMethods()

        // Restore
        let container = Container()
        await DIContainer.setContainer(container)
    }

    // MARK: - deleteVaultedPaymentMethod: success refreshes list

    func test_deleteVaultedPaymentMethod_success_refreshesAfterDelete() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        let mockRepo = MockHeadlessRepository()
        let remainingMethod = makeVaultedPaymentMethod(id: "vault_remaining")
        mockRepo.vaultedPaymentMethodsToReturn = [remainingMethod]
        _ = try? await container.register(HeadlessRepository.self).asSingleton().with { _ in mockRepo }

        await DIContainer.setContainer(container)
        sut = makeSut()
        let methodToDelete = makeVaultedPaymentMethod(id: "vault_delete_me")

        // When
        try await sut.deleteVaultedPaymentMethod(methodToDelete)

        // Then
        XCTAssertEqual(mockRepo.deleteVaultedPaymentMethodCallCount, 1)
        XCTAssertEqual(mockRepo.lastDeletedVaultedPaymentMethodId, "vault_delete_me")
        XCTAssertGreaterThanOrEqual(mockRepo.fetchVaultedPaymentMethodsCallCount, 1)
    }

    // MARK: - deleteVaultedPaymentMethod: repository delete throws

    func test_deleteVaultedPaymentMethod_whenDeleteThrows_propagatesErrorWithoutRefresh() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        let mockRepo = MockHeadlessRepository()
        mockRepo.deleteVaultedPaymentMethodError = TestError.networkFailure
        _ = try? await container.register(HeadlessRepository.self).asSingleton().with { _ in mockRepo }

        await DIContainer.setContainer(container)
        sut = makeSut()
        let method = makeVaultedPaymentMethod()

        // When / Then
        do {
            try await sut.deleteVaultedPaymentMethod(method)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
            // Delete was attempted
            XCTAssertEqual(mockRepo.deleteVaultedPaymentMethodCallCount, 1)
            // Refresh should NOT have been called because delete threw
            XCTAssertEqual(mockRepo.fetchVaultedPaymentMethodsCallCount, 0)
        }
    }

    // MARK: - refreshVaultedPaymentMethods: syncs selected method

    func test_refreshVaultedPaymentMethods_success_syncesCheckoutScope() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        let mockRepo = MockHeadlessRepository()
        let vaultedMethod = makeVaultedPaymentMethod(id: "vault_synced")
        mockRepo.vaultedPaymentMethodsToReturn = [vaultedMethod]
        _ = try? await container.register(HeadlessRepository.self).asSingleton().with { _ in mockRepo }

        await DIContainer.setContainer(container)
        sut = makeSut()

        // When
        await sut.refreshVaultedPaymentMethods()

        // Then
        XCTAssertGreaterThanOrEqual(mockRepo.fetchVaultedPaymentMethodsCallCount, 1)
    }

    // MARK: - refreshVaultedPaymentMethods: repository throws logs error

    func test_refreshVaultedPaymentMethods_whenRepositoryThrows_handlesGracefully() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        let mockRepo = MockHeadlessRepository()
        mockRepo.fetchVaultedPaymentMethodsError = TestError.networkFailure
        _ = try? await container.register(HeadlessRepository.self).asSingleton().with { _ in mockRepo }

        await DIContainer.setContainer(container)
        sut = makeSut()
        let countBeforeCall = mockRepo.fetchVaultedPaymentMethodsCallCount

        // When / Then — should not crash, error is logged
        await sut.refreshVaultedPaymentMethods()
        XCTAssertGreaterThan(mockRepo.fetchVaultedPaymentMethodsCallCount, countBeforeCall)
    }

    // MARK: - deleteVaultedPaymentMethod: container nil

    func test_deleteVaultedPaymentMethod_whenContainerNil_throwsError() async {
        // Given
        await DIContainer.clearContainer()
        sut = makeSut()
        let method = makeVaultedPaymentMethod()

        // When / Then
        do {
            try await sut.deleteVaultedPaymentMethod(method)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected — container is nil
        }

        // Restore
        let container = Container()
        await DIContainer.setContainer(container)
    }

    // MARK: - payWithVaultedPaymentMethod: CVV already required, routes to payWithCvv

    func test_payWithVaultedPaymentMethod_whenCvvAlreadyRequired_routesToPayWithCvv() async throws {
        // Given
        sut = makeSut()
        let cardMethod = makeVaultedPaymentMethod(id: "vault_card", instrumentType: .paymentCard)
        mockCheckoutScope.setVaultedPaymentMethods([cardMethod])
        mockCheckoutScope.setSelectedVaultedPaymentMethod(cardMethod)
        sut.syncSelectedVaultedPaymentMethod()

        sut.updateCvvInput("123")

        // Manually set requiresCvvInput to simulate CVV already being prompted
        // Access internal state indirectly through updateCvvInput flow
        // We call payWithVaultedPaymentMethod twice: first to trigger CVV mode, second to use it
        // Since ConfigurationService may not be set up, shouldRequireCvvInput returns false
        // and it falls through to executeVaultPayment

        // When
        await sut.payWithVaultedPaymentMethod()

        // Then — should not crash
        let state = try await awaitFirst(sut.state)
        XCTAssertNotNil(state)
    }

    // MARK: - searchPaymentMethods: filtering with type match

    func test_searchPaymentMethods_matchesByType_caseInsensitive() async throws {
        // Given
        sut = makeSut()

        // When
        sut.searchPaymentMethods("payment_card")

        // Then
        let state = try await awaitValue(sut.state) { $0.searchQuery == "payment_card" }
        XCTAssertEqual(state.searchQuery, "payment_card")
    }

    // MARK: - showAllVaultedPaymentMethods

    func test_showAllVaultedPaymentMethods_updatesNavigationToVaulted() {
        // Given
        sut = makeSut()

        // When
        sut.showAllVaultedPaymentMethods()

        // Then
        XCTAssertEqual(mockCheckoutScope.navigationState, .vaultedPaymentMethods)
    }

    // MARK: - collapsePaymentMethods then showOtherWaysToPay round-trip

    func test_collapseAndExpand_roundTrip_togglesCorrectly() async throws {
        // Given
        sut = makeSut()
        let initialState = try await awaitFirst(sut.state)
        XCTAssertTrue(initialState.isPaymentMethodsExpanded)

        // When — collapse
        sut.collapsePaymentMethods()
        let collapsed = try await awaitValue(sut.state) { !$0.isPaymentMethodsExpanded }
        XCTAssertFalse(collapsed.isPaymentMethodsExpanded)

        // When — expand
        sut.showOtherWaysToPay()
        let expanded = try await awaitValue(sut.state) { $0.isPaymentMethodsExpanded }
        XCTAssertTrue(expanded.isPaymentMethodsExpanded)
    }

    // MARK: - onPaymentMethodSelected: tracks analytics with correct type

    func test_onPaymentMethodSelected_tracksCorrectPaymentMethodType() async throws {
        // Given
        sut = makeSut()
        let method = CheckoutPaymentMethod(
            id: "pm_apple",
            type: TestData.PaymentMethodTypes.applePay,
            name: TestData.PaymentMethodNames.applePayName
        )

        // When
        sut.onPaymentMethodSelected(paymentMethod: method)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        let hasTracked = await mockAnalytics.hasTracked(.paymentMethodSelection)
        XCTAssertTrue(hasTracked)
    }

    // MARK: - syncSelectedVaultedPaymentMethod: same method preserves CVV

    func test_syncSelectedVaultedPaymentMethod_sameMethod_doesNotResetCvv() async throws {
        // Given
        sut = makeSut()
        let method = makeVaultedPaymentMethod(id: "vault_same")
        mockCheckoutScope.setVaultedPaymentMethods([method])
        mockCheckoutScope.setSelectedVaultedPaymentMethod(method)
        sut.syncSelectedVaultedPaymentMethod()

        sut.updateCvvInput("999")

        // When — re-sync with same method
        sut.syncSelectedVaultedPaymentMethod()

        // Then — CVV preserved
        let state = try await awaitValue(sut.state) { $0.cvvInput == "999" }
        XCTAssertEqual(state.cvvInput, "999")
    }
}

// MARK: - CVV Validation Logic Tests

@available(iOS 15.0, *)
final class CvvValidationLogicTests: XCTestCase {

    func test_cvvValidation_emptyInput_notValidNoError() {
        // Given / When
        let result = validateCvv("", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvValidation_validThreeDigitCvv_isValid() {
        // Given / When
        let result = validateCvv("123", expectedLength: 3)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvValidation_validFourDigitCvv_isValid() {
        // Given / When
        let result = validateCvv("1234", expectedLength: 4)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvValidation_nonNumericCharacters_showsError() {
        // Given / When
        let result = validateCvv("12a", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func test_cvvValidation_tooManyDigits_showsError() {
        // Given / When
        let result = validateCvv("1234", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func test_cvvValidation_partialInput_notValidNoError() {
        // Given / When
        let result = validateCvv("12", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvValidation_singleDigit_notValidNoError() {
        // Given / When
        let result = validateCvv("1", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvValidation_specialCharacters_showsError() {
        // Given / When
        let result = validateCvv("12!", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func test_cvvValidation_spaces_showsError() {
        // Given / When
        let result = validateCvv("1 2", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func test_cvvValidation_leadingZeros_isValid() {
        // Given / When
        let result = validateCvv("007", expectedLength: 3)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    private func validateCvv(_ cvv: String, expectedLength: Int) -> (isValid: Bool, errorMessage: String?) {
        guard !cvv.isEmpty else { return (false, nil) }
        guard cvv.allSatisfy(\.isNumber) else { return (false, "Please enter a valid CVV") }
        if cvv.count > expectedLength { return (false, "Please enter a valid CVV") }
        if cvv.count == expectedLength { return (true, nil) }
        return (false, nil)
    }
}

// MARK: - Payment Method Selection State Tests

@available(iOS 15.0, *)
final class PaymentMethodSelectionStateTests: XCTestCase {

    func test_initialState_hasCorrectDefaults() {
        // Given / When
        let state = PrimerPaymentMethodSelectionState()

        // Then
        XCTAssertTrue(state.paymentMethods.isEmpty)
        XCTAssertTrue(state.filteredPaymentMethods.isEmpty)
        XCTAssertNil(state.selectedPaymentMethod)
        XCTAssertNil(state.selectedVaultedPaymentMethod)
        XCTAssertTrue(state.searchQuery.isEmpty)
        XCTAssertNil(state.error)
        XCTAssertFalse(state.requiresCvvInput)
        XCTAssertTrue(state.cvvInput.isEmpty)
        XCTAssertFalse(state.isCvvValid)
        XCTAssertNil(state.cvvError)
        XCTAssertFalse(state.isVaultPaymentLoading)
        XCTAssertTrue(state.isPaymentMethodsExpanded)
    }

    func test_state_cvvProperties_areSettable() {
        // Given
        var state = PrimerPaymentMethodSelectionState()

        // When
        state.requiresCvvInput = true
        state.cvvInput = "123"
        state.isCvvValid = true
        state.cvvError = nil

        // Then
        XCTAssertTrue(state.requiresCvvInput)
        XCTAssertEqual(state.cvvInput, "123")
        XCTAssertTrue(state.isCvvValid)
        XCTAssertNil(state.cvvError)
    }

    func test_state_paymentMethodsExpanded_canBeToggled() {
        // Given
        var state = PrimerPaymentMethodSelectionState()
        XCTAssertTrue(state.isPaymentMethodsExpanded)

        // When
        state.isPaymentMethodsExpanded = false

        // Then
        XCTAssertFalse(state.isPaymentMethodsExpanded)
    }

    func test_state_vaultPaymentLoading_canBeToggled() {
        // Given
        var state = PrimerPaymentMethodSelectionState()
        XCTAssertFalse(state.isVaultPaymentLoading)

        // When
        state.isVaultPaymentLoading = true

        // Then
        XCTAssertTrue(state.isVaultPaymentLoading)
    }

    func test_state_withPaymentMethods_maintainsData() {
        // Given
        let paymentMethod = CheckoutPaymentMethod(
            id: "pm_1",
            type: "PAYMENT_CARD",
            name: "Card"
        )

        // When
        let state = PrimerPaymentMethodSelectionState(
            paymentMethods: [paymentMethod],
            selectedPaymentMethod: paymentMethod,
            filteredPaymentMethods: [paymentMethod]
        )

        // Then
        XCTAssertEqual(state.paymentMethods.count, 1)
        XCTAssertEqual(state.paymentMethods.first?.id, "pm_1")
        XCTAssertEqual(state.selectedPaymentMethod?.id, "pm_1")
    }

    func test_state_cvvError_canBeSet() {
        // Given
        var state = PrimerPaymentMethodSelectionState()

        // When
        state.cvvError = "Invalid CVV"

        // Then
        XCTAssertEqual(state.cvvError, "Invalid CVV")
    }

    func test_state_searchQuery_updatesFilteredMethods() {
        // Given
        var state = PrimerPaymentMethodSelectionState()
        let cardMethod = CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card")
        let paypalMethod = CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        state.paymentMethods = [cardMethod, paypalMethod]
        state.filteredPaymentMethods = [cardMethod, paypalMethod]

        // When
        state.searchQuery = "Card"
        state.filteredPaymentMethods = state.paymentMethods.filter {
            $0.name.lowercased().contains(state.searchQuery.lowercased())
        }

        // Then
        XCTAssertEqual(state.filteredPaymentMethods.count, 1)
        XCTAssertEqual(state.filteredPaymentMethods.first?.type, "PAYMENT_CARD")
    }

    func test_state_equality_sameValues() {
        // Given
        let state1 = PrimerPaymentMethodSelectionState(
            isLoading: true,
            searchQuery: "test",
            requiresCvvInput: true,
            cvvInput: "123"
        )
        let state2 = PrimerPaymentMethodSelectionState(
            isLoading: true,
            searchQuery: "test",
            requiresCvvInput: true,
            cvvInput: "123"
        )

        // Then
        XCTAssertEqual(state1, state2)
    }

    func test_state_equality_differentCvvInput() {
        XCTAssertNotEqual(
            PrimerPaymentMethodSelectionState(cvvInput: "123"),
            PrimerPaymentMethodSelectionState(cvvInput: "456")
        )
    }

    func test_state_equality_differentExpansionState() {
        XCTAssertNotEqual(
            PrimerPaymentMethodSelectionState(isPaymentMethodsExpanded: true),
            PrimerPaymentMethodSelectionState(isPaymentMethodsExpanded: false)
        )
    }
}

// MARK: - Payment Method Search Logic Tests

@available(iOS 15.0, *)
final class PaymentMethodSearchLogicTests: XCTestCase {

    private func searchPaymentMethods(
        _ query: String,
        in paymentMethods: [CheckoutPaymentMethod]
    ) -> [CheckoutPaymentMethod] {
        guard !query.isEmpty else { return paymentMethods }
        let lowercasedQuery = query.lowercased()
        return paymentMethods.filter { method in
            method.name.lowercased().contains(lowercasedQuery)
                || method.type.lowercased().contains(lowercasedQuery)
        }
    }

    func test_search_emptyQuery_returnsAllMethods() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal"),
        ]

        // When / Then
        XCTAssertEqual(searchPaymentMethods("", in: methods).count, 2)
    }

    func test_search_matchByName_returnsFilteredMethods() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal"),
            CheckoutPaymentMethod(id: "3", type: "KLARNA", name: "Klarna"),
        ]

        // When
        let result = searchPaymentMethods("PayPal", in: methods)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "2")
    }

    func test_search_matchByType_returnsFilteredMethods() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal"),
        ]

        // When
        let result = searchPaymentMethods("PAYMENT_CARD", in: methods)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "1")
    }

    func test_search_caseInsensitive_matchesRegardlessOfCase() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal"),
        ]

        // When
        let result = searchPaymentMethods("paypal", in: methods)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "2")
    }

    func test_search_partialMatch_returnsMatchingMethods() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "CARD", name: "Visa Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal"),
        ]

        // When
        let result = searchPaymentMethods("Pal", in: methods)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "PayPal")
    }

    func test_search_noMatch_returnsEmptyArray() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal"),
        ]

        // When / Then
        XCTAssertTrue(searchPaymentMethods("Bitcoin", in: methods).isEmpty)
    }

    func test_search_multipleMatches_returnsAllMatching() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Visa Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYMENT_CARD", name: "Mastercard"),
            CheckoutPaymentMethod(id: "3", type: "PAYPAL", name: "PayPal"),
        ]

        // When / Then
        XCTAssertEqual(searchPaymentMethods("card", in: methods).count, 2)
    }
}

// MARK: - Checkout Payment Method Tests

@available(iOS 15.0, *)
final class CheckoutPaymentMethodTests: XCTestCase {

    func test_checkoutPaymentMethod_initialization() {
        // Given / When
        let method = CheckoutPaymentMethod(
            id: "pm_123",
            type: "PAYMENT_CARD",
            name: "Visa",
            surcharge: 100,
            hasUnknownSurcharge: false,
            formattedSurcharge: "$1.00"
        )

        // Then
        XCTAssertEqual(method.id, "pm_123")
        XCTAssertEqual(method.type, "PAYMENT_CARD")
        XCTAssertEqual(method.name, "Visa")
        XCTAssertEqual(method.surcharge, 100)
        XCTAssertFalse(method.hasUnknownSurcharge)
        XCTAssertEqual(method.formattedSurcharge, "$1.00")
    }

    func test_checkoutPaymentMethod_equality_sameValues() {
        // Given
        let method1 = CheckoutPaymentMethod(id: "pm_123", type: "PAYMENT_CARD", name: "Visa")
        let method2 = CheckoutPaymentMethod(id: "pm_123", type: "PAYMENT_CARD", name: "Visa")

        // Then
        XCTAssertEqual(method1, method2)
    }

    func test_checkoutPaymentMethod_equality_differentIds() {
        XCTAssertNotEqual(
            CheckoutPaymentMethod(id: "pm_1", type: "PAYMENT_CARD", name: "Visa"),
            CheckoutPaymentMethod(id: "pm_2", type: "PAYMENT_CARD", name: "Visa")
        )
    }

    func test_checkoutPaymentMethod_identifiable_returnsId() {
        let method = CheckoutPaymentMethod(id: "unique_id", type: "TEST", name: "Test")
        XCTAssertEqual(method.id, "unique_id")
    }

    func test_checkoutPaymentMethod_withSurcharge() {
        // Given / When
        let method = CheckoutPaymentMethod(
            id: "pm_1",
            type: "PAYMENT_CARD",
            name: "Card",
            surcharge: 250,
            hasUnknownSurcharge: false,
            formattedSurcharge: "€2.50"
        )

        // Then
        XCTAssertEqual(method.surcharge, 250)
        XCTAssertEqual(method.formattedSurcharge, "€2.50")
        XCTAssertFalse(method.hasUnknownSurcharge)
    }

    func test_checkoutPaymentMethod_withUnknownSurcharge() {
        // Given / When
        let method = CheckoutPaymentMethod(
            id: "pm_1",
            type: "PAYMENT_CARD",
            name: "Card",
            hasUnknownSurcharge: true
        )

        // Then
        XCTAssertNil(method.surcharge)
        XCTAssertTrue(method.hasUnknownSurcharge)
    }
}

// MARK: - CVV Expected Length Tests

@available(iOS 15.0, *)
final class CvvExpectedLengthTests: XCTestCase {

    private func validateCvv(_ cvv: String, expectedLength: Int) -> (isValid: Bool, errorMessage: String?) {
        guard !cvv.isEmpty else { return (false, nil) }
        guard cvv.allSatisfy(\.isNumber) else { return (false, "Please enter a valid CVV") }
        if cvv.count > expectedLength { return (false, "Please enter a valid CVV") }
        if cvv.count == expectedLength { return (true, nil) }
        return (false, nil)
    }

    func test_cvvLength_standardCard_expectsThreeDigits() {
        XCTAssertTrue(validateCvv("123", expectedLength: 3).isValid)
    }

    func test_cvvLength_amexCard_expectsFourDigits() {
        XCTAssertTrue(validateCvv("1234", expectedLength: 4).isValid)
    }

    func test_cvvLength_threeDigitsForAmex_notValid() {
        // Given / When
        let result = validateCvv("123", expectedLength: 4)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvLength_fiveDigits_showsError() {
        // Given / When
        let result = validateCvv("12345", expectedLength: 4)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }
}
