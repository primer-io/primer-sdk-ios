//
//  DefaultCheckoutScopeVaultIntentTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

/// Under `.vault` the checkout saves a payment method and never pays: it needs a customer, offers only
/// methods it can save, skips the payment gate and saved methods, and ends in `.vaulted`.
@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScopeVaultIntentTests: XCTestCase {

    private let customer = ClientSession.Customer(id: "customer_id")
    private let token = PrimerPaymentMethodToken(token: "multi_use_token", paymentMethodType: "PAYMENT_CARD")

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
    }

    override func tearDown() async throws {
        PrimerInternal.shared.intent = nil
        SDKSessionHelper.tearDown()
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_vault_keepsOnlyMethodsThatCanBeSaved() async throws {
        let sut = try await makeSut(paymentMethods: [cardMethod, payPalMethod])

        let state = await settledState(of: sut)

        guard case .ready = state else { return XCTFail("Expected .ready, got \(state)") }
        XCTAssertEqual(sut.availablePaymentMethods.map(\.type), ["PAYMENT_CARD"])
    }

    func test_checkout_keepsEveryRegisteredMethod() async throws {
        let sut = try await makeSut(intent: .checkout, paymentMethods: [cardMethod, payPalMethod])

        _ = await settledState(of: sut)

        XCTAssertEqual(Set(sut.availablePaymentMethods.map(\.type)), ["PAYMENT_CARD", "PAYPAL"])
    }

    func test_vault_withoutCustomerId_failsWithInvalidCustomerId() async throws {
        let sut = try await makeSut(hasCustomer: false)

        let state = await settledState(of: sut)

        guard case let .failure(error, _) = state else { return XCTFail("Expected .failure, got \(state)") }
        guard case let .invalidClientSessionValue(name, _, _, _) = error else {
            return XCTFail("Expected .invalidClientSessionValue, got \(error)")
        }
        XCTAssertEqual(name, "customer.id")
    }

    func test_vault_withoutMethodThatCanBeSaved_failsWithUnsupportedIntent() async throws {
        let sut = try await makeSut(paymentMethods: [payPalMethod])

        let state = await settledState(of: sut)

        guard case let .failure(error, _) = state else { return XCTFail("Expected .failure, got \(state)") }
        guard case let .unsupportedIntent(intent, _) = error else {
            return XCTFail("Expected .unsupportedIntent, got \(error)")
        }
        XCTAssertEqual(intent, .vault)
    }

    func test_vault_skipsTheBeforePaymentCreateHandler() async throws {
        let sut = try await makeSut()
        var handlerCalls = 0
        sut.onBeforePaymentCreate = { _, decisionHandler in
            handlerCalls += 1
            decisionHandler(.abortPaymentCreation(withErrorMessage: "aborted"))
        }

        try await sut.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")

        XCTAssertEqual(handlerCalls, 0)
    }

    func test_vault_neverFetchesSavedPaymentMethods() async throws {
        let repository = MockHeadlessRepository()
        let sut = try await makeSut(paymentMethods: [cardMethod], repository: repository)

        _ = await settledState(of: sut)
        await (sut.paymentMethodSelectionInternal as? DefaultPaymentMethodSelectionScope)?.refreshVaultedPaymentMethods()

        XCTAssertEqual(repository.fetchVaultedPaymentMethodsCallCount, 0)
    }

    func test_checkout_withSingleMethod_fetchesSavedPaymentMethods() async throws {
        let repository = MockHeadlessRepository()
        let sut = try await makeSut(intent: .checkout, paymentMethods: [cardMethod], repository: repository)

        _ = await settledState(of: sut)

        XCTAssertGreaterThan(repository.fetchVaultedPaymentMethodsCallCount, 0)
    }

    func test_handleVaultSuccess_endsInVaultedStateAndScreen() async throws {
        let sut = try await makeSut()
        _ = await settledState(of: sut)

        sut.handleVaultSuccess(token)

        XCTAssertEqual(sut.currentState, .vaulted(token))
        XCTAssertEqual(sut.navigationState, .vaulted(token))
    }

    func test_vault_ignoresASelectedMethodThatCannotBeSaved() async throws {
        let sut = try await makeSut(paymentMethods: [cardMethod, payPalMethod])
        _ = await settledState(of: sut)
        let navigationBefore = sut.navigationState

        sut.handlePaymentMethodSelection(InternalPaymentMethod(id: "paypal", type: "PAYPAL", name: "PayPal"))

        XCTAssertEqual(sut.navigationState, navigationBefore)
    }

    func test_vault_startsAnOfferedMethod() async throws {
        let sut = try await makeSut(paymentMethods: [cardMethod, payPalMethod])
        _ = await settledState(of: sut)

        sut.handlePaymentMethodSelection(InternalPaymentMethod(id: "card", type: "PAYMENT_CARD", name: "Card"))

        XCTAssertEqual(sut.navigationState, .paymentMethod("PAYMENT_CARD"))
    }

    // MARK: - Per-method intents

    func test_mix_savesTheCardAndKeepsTheMethodsThatPay() async throws {
        let sut = try await makeSut(intent: .checkout, paymentMethodIntents: savedCard, paymentMethods: [cardMethod, payPalMethod])

        let state = await settledState(of: sut)

        guard case .ready = state else { return XCTFail("Expected .ready, got \(state)") }
        XCTAssertEqual(Set(sut.availablePaymentMethods.map(\.type)), ["PAYMENT_CARD", "PAYPAL"])
        XCTAssertEqual(sut.intent(for: "PAYMENT_CARD"), .vault)
        XCTAssertEqual(sut.intent(for: "PAYPAL"), .checkout)
    }

    func test_mix_sessionVaultWithAPayingOverride_keepsTheOverriddenMethod() async throws {
        let sut = try await makeSut(paymentMethodIntents: ["PAYPAL": .checkout], paymentMethods: [cardMethod, payPalMethod])

        _ = await settledState(of: sut)

        XCTAssertEqual(Set(sut.availablePaymentMethods.map(\.type)), ["PAYMENT_CARD", "PAYPAL"])
    }

    func test_mix_explicitVaultForAMethodThatCannotBeSaved_failsAtStart() async throws {
        let sut = try await makeSut(intent: .checkout, paymentMethodIntents: ["PAYPAL": .vault], paymentMethods: [cardMethod, payPalMethod])

        let state = await settledState(of: sut)

        guard case let .failure(error, _) = state else { return XCTFail("Expected .failure, got \(state)") }
        guard case .unsupportedIntent(.vault, _) = error else { return XCTFail("Expected .unsupportedIntent, got \(error)") }
    }

    func test_mix_ignoresAKeyForAMethodTheSessionDoesNotOffer() async throws {
        let sut = try await makeSut(intent: .checkout, paymentMethodIntents: ["KLARNA": .vault], hasCustomer: false)

        let state = await settledState(of: sut)

        guard case .ready = state else { return XCTFail("Expected .ready, got \(state)") }
    }

    func test_mix_withoutCustomerId_failsWhenAMethodSaves() async throws {
        let sut = try await makeSut(intent: .checkout, paymentMethodIntents: savedCard, hasCustomer: false)

        let state = await settledState(of: sut)

        guard case let .failure(error, _) = state else { return XCTFail("Expected .failure, got \(state)") }
        guard case .invalidClientSessionValue = error else { return XCTFail("Expected .invalidClientSessionValue, got \(error)") }
    }

    func test_mix_withoutCustomerId_startsWhenEveryOfferedMethodPays() async throws {
        let sut = try await makeSut(paymentMethodIntents: ["PAYMENT_CARD": .checkout], hasCustomer: false)

        let state = await settledState(of: sut)

        guard case .ready = state else { return XCTFail("Expected .ready, got \(state)") }
    }

    func test_mix_beforePaymentCreate_skipsTheSaveAndAppliesEachMethodIntent() async throws {
        let sut = try await makeSut(intent: .checkout, paymentMethodIntents: savedCard, paymentMethods: [cardMethod, payPalMethod])
        _ = await settledState(of: sut)
        var handledTypes: [String] = []
        sut.onBeforePaymentCreate = { data, decisionHandler in
            handledTypes.append(data.paymentMethodType.type)
            decisionHandler(.continuePaymentCreation())
        }

        try await sut.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")
        XCTAssertEqual(PrimerInternal.shared.intent, .vault)
        try await sut.invokeBeforePaymentCreate(paymentMethodType: "PAYPAL")
        XCTAssertEqual(PrimerInternal.shared.intent, .checkout)

        XCTAssertEqual(handledTypes, ["PAYPAL"])
    }

    func test_mix_selectingAMethod_appliesItsIntent() async throws {
        let sut = try await makeSut(intent: .checkout, paymentMethodIntents: savedCard, paymentMethods: [cardMethod, payPalMethod])
        _ = await settledState(of: sut)
        PrimerInternal.shared.intent = .checkout

        sut.handlePaymentMethodSelection(InternalPaymentMethod(id: "card", type: "PAYMENT_CARD", name: "Card"))

        XCTAssertEqual(PrimerInternal.shared.intent, .vault)
        XCTAssertEqual(sut.navigationState, .paymentMethod("PAYMENT_CARD"))
    }

    func test_mix_showsSavedMethodsOnlyForTypesThatPay() async throws {
        let sut = try await makeSut(intent: .checkout, paymentMethodIntents: savedCard, paymentMethods: [cardMethod, payPalMethod])
        _ = await settledState(of: sut)

        sut.setVaultedPaymentMethods([savedMethod(type: "PAYMENT_CARD"), savedMethod(type: "PAYPAL")])

        XCTAssertEqual(sut.vaultedPaymentMethods.map(\.paymentMethodType), ["PAYPAL"])
    }

    func test_mix_fetchesSavedMethodsWhenATypePays() async throws {
        let repository = MockHeadlessRepository()
        let sut = try await makeSut(paymentMethodIntents: ["PAYPAL": .checkout], paymentMethods: [cardMethod], repository: repository)

        _ = await settledState(of: sut)

        XCTAssertGreaterThan(repository.fetchVaultedPaymentMethodsCallCount, 0)
    }

    // MARK: - Helpers

    private var cardMethod: PrimerPaymentMethod { Mocks.PaymentMethods.paymentCardPaymentMethod }
    private var payPalMethod: PrimerPaymentMethod { Mocks.PaymentMethods.paypalPaymentMethod }
    private let savedCard: [String: PrimerSessionIntent] = ["PAYMENT_CARD": .vault]

    private func savedMethod(type: String) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        // swiftlint:disable:next force_try
        let instrumentData = try! JSONDecoder().decode(
            Response.Body.Tokenization.PaymentInstrumentData.self, from: Data(#"{"last4Digits":"4242"}"#.utf8)
        )
        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: "saved_\(type)",
            paymentMethodType: type,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_\(type)"
        )
    }

    private func makeSut(
        intent: PrimerSessionIntent = .vault,
        paymentMethodIntents: [String: PrimerSessionIntent] = [:],
        paymentMethods: [PrimerPaymentMethod]? = nil,
        hasCustomer: Bool = true,
        repository: MockHeadlessRepository? = nil
    ) async throws -> DefaultCheckoutScope {
        SDKSessionHelper.setUp(
            withPaymentMethods: paymentMethods ?? [cardMethod],
            customer: hasCustomer ? customer : nil
        )
        let container = try await ContainerTestHelpers.createTestContainer(
            apiConfiguration: PrimerAPIConfigurationModule.apiConfiguration
        )
        if let repository {
            _ = try await container.register(HeadlessRepository.self).asSingleton().with { _ in repository }
        }
        await DIContainer.setContainer(container)

        return DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(uiOptions: PrimerUIOptions(isInitScreenEnabled: false)),
            intent: intent,
            paymentMethodIntents: paymentMethodIntents,
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
    }

    /// Drains the state stream until the scope leaves `.initializing`, racing a five second timer.
    private func settledState(of scope: DefaultCheckoutScope) async -> PrimerCheckoutState {
        await withTaskGroup(of: PrimerCheckoutState.self) { group in
            group.addTask { @MainActor in
                for await state in scope.state where state != .initializing { return state }
                return scope.currentState
            }
            group.addTask { @MainActor in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                return scope.currentState
            }
            let first = await group.next() ?? scope.currentState
            group.cancelAll()
            return first
        }
    }
}
