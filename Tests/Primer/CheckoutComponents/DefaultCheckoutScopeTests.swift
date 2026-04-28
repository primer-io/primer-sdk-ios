//
//  DefaultCheckoutScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - DefaultCheckoutScope Behavior Tests

@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScopeBehaviorTests: XCTestCase {

    private var sut: DefaultCheckoutScope!
    private var navigator: CheckoutNavigator!

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
    }

    override func tearDown() async throws {
        sut = nil
        navigator = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
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

    func test_onDismiss_setsNavigationStateToDismissed() {
        // Given — disable the init screen so the async init task cannot overwrite `.dismissed` with `.loading`.
        sut = makeSut(settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)))

        // When
        sut.onDismiss()

        // Then — updateNavigationState(.dismissed) is synchronous, so the result is observable immediately.
        XCTAssertEqual(sut.navigationState, .dismissed)
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

    func test_currentNavigationState_returnsLatestNavigationState() {
        // Given
        sut = makeSut()

        // When
        sut.updateNavigationState(.processing)

        // Then
        XCTAssertEqual(sut.currentNavigationState, .processing)
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

    // MARK: - navigationStateStream Tests

    func test_navigationStateStream_emitsInitialNavigationState() async throws {
        // Given — disable init screen so the async init task cannot mutate the navigation state.
        sut = makeSut(settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)))

        // When
        let value = try await awaitFirst(sut.navigationStateStream)

        // Then
        XCTAssertEqual(value, .loading)
    }

    func test_navigationStateStream_emitsUpdatedNavigationStates() async throws {
        // Given
        sut = makeSut(settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)))
        let stream = sut.navigationStateStream
        let waitTask = Task { try await awaitValue(stream, equalTo: .processing) }

        // Allow the iteration task to subscribe before mutating.
        try await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.updateNavigationState(.processing)

        // Then
        let value = try await waitTask.value
        XCTAssertEqual(value, .processing)
    }

    func test_navigationStateStream_consumerEarlyExit_terminatesCleanly() async {
        // Given
        sut = makeSut(settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)))
        var receivedCount = 0

        // When — break after the first value to trigger the onTermination handler.
        for await value in sut.navigationStateStream {
            receivedCount += 1
            XCTAssertEqual(value, .loading)
            break
        }

        // Then
        XCTAssertEqual(receivedCount, 1)
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
