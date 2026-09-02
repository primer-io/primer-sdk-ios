//
//  DefaultCheckoutScopePaymentHandlingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

/// Checkout Components creates the payment itself. A session started with `.manual` must fail
/// before any payment attempt instead of hanging on the processing screen.
@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScopePaymentHandlingTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        await DIContainer.setContainer(try await ContainerTestHelpers.createTestContainer())
    }

    override func tearDown() async throws {
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_init_manualPaymentHandling_failsWithInvalidValue() async throws {
        let sut = makeSut(paymentHandling: .manual)

        let state = await settledState(of: sut)

        guard case let .failure(error) = state else {
            return XCTFail("Expected .failure, got \(state)")
        }
        XCTAssertEqual(error.errorId, "invalid-value")
        XCTAssertTrue(error.errorDescription?.contains("paymentHandling") == true)
        XCTAssertEqual(sut.navigationState, .failure(error))
    }

    func test_init_autoPaymentHandling_doesNotRejectSettings() async throws {
        let sut = makeSut(paymentHandling: .auto)

        let state = await settledState(of: sut)

        if case let .failure(error) = state {
            XCTAssertNotEqual(error.errorId, "invalid-value")
        }
    }

    private func makeSut(paymentHandling: PrimerPaymentHandling) -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(
                paymentHandling: paymentHandling,
                uiOptions: PrimerUIOptions(isInitScreenEnabled: false)
            ),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
    }

    /// Drains the state stream until the scope leaves `.initializing`, bounded so a broken init
    /// cannot hang the suite.
    private func settledState(of scope: DefaultCheckoutScope) async -> PrimerCheckoutState {
        let deadline = Date().addingTimeInterval(5)
        for await state in scope.state {
            if case .initializing = state, Date() < deadline { continue }
            return state
        }
        return scope.currentState
    }
}
