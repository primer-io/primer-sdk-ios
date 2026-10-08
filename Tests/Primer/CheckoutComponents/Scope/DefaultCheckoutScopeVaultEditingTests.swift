//
//  DefaultCheckoutScopeVaultEditingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
import XCTest

/// Edit mode lives in the scope, not in the list's view, so only navigation can end it when the list goes away.
@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScopeVaultEditingTests: XCTestCase {

    private var sut: DefaultCheckoutScope!

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
        sut = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
        )
        sut.updateNavigationState(.vaultedPaymentMethods)
        sut.setVaultEditing(true)
    }

    override func tearDown() async throws {
        sut = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_dismissingTheInlineSheet_endsEditMode() {
        sut.cancelActivePaymentMethod(returnToSelection: true)

        XCTAssertFalse(sut.isVaultEditing)
    }

    func test_dismissingTheCheckout_endsEditMode() {
        sut.cancelActivePaymentMethod(returnToSelection: false)

        XCTAssertFalse(sut.isVaultEditing)
    }

    func test_leavingTheVaultFlowForAnotherScreen_endsEditMode() {
        sut.updateNavigationState(.paymentMethod(PrimerPaymentMethodType.paymentCard.rawValue))

        XCTAssertFalse(sut.isVaultEditing)
    }

    func test_openingAndCancellingADelete_keepsEditMode() {
        sut.updateNavigationState(.deleteVaultedPaymentMethodConfirmation(makeVaultedPaymentMethod()))
        XCTAssertTrue(sut.isVaultEditing)

        sut.updateNavigationState(.vaultedPaymentMethods)
        XCTAssertTrue(sut.isVaultEditing)
    }

    private func makeVaultedPaymentMethod() -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        let data = try! JSONSerialization.data(withJSONObject: ["last4Digits": "4242"]) // swiftlint:disable:this force_try
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )
        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: "vault_1",
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics_vault_1"
        )
    }
}
