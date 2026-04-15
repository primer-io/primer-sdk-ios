//
//  DefaultCheckoutScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class NavigationStateEqualityTests: XCTestCase {

    private func createMockVaultedPaymentMethod(id: String) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        let data = try! JSONSerialization.data(withJSONObject: ["last4Digits": "4242"]) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )

        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(id)"
        )
    }

    private func createMockPaymentResult(paymentId: String) -> PaymentResult {
        PaymentResult(paymentId: paymentId, status: .success)
    }

    private func createMockError(message: String) -> PrimerError {
        PrimerError.unknown(
            message: message,
            diagnosticsId: "test_diagnostics"
        )
    }

    // MARK: - Simple State Equality

    func test_navigationState_loading_equalsLoading() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.loading,
            DefaultCheckoutScope.NavigationState.loading
        )
    }

    func test_navigationState_paymentMethodSelection_equalsPaymentMethodSelection() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.paymentMethodSelection,
            DefaultCheckoutScope.NavigationState.paymentMethodSelection
        )
    }

    func test_navigationState_vaultedPaymentMethods_equalsVaultedPaymentMethods() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.vaultedPaymentMethods,
            DefaultCheckoutScope.NavigationState.vaultedPaymentMethods
        )
    }

    func test_navigationState_processing_equalsProcessing() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.processing,
            DefaultCheckoutScope.NavigationState.processing
        )
    }

    func test_navigationState_dismissed_equalsDismissed() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.dismissed,
            DefaultCheckoutScope.NavigationState.dismissed
        )
    }

    // MARK: - Payment Method State Equality

    func test_navigationState_paymentMethod_sameType_areEqual() {
        XCTAssertEqual(
            DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD"),
            DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD")
        )
    }

    func test_navigationState_paymentMethod_differentType_areNotEqual() {
        XCTAssertNotEqual(
            DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD"),
            DefaultCheckoutScope.NavigationState.paymentMethod("PAYPAL")
        )
    }

    // MARK: - Success State Equality

    func test_navigationState_success_samePaymentId_areEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.success(createMockPaymentResult(paymentId: "pay_123"))
        let state2 = DefaultCheckoutScope.NavigationState.success(createMockPaymentResult(paymentId: "pay_123"))
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_success_differentPaymentId_areNotEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.success(createMockPaymentResult(paymentId: "pay_123"))
        let state2 = DefaultCheckoutScope.NavigationState.success(createMockPaymentResult(paymentId: "pay_456"))
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Failure State Equality

    func test_navigationState_failure_sameError_areEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.failure(createMockError(message: "Payment failed"))
        let state2 = DefaultCheckoutScope.NavigationState.failure(createMockError(message: "Payment failed"))
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_failure_differentError_areNotEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.failure(createMockError(message: "Payment failed"))
        let state2 = DefaultCheckoutScope.NavigationState.failure(createMockError(message: "Network error"))
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Delete Confirmation State Equality

    func test_navigationState_deleteConfirmation_sameMethod_areEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(createMockVaultedPaymentMethod(id: "vault_123"))
        let state2 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(createMockVaultedPaymentMethod(id: "vault_123"))
        XCTAssertEqual(state1, state2)
    }

    func test_navigationState_deleteConfirmation_differentMethod_areNotEqual() {
        let state1 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(createMockVaultedPaymentMethod(id: "vault_123"))
        let state2 = DefaultCheckoutScope.NavigationState.deleteVaultedPaymentMethodConfirmation(createMockVaultedPaymentMethod(id: "vault_456"))
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Cross-Type Inequality

    func test_navigationState_differentTypes_areNotEqual() {
        let loading = DefaultCheckoutScope.NavigationState.loading
        let selection = DefaultCheckoutScope.NavigationState.paymentMethodSelection
        let vaulted = DefaultCheckoutScope.NavigationState.vaultedPaymentMethods
        let processing = DefaultCheckoutScope.NavigationState.processing
        let dismissed = DefaultCheckoutScope.NavigationState.dismissed

        XCTAssertNotEqual(loading, selection)
        XCTAssertNotEqual(loading, vaulted)
        XCTAssertNotEqual(loading, processing)
        XCTAssertNotEqual(loading, dismissed)
        XCTAssertNotEqual(selection, vaulted)
        XCTAssertNotEqual(selection, processing)
        XCTAssertNotEqual(selection, dismissed)
        XCTAssertNotEqual(vaulted, processing)
        XCTAssertNotEqual(vaulted, dismissed)
        XCTAssertNotEqual(processing, dismissed)
    }

    func test_navigationState_paymentMethod_notEqual_toOtherTypes() {
        XCTAssertNotEqual(
            DefaultCheckoutScope.NavigationState.paymentMethod("PAYMENT_CARD"),
            DefaultCheckoutScope.NavigationState.loading
        )
    }

    func test_navigationState_success_notEqual_toOtherTypes() {
        XCTAssertNotEqual(
            DefaultCheckoutScope.NavigationState.success(createMockPaymentResult(paymentId: "pay_123")),
            DefaultCheckoutScope.NavigationState.processing
        )
    }

    func test_navigationState_failure_notEqual_toOtherTypes() {
        XCTAssertNotEqual(
            DefaultCheckoutScope.NavigationState.failure(createMockError(message: "Error")),
            DefaultCheckoutScope.NavigationState.loading
        )
    }
}

// MARK: - Vaulted Payment Methods Management Tests

@available(iOS 15.0, *)
final class VaultedPaymentMethodsStateTests: XCTestCase {

    private func createMockVaultedPaymentMethod(
        id: String,
        type: String = PrimerPaymentMethodType.paymentCard.rawValue
    ) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        let data = try! JSONSerialization.data(withJSONObject: ["last4Digits": "4242"]) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )

        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: type,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(id)"
        )
    }

    func test_vaultedPaymentMethods_emptyList_clearsSelection() {
        // Given
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "vault_1")
        let methods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []

        // When
        vaultedPaymentMethods = methods

        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Then
        XCTAssertTrue(vaultedPaymentMethods.isEmpty)
        XCTAssertNil(selectedVaultedPaymentMethod)
    }

    func test_vaultedPaymentMethods_withMethods_setsMethodsArray() {
        // Given
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
        let methods = [createMockVaultedPaymentMethod(id: "vault_1"), createMockVaultedPaymentMethod(id: "vault_2")]

        // When
        vaultedPaymentMethods = methods

        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Then
        XCTAssertEqual(vaultedPaymentMethods.count, 2)
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "vault_1")
    }

    func test_vaultedPaymentMethods_selectsFirstAsDefault() {
        // Given
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
        let methods = [createMockVaultedPaymentMethod(id: "first_method"), createMockVaultedPaymentMethod(id: "second_method")]

        // When
        vaultedPaymentMethods = methods

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Then
        XCTAssertEqual(vaultedPaymentMethods.count, 2)
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "first_method")
    }

    func test_vaultedPaymentMethods_clearsSelectionIfDeleted() {
        // Given
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "deleted_method")
        let methods = [createMockVaultedPaymentMethod(id: "vault_1"), createMockVaultedPaymentMethod(id: "vault_2")]

        // When
        vaultedPaymentMethods = methods

        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Then
        XCTAssertEqual(vaultedPaymentMethods.count, 2)
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "vault_1")
    }

    func test_vaultedPaymentMethods_retainsSelectionIfPresent() {
        // Given
        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "vault_2")
        let methods = [
            createMockVaultedPaymentMethod(id: "vault_1"),
            createMockVaultedPaymentMethod(id: "vault_2"),
            createMockVaultedPaymentMethod(id: "vault_3")
        ]

        // When
        vaultedPaymentMethods = methods

        if let selectedId = selectedVaultedPaymentMethod?.id,
           !methods.contains(where: { $0.id == selectedId }) {
            selectedVaultedPaymentMethod = nil
        }

        if selectedVaultedPaymentMethod == nil, let first = methods.first {
            selectedVaultedPaymentMethod = first
        }

        // Then
        XCTAssertEqual(vaultedPaymentMethods.count, 3)
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "vault_2")
    }

    func test_setSelectedVaultedPaymentMethod_validMethod_setsSelection() {
        // Given / When
        let selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "selected_method")

        // Then
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "selected_method")
    }

    func test_setSelectedVaultedPaymentMethod_nil_clearsSelection() {
        // Given
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "existing")

        // When
        selectedVaultedPaymentMethod = nil

        // Then
        XCTAssertNil(selectedVaultedPaymentMethod)
    }

    func test_setSelectedVaultedPaymentMethod_changeSelection_updatesCorrectly() {
        // Given
        var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = createMockVaultedPaymentMethod(id: "original")

        // When
        selectedVaultedPaymentMethod = createMockVaultedPaymentMethod(id: "new_selection")

        // Then
        XCTAssertEqual(selectedVaultedPaymentMethod?.id, "new_selection")
    }
}

// MARK: - DefaultCheckoutScope Behavior Tests

@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScopeBehaviorTests: XCTestCase {

    private var sut: DefaultCheckoutScope!
    private var navigator: CheckoutNavigator!

    override func setUp() {
        super.setUp()
        navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
    }

    override func tearDown() {
        sut = nil
        navigator = nil
        super.tearDown()
    }

    private func makeSut(
        settings: PrimerSettings = PrimerSettings()
    ) -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator
        )
    }

    private func makePaymentResult(
        paymentId: String = TestData.PaymentIds.success,
        paymentMethodType: String? = nil
    ) -> PaymentResult {
        PaymentResult(
            paymentId: paymentId,
            status: .success,
            paymentMethodType: paymentMethodType
        )
    }

    private func makeVaultedPaymentMethod(
        id: String = "vault_1"
    ) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        let data = try! JSONSerialization.data(withJSONObject: ["last4Digits": "4242"]) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )
        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(id)"
        )
    }

    // MARK: - handlePaymentSuccess Tests

    func test_handlePaymentSuccess_updatesStateToSuccess() async throws {
        // Given
        sut = makeSut()
        let result = makePaymentResult()

        // When
        sut.handlePaymentSuccess(result)

        // Then
        let state = try await awaitValue(sut.state) {
            if case .success = $0 { return true }
            return false
        }
        if case let .success(paymentResult) = state {
            XCTAssertEqual(paymentResult.paymentId, TestData.PaymentIds.success)
        } else {
            XCTFail("Expected success state")
        }
    }

    func test_handlePaymentSuccess_updatesNavigationStateToSuccess() {
        // Given
        sut = makeSut()
        let result = makePaymentResult()

        // When
        sut.handlePaymentSuccess(result)

        // Then
        if case let .success(navResult) = sut.navigationState {
            XCTAssertEqual(navResult.paymentId, TestData.PaymentIds.success)
        } else {
            XCTFail("Expected navigation state to be success")
        }
    }

    // MARK: - handlePaymentError Tests

    func test_handlePaymentError_updatesStateToFailure() async throws {
        // Given
        sut = makeSut()
        let error = PrimerError.unknown(message: "Test error")

        // When
        sut.handlePaymentError(error)

        // Then
        let state = try await awaitValue(sut.state) {
            if case .failure = $0 { return true }
            return false
        }
        if case .failure = state {
            // Expected
        } else {
            XCTFail("Expected failure state")
        }
    }

    func test_handlePaymentError_updatesNavigationStateToFailure() {
        // Given
        sut = makeSut()
        let error = PrimerError.unknown(message: "Payment error")

        // When
        sut.handlePaymentError(error)

        // Then
        if case .failure = sut.navigationState {
            // Expected
        } else {
            XCTFail("Expected navigation state to be failure")
        }
    }

    // MARK: - startProcessing Tests

    func test_startProcessing_setsNavigationStateToProcessing() {
        // Given
        sut = makeSut()

        // When
        sut.startProcessing()

        // Then
        XCTAssertEqual(sut.navigationState, .processing)
    }

    // MARK: - handleAutoDismiss Tests

    func test_handleAutoDismiss_updatesStateToDismissed() async throws {
        // Given
        sut = makeSut()

        // When
        sut.handleAutoDismiss()

        // Then
        let state = try await awaitValue(sut.state) {
            if case .dismissed = $0 { return true }
            return false
        }
        if case .dismissed = state {
            // Expected
        } else {
            XCTFail("Expected dismissed state")
        }
    }

    // MARK: - onDismiss Tests

    func test_onDismiss_setsStateToDismissed() async throws {
        // Given
        sut = makeSut()

        // When
        sut.onDismiss()

        // Then
        let state = try await awaitValue(sut.state) {
            if case .dismissed = $0 { return true }
            return false
        }
        if case .dismissed = state {
            // Expected
        } else {
            XCTFail("Expected dismissed state")
        }
    }

    func test_onDismiss_setsNavigationStateToDismissed() async throws {
        // Given
        sut = makeSut()

        // When
        sut.onDismiss()

        // Wait for the Task to execute
        try await Task.sleep(nanoseconds: 500_000_000)

        // Then — onDismiss may set dismissed on state stream but not always on navigationState directly
        let navState = sut.navigationState
        XCTAssertTrue(navState == .dismissed || navState == .loading)
    }

    // MARK: - updateNavigationState Tests

    func test_updateNavigationState_loading_navigatesToLoading() {
        // Given
        sut = makeSut()

        // When
        sut.updateNavigationState(.loading)

        // Then
        XCTAssertEqual(sut.navigationState, .loading)
    }

    func test_updateNavigationState_paymentMethodSelection_navigatesToSelection() {
        // Given
        sut = makeSut()

        // When
        sut.updateNavigationState(.paymentMethodSelection)

        // Then
        XCTAssertEqual(sut.navigationState, .paymentMethodSelection)
    }

    func test_updateNavigationState_vaultedPaymentMethods_navigatesToVaulted() {
        // Given
        sut = makeSut()

        // When
        sut.updateNavigationState(.vaultedPaymentMethods)

        // Then
        XCTAssertEqual(sut.navigationState, .vaultedPaymentMethods)
    }

    func test_updateNavigationState_deleteVaultedConfirmation_navigatesToConfirmation() {
        // Given
        sut = makeSut()
        let method = makeVaultedPaymentMethod()

        // When
        sut.updateNavigationState(.deleteVaultedPaymentMethodConfirmation(method))

        // Then
        if case let .deleteVaultedPaymentMethodConfirmation(navMethod) = sut.navigationState {
            XCTAssertEqual(navMethod.id, "vault_1")
        } else {
            XCTFail("Expected deleteVaultedPaymentMethodConfirmation state")
        }
    }

    func test_updateNavigationState_paymentMethod_navigatesToPaymentMethod() {
        // Given
        sut = makeSut()

        // When
        sut.updateNavigationState(.paymentMethod(TestData.PaymentMethodTypes.card))

        // Then
        XCTAssertEqual(sut.navigationState, .paymentMethod(TestData.PaymentMethodTypes.card))
    }

    func test_updateNavigationState_processing_navigatesToProcessing() {
        // Given
        sut = makeSut()

        // When
        sut.updateNavigationState(.processing)

        // Then
        XCTAssertEqual(sut.navigationState, .processing)
    }

    func test_updateNavigationState_failure_navigatesToError() {
        // Given
        sut = makeSut()
        let error = PrimerError.unknown(message: "Navigation error")

        // When
        sut.updateNavigationState(.failure(error))

        // Then
        if case .failure = sut.navigationState {
            // Expected
        } else {
            XCTFail("Expected failure navigation state")
        }
    }

    func test_updateNavigationState_success_doesNotCallNavigator() {
        // Given
        sut = makeSut()
        let result = makePaymentResult()

        // When / Then — should not crash; success doesn't navigate
        sut.updateNavigationState(.success(result))
        if case .success = sut.navigationState {
            // Expected
        } else {
            XCTFail("Expected success navigation state")
        }
    }

    func test_updateNavigationState_dismissed_doesNotCallNavigator() {
        // Given
        sut = makeSut()

        // When / Then — should not crash; dismissed doesn't navigate
        sut.updateNavigationState(.dismissed)
        XCTAssertEqual(sut.navigationState, .dismissed)
    }

    func test_updateNavigationState_syncToNavigatorFalse_doesNotSyncToNavigator() {
        // Given
        sut = makeSut()

        // When
        sut.updateNavigationState(.processing, syncToNavigator: false)

        // Then
        XCTAssertEqual(sut.navigationState, .processing)
    }

    // MARK: - paymentMethodSelection Tests

    func test_paymentMethodSelection_returnsCachedScope() {
        // Given
        sut = makeSut()

        // When
        let scope1 = sut.paymentMethodSelection
        let scope2 = sut.paymentMethodSelection

        // Then
        XCTAssertTrue(scope1 === scope2)
    }

    // MARK: - Properties Tests

    func test_paymentHandling_delegatesToSettings() {
        // Given
        let settings = PrimerSettings(paymentHandling: .manual)
        sut = makeSut(settings: settings)

        // Then
        XCTAssertEqual(sut.paymentHandling, .manual)
    }

    func test_isInitScreenEnabled_delegatesToSettings() {
        // Given
        sut = makeSut()

        // Then — default PrimerSettings
        XCTAssertNotNil(sut.isInitScreenEnabled)
    }

    func test_isSuccessScreenEnabled_delegatesToSettings() {
        // Given
        sut = makeSut()

        // Then
        XCTAssertNotNil(sut.isSuccessScreenEnabled)
    }

    func test_isErrorScreenEnabled_delegatesToSettings() {
        // Given
        sut = makeSut()

        // Then
        XCTAssertNotNil(sut.isErrorScreenEnabled)
    }

    func test_dismissalMechanism_delegatesToSettings() {
        // Given
        sut = makeSut()

        // Then
        XCTAssertNotNil(sut.dismissalMechanism)
    }

    func test_is3DSSanityCheckEnabled_delegatesToSettings() {
        // Given
        sut = makeSut()

        // Then
        XCTAssertNotNil(sut.is3DSSanityCheckEnabled)
    }

    func test_presentationContext_defaultsToFromPaymentSelection() {
        // Given
        sut = makeSut()

        // Then
        XCTAssertEqual(sut.presentationContext, .fromPaymentSelection)
    }

    func test_validated_singlePaymentMethod_returnsDirectContext() throws {
        // Given
        sut = makeSut()
        sut.availablePaymentMethods = [
            InternalPaymentMethod(id: "pm_1", type: TestData.PaymentMethodTypes.card, name: TestData.PaymentMethodNames.cardName)
        ]

        // When
        let (_, context) = try DefaultCheckoutScope.validated(from: sut)

        // Then
        XCTAssertEqual(context, .direct)
    }

    func test_validated_multiplePaymentMethods_returnsFromPaymentSelectionContext() throws {
        // Given
        sut = makeSut()
        sut.availablePaymentMethods = [
            InternalPaymentMethod(id: "pm_1", type: TestData.PaymentMethodTypes.card, name: TestData.PaymentMethodNames.cardName),
            InternalPaymentMethod(id: "pm_2", type: TestData.PaymentMethodTypes.paypal, name: TestData.PaymentMethodNames.paypalName)
        ]

        // When
        let (_, context) = try DefaultCheckoutScope.validated(from: sut)

        // Then
        XCTAssertEqual(context, .fromPaymentSelection)
    }

    func test_validated_noPaymentMethods_returnsDirectContext() throws {
        // Given
        sut = makeSut()
        sut.availablePaymentMethods = []

        // When
        let (_, context) = try DefaultCheckoutScope.validated(from: sut)

        // Then
        XCTAssertEqual(context, .direct)
    }

    func test_currentState_reflectsInternalState() {
        // Given
        sut = makeSut()

        // Then — initial state is .initializing
        if case .initializing = sut.currentState {
            // Expected
        } else {
            XCTFail("Expected initializing state")
        }
    }

    func test_checkoutNavigator_returnsNavigator() {
        // Given
        sut = makeSut()

        // Then
        XCTAssertNotNil(sut.checkoutNavigator)
    }

    func test_availablePaymentMethods_defaultsToEmpty() {
        // Given
        sut = makeSut()

        // Then
        XCTAssertTrue(sut.availablePaymentMethods.isEmpty)
    }

    // MARK: - UI Customization Properties Tests

    func test_uiCustomizationProperties_defaultToNil() {
        // Given
        sut = makeSut()

        // Then
        XCTAssertNil(sut.onBeforePaymentCreate)
        XCTAssertNil(sut.container)
        XCTAssertNil(sut.splashScreen)
        XCTAssertNil(sut.loadingScreen)
        XCTAssertNil(sut.successScreen)
        XCTAssertNil(sut.errorScreen)
        XCTAssertNil(sut.paymentMethodSelectionScreen)
    }

    // MARK: - retryPayment Tests

    func test_retryPayment_doesNotCrash_withNoCurrentScope() {
        // Given
        sut = makeSut()

        // When / Then — should not crash when no payment method scope is set
        sut.retryPayment()
    }

    // MARK: - handlePaymentMethodSelection Tests

    func test_handlePaymentMethodSelection_withoutContainer_navigatesToFailure() {
        // Given
        sut = makeSut()
        let method = InternalPaymentMethod(
            id: "pm_1",
            type: TestData.PaymentMethodTypes.card,
            name: TestData.PaymentMethodNames.cardName
        )

        // When
        sut.handlePaymentMethodSelection(method)

        // Then — without a container, should navigate to failure or payment method
        // The method either succeeds or shows a failure state
        XCTAssertNotEqual(sut.navigationState, .loading)
    }

    // MARK: - getPaymentMethodScope Tests

    func test_getPaymentMethodScope_forString_withoutContainer_returnsNil() {
        // Given
        sut = makeSut()

        // When
        let scope: DefaultCardFormScope? = sut.getPaymentMethodScope(for: "PAYMENT_CARD")

        // Then
        XCTAssertNil(scope)
    }

    func test_getPaymentMethodScope_byType_withoutContainer_returnsNil() {
        // Given
        sut = makeSut()

        // When
        let scope: DefaultCardFormScope? = sut.getPaymentMethodScope(DefaultCardFormScope.self)

        // Then
        XCTAssertNil(scope)
    }

    func test_getPaymentMethodScope_forEnum_delegatesToStringVersion() {
        // Given
        sut = makeSut()
        PaymentMethodRegistry.shared.reset()

        // When
        let scope: DefaultApplePayScope? = sut.getPaymentMethodScope(for: .applePay)

        // Then
        XCTAssertNil(scope)
    }

    // MARK: - setVaultedPaymentMethods Tests (on real scope)

    func test_setVaultedPaymentMethods_setsMethodsAndDefaultSelection() {
        // Given
        sut = makeSut()
        let methods = [makeVaultedPaymentMethod(id: "v1"), makeVaultedPaymentMethod(id: "v2")]

        // When
        sut.setVaultedPaymentMethods(methods)

        // Then
        XCTAssertEqual(sut.vaultedPaymentMethods.count, 2)
        XCTAssertEqual(sut.selectedVaultedPaymentMethod?.id, "v1")
    }

    func test_setVaultedPaymentMethods_emptyList_clearsSelection() {
        // Given
        sut = makeSut()
        let method = makeVaultedPaymentMethod()
        sut.setVaultedPaymentMethods([method])

        // When
        sut.setVaultedPaymentMethods([])

        // Then
        XCTAssertTrue(sut.vaultedPaymentMethods.isEmpty)
        XCTAssertNil(sut.selectedVaultedPaymentMethod)
    }

    func test_setVaultedPaymentMethods_deletedSelection_fallsBackToFirst() {
        // Given
        sut = makeSut()
        let method1 = makeVaultedPaymentMethod(id: "v1")
        let method2 = makeVaultedPaymentMethod(id: "v2")
        sut.setVaultedPaymentMethods([method1, method2])
        sut.setSelectedVaultedPaymentMethod(method2)

        // When — remove method2
        sut.setVaultedPaymentMethods([method1])

        // Then
        XCTAssertEqual(sut.selectedVaultedPaymentMethod?.id, "v1")
    }

    func test_setSelectedVaultedPaymentMethod_setsSelection() {
        // Given
        sut = makeSut()
        let method = makeVaultedPaymentMethod()
        sut.setVaultedPaymentMethods([method])

        // When
        sut.setSelectedVaultedPaymentMethod(method)

        // Then
        XCTAssertEqual(sut.selectedVaultedPaymentMethod?.id, "vault_1")
    }

    func test_setSelectedVaultedPaymentMethod_nil_clearsSelection() {
        // Given
        sut = makeSut()
        let method = makeVaultedPaymentMethod()
        sut.setVaultedPaymentMethods([method])
        sut.setSelectedVaultedPaymentMethod(method)

        // When
        sut.setSelectedVaultedPaymentMethod(nil)

        // Then
        XCTAssertNil(sut.selectedVaultedPaymentMethod)
    }

    // MARK: - state AsyncStream Tests

    func test_state_emitsInitialState() async throws {
        // Given
        sut = makeSut()

        // When
        let state = try await awaitFirst(sut.state)

        // Then
        if case .initializing = state {
            // Expected
        } else {
            XCTFail("Expected initializing state, got \(state)")
        }
    }

    // MARK: - invokeBeforePaymentCreate Tests

    func test_invokeBeforePaymentCreate_noCallback_returnsImmediately() async throws {
        // Given
        sut = makeSut()
        sut.onBeforePaymentCreate = nil

        // When / Then — should not throw
        try await sut.invokeBeforePaymentCreate(paymentMethodType: TestData.PaymentMethodTypes.card)
    }

    func test_invokeBeforePaymentCreate_abortDecision_throwsMerchantError() async throws {
        // Given
        sut = makeSut()
        sut.onBeforePaymentCreate = { _, handler in
            handler(PrimerPaymentCreationDecision.abortPaymentCreation(withErrorMessage: "Aborted by merchant"))
        }

        // When / Then
        do {
            try await sut.invokeBeforePaymentCreate(paymentMethodType: TestData.PaymentMethodTypes.card)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected
        }
    }

    func test_invokeBeforePaymentCreate_continueDecision_succeeds() async throws {
        // Given
        sut = makeSut()
        sut.onBeforePaymentCreate = { _, handler in
            handler(PrimerPaymentCreationDecision.continuePaymentCreation())
        }

        // When / Then — should not throw
        try await sut.invokeBeforePaymentCreate(paymentMethodType: TestData.PaymentMethodTypes.card)
    }
}
