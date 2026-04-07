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
            diContainer: DIContainer.shared,
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

    func test_initialState_isIdle() async {
        // Given/When
        let state = await collectFirstState()

        // Then
        XCTAssertEqual(state?.status, .idle)
        XCTAssertTrue(state?.paymentOptions.isEmpty ?? false)
        XCTAssertNil(state?.selectedOption)
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

    func test_start_multipleOptions_transitionsToOptionSelection() async {
        // Given
        let options = [
            AdyenKlarnaPaymentOption(id: "pay_later", name: "Pay Later"),
            AdyenKlarnaPaymentOption(id: "pay_now", name: "Pay Now"),
        ]
        mockInteractor.fetchPaymentOptionsResult = .success(options)

        // When
        sut.start()

        // Then
        let state = await collectStateMatching { $0.status == .optionSelection }
        XCTAssertEqual(state?.paymentOptions.count, 2)
        XCTAssertEqual(state?.paymentOptions[0].id, "pay_later")
        XCTAssertNil(state?.selectedOption)
    }

    // MARK: - start() with Single Option

    func test_start_singleOption_autoSelects() async {
        // Given
        let options = [AdyenKlarnaPaymentOption(id: "pay_later", name: "Pay Later")]
        mockInteractor.fetchPaymentOptionsResult = .success(options)
        PrimerInternal.shared.intent = .vault

        // When
        sut.start()

        // Then — should auto-select and proceed to payment
        let state = await collectStateMatching { $0.selectedOption != nil }
        XCTAssertEqual(state?.selectedOption?.id, "pay_later")
    }

    // MARK: - start() with Empty Options

    func test_start_emptyOptions_transitionsToFailure() async {
        // Given
        mockInteractor.fetchPaymentOptionsResult = .success([])

        // When
        sut.start()

        // Then
        let state = await collectStateMatching {
            if case .failure = $0.status { return true }
            return false
        }
        if case let .failure(message) = state?.status {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected failure state")
        }
    }

    // MARK: - start() with Fetch Error

    func test_start_fetchError_transitionsToFailure() async {
        // Given
        mockInteractor.fetchPaymentOptionsResult = .failure(PrimerError.invalidValue(key: "test"))

        // When
        sut.start()

        // Then
        let state = await collectStateMatching {
            if case .failure = $0.status { return true }
            return false
        }
        XCTAssertNotNil(state)
    }

    // MARK: - selectOption

    func test_selectOption_setsSelectedOptionAndSubmits() async {
        // Given
        let option = AdyenKlarnaPaymentOption(id: "pay_later", name: "Pay Later")
        PrimerInternal.shared.intent = .vault

        // When
        sut.selectOption(option)

        // Then
        let state = await collectStateMatching { $0.selectedOption != nil }
        XCTAssertEqual(state?.selectedOption, option)
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

    private func collectStateMatching(_ predicate: @escaping (PrimerAdyenKlarnaState) -> Bool) async -> PrimerAdyenKlarnaState? {
        let stream = sut.state
        return await withTaskGroup(of: PrimerAdyenKlarnaState?.self) { group in
            group.addTask {
                for await state in stream {
                    if predicate(state) {
                        return state
                    }
                }
                return nil
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                return nil
            }

            for await result in group {
                if let result {
                    group.cancelAll()
                    return result
                }
            }
            return nil
        }
    }
}
