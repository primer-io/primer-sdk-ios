//
//  BackendDrivenPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerSDK
import XCTest

@available(iOS 16.0, *)
@MainActor
final class BackendDrivenPaymentMethodTests: XCTestCase {
    override func tearDown() async throws {
        PaymentMethodRegistry.shared.reset()
        try await super.tearDown()
    }

    func testABackendDrivenTypeReplacesTheNativeRegistrationForThatType() async throws {
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
        try await withTimeout(3.0) {
            while checkoutScope.navigationState == .loading { await Task.yield() }
        }
        let type = AdyenKlarnaPaymentMethod.paymentMethodType
        PaymentMethodRegistry.shared.reset()
        AdyenKlarnaPaymentMethod.register()

        BackendDrivenPaymentMethod.register(types: [type])

        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: type,
            checkoutScope: checkoutScope,
            diContainer: Container()
        )
        XCTAssertTrue(scope is DefaultBackendDrivenScope)
    }

    func testACardKeepsItsNativeRegistrationWhenFlaggedBackendDriven() async throws {
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
        try await withTimeout(3.0) {
            while checkoutScope.navigationState == .loading { await Task.yield() }
        }
        PaymentMethodRegistry.shared.reset()

        BackendDrivenPaymentMethod.register(types: [CardPaymentMethod.paymentMethodType])

        XCTAssertFalse(PaymentMethodRegistry.shared.registeredTypes.contains(CardPaymentMethod.paymentMethodType))
    }
}
