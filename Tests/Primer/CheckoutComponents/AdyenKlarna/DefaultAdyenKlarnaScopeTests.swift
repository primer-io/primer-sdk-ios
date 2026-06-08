//
//  DefaultAdyenKlarnaScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class DefaultAdyenKlarnaScopeTests: XCTestCase {

    private var mockInteractor: MockProcessAdyenKlarnaPaymentInteractor!
    private var mockRepository: MockAdyenKlarnaRepository!
    private var checkoutScope: DefaultCheckoutScope!
    private var sut: DefaultAdyenKlarnaScope!

    override func setUp() {
        super.setUp()
        mockInteractor = MockProcessAdyenKlarnaPaymentInteractor()
        mockRepository = MockAdyenKlarnaRepository()

        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "testapp://payment")
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: settings,
            navigator: CheckoutNavigator()
        )

        sut = DefaultAdyenKlarnaScope(
            checkoutScope: checkoutScope,
            interactor: mockInteractor,
            repository: mockRepository
        )
    }

    override func tearDown() {
        sut = nil
        checkoutScope = nil
        mockInteractor = nil
        mockRepository = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_isIdle() async throws {
        // Given/When
        let state = try await awaitFirst(sut.state)

        // Then
        XCTAssertEqual(state.status, .idle)
        XCTAssertTrue(state.paymentOptions.isEmpty)
        XCTAssertNil(state.selectedOption)
    }

    // MARK: - Properties

    func test_paymentMethodType_isAdyenKlarna() {
        XCTAssertEqual(sut.paymentMethodType, "ADYEN_KLARNA")
    }

    func test_presentationContext_defaultIsFromPaymentSelection() {
        XCTAssertEqual(sut.presentationContext, .fromPaymentSelection)
    }

    func test_customizationProperties_areNilByDefault() {
        XCTAssertNil(sut.screen)
        XCTAssertNil(sut.payButton)
        XCTAssertNil(sut.submitButtonText)
    }

    // MARK: - start() with Multiple Options

    func test_start_multipleOptions_transitionsToOptionSelection() async throws {
        // Given
        let options = [
            AdyenKlarnaPaymentOption(id: "pay_later", name: "Pay Later"),
            AdyenKlarnaPaymentOption(id: "pay_now", name: "Pay Now"),
        ]
        mockInteractor.fetchPaymentOptionsResult = .success(options)

        // When
        sut.start()

        // Then
        let state = try await awaitValue(sut.state, matching: { $0.status == .optionSelection })
        XCTAssertEqual(state.paymentOptions.count, 2)
        XCTAssertEqual(state.paymentOptions[0].id, "pay_later")
        XCTAssertNil(state.selectedOption)
    }

    // MARK: - start() with Single Option

    func test_start_singleOption_autoSelects() async throws {
        // Given
        let options = [AdyenKlarnaPaymentOption(id: "pay_later", name: "Pay Later")]
        mockInteractor.fetchPaymentOptionsResult = .success(options)
        PrimerInternal.shared.intent = .vault

        // When
        sut.start()

        // Then — should auto-select and proceed to payment
        let state = try await awaitValue(sut.state, matching: { $0.selectedOption != nil })
        XCTAssertEqual(state.selectedOption?.id, "pay_later")
    }

    // MARK: - start() with Empty Options

    func test_start_emptyOptions_transitionsToFailure() async throws {
        // Given
        mockInteractor.fetchPaymentOptionsResult = .success([])

        // When
        sut.start()

        // Then
        let state = try await awaitValue(sut.state, matching: {
            if case .failure = $0.status { return true }
            return false
        })
        if case let .failure(message) = state.status {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected failure state")
        }
    }

    // MARK: - start() with Fetch Error

    func test_start_fetchError_transitionsToFailure() async throws {
        // Given
        mockInteractor.fetchPaymentOptionsResult = .failure(PrimerError.invalidValue(key: "test"))

        // When
        sut.start()

        // Then
        let state = try await awaitValue(sut.state, matching: {
            if case .failure = $0.status { return true }
            return false
        })
        XCTAssertNotNil(state)
    }

    func test_start_emptyOptions_propagatesErrorToCheckoutScope() async throws {
        // Given
        mockInteractor.fetchPaymentOptionsResult = .success([])

        // When
        sut.start()

        // Then — local failure surfaces, and the checkout-level error handler is notified
        _ = try await awaitValue(sut.state, matching: {
            if case .failure = $0.status { return true }
            return false
        })
        guard case .failure = checkoutScope.currentState else {
            return XCTFail("Expected checkout scope to be notified of failure")
        }
    }

    func test_start_fetchError_propagatesErrorToCheckoutScope() async throws {
        // Given
        mockInteractor.fetchPaymentOptionsResult = .failure(PrimerError.invalidValue(key: "test"))

        // When
        sut.start()

        // Then — the checkout-level error handler is notified, matching the submit path
        _ = try await awaitValue(sut.state, matching: {
            if case .failure = $0.status { return true }
            return false
        })
        guard case .failure = checkoutScope.currentState else {
            return XCTFail("Expected checkout scope to be notified of failure")
        }
    }

    func test_start_cancelledError_doesNotTransitionToFailure() async throws {
        // Given
        mockInteractor.fetchPaymentOptionsResult = .failure(
            PrimerError.cancelled(paymentMethodType: "ADYEN_KLARNA")
        )

        // When
        sut.start()

        // Then — cancellation must not surface as a payment failure on the Klarna scope, nor be
        // propagated to the checkout scope as a payment error. (The real checkout scope may
        // independently fail its own DI setup in this isolated test, so we assert it did not fail
        // *with the cancellation error* — the only failure the Klarna scope could propagate here.)
        // why: asserting absence of a failure — there is no positive signal to await on the
        // cancellation path (it returns early without yielding), so wait a tick then verify nothing failed.
        try await Task.sleep(nanoseconds: 200_000_000)
        let currentState = try await awaitFirst(sut.state)
        if case .failure = currentState.status {
            XCTFail("Cancellation must not surface as a payment failure on the Klarna scope")
        }
        if case let .failure(error) = checkoutScope.currentState, case .cancelled = error {
            XCTFail("Cancellation must not propagate to the checkout scope as a payment error")
        }
    }

    // MARK: - selectOption

    func test_selectOption_setsSelectedOptionAndSubmits() async throws {
        // Given
        let option = AdyenKlarnaPaymentOption(id: "pay_later", name: "Pay Later")
        PrimerInternal.shared.intent = .vault

        // When
        sut.selectOption(option)

        // Then
        let state = try await awaitValue(sut.state, matching: { $0.selectedOption != nil })
        XCTAssertEqual(state.selectedOption, option)
        XCTAssertEqual(mockInteractor.lastSelectedOption, option)
    }

    // MARK: - cancel

    func test_cancel_resetsStateToIdle() {
        // When
        sut.cancel()

        // Then — should call cancelPolling on repository
        XCTAssertEqual(mockRepository.cancelPollingCallCount, 1)
    }

    // MARK: - submit without selection

    func test_submit_withoutSelectedOption_doesNothing() {
        // Given - no option selected

        // When
        sut.submit()

        // Then
        XCTAssertEqual(mockInteractor.executeCallCount, 0)
    }

    // MARK: - Customization

    func test_submitButtonText_canBeSet() {
        // When
        sut.submitButtonText = "Custom Text"

        // Then
        XCTAssertEqual(sut.submitButtonText, "Custom Text")
    }

    // MARK: - State with Payment Method

    func test_initialState_withPaymentMethod_includesPaymentMethod() {
        // Given
        let paymentMethod = CheckoutPaymentMethod(id: "test", type: "ADYEN_KLARNA", name: "Klarna")
        let scope = DefaultAdyenKlarnaScope(
            checkoutScope: checkoutScope,
            interactor: mockInteractor,
            repository: mockRepository,
            paymentMethod: paymentMethod,
            surchargeAmount: "+ €0.50"
        )

        // Then — verify properties are set (state stream starts with these)
        XCTAssertEqual(scope.paymentMethodType, "ADYEN_KLARNA")
    }

    // MARK: - Helpers

    private func collectFirstState() async -> PrimerAdyenKlarnaState? {
        let stream = sut.state
        return await withCheckedContinuation { continuation in
            Task {
                for await state in stream {
                    continuation.resume(returning: state)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }
}
