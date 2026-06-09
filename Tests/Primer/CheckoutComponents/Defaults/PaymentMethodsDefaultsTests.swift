//
//  PaymentMethodsDefaultsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
final class PaymentMethodsDefaultsTests: XCTestCase {

  // MARK: - Helpers

  private func makeSession(
    state: PrimerPaymentMethodSelectionState = .init(),
    vaulted: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
  ) -> PrimerSelectionSession {
    let scope = MockSelectionScopeInternal()
    scope.stubbedCurrentState = state
    scope.stubbedVaultedPaymentMethods = vaulted
    return PrimerSelectionSession(scope: scope)
  }

  private func makeVaultedCard(id: String = "vault_1") -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
    let data = try! JSONSerialization.data(withJSONObject: ["last4Digits": "4242", "network": "VISA"]) // swiftlint:disable:this force_try
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

  // MARK: - PaymentMethodsDefaults section helpers

  func test_method_buildsRowForwardingSelection() {
    var selected = false
    let method = CheckoutPaymentMethod(id: "pm_1", type: "PAYMENT_CARD", name: "Card")
    let row = PaymentMethodsDefaults.method(method) { selected = true }
    XCTAssertEqual(row.method, method)
    row.onSelect()
    XCTAssertTrue(selected)
  }

  func test_header_emptyState_unavailable_render() {
    let session = makeSession()
    XCTAssertTrue(SwiftUIRenderProbe.render(PaymentMethodsDefaults.header(session)))
    XCTAssertTrue(SwiftUIRenderProbe.render(PaymentMethodsDefaults.emptyState(session)))
    XCTAssertTrue(SwiftUIRenderProbe.render(PaymentMethodsDefaults.unavailable()))
  }

  func test_methodRowContent_rendersBrandedButton() {
    let method = CheckoutPaymentMethod(id: "pm_1", type: "PAYMENT_CARD", name: "Card")
    XCTAssertTrue(SwiftUIRenderProbe.render(PaymentMethodsDefaults.method(method) {}))
  }

  // MARK: - VaultedPaymentMethodsDefaults section helpers

  func test_vaulted_header_item_submit_render() {
    let session = makeSession()
    let vaulted = makeVaultedCard()
    XCTAssertTrue(SwiftUIRenderProbe.render(VaultedPaymentMethodsDefaults.header(session)))
    XCTAssertTrue(SwiftUIRenderProbe.render(VaultedPaymentMethodsDefaults.item(vaulted, isSelected: true, onSelect: {})))
    XCTAssertTrue(SwiftUIRenderProbe.render(VaultedPaymentMethodsDefaults.item(vaulted, isSelected: false, onSelect: {})))
    XCTAssertTrue(SwiftUIRenderProbe.render(VaultedPaymentMethodsDefaults.submitButton(isLoading: true, isEnabled: false, onSubmit: {})))
    XCTAssertTrue(SwiftUIRenderProbe.render(VaultedPaymentMethodsDefaults.submitButton(isLoading: false, isEnabled: true, onSubmit: {})))
    XCTAssertTrue(SwiftUIRenderProbe.render(VaultedPaymentMethodsDefaults.unavailable()))
  }

  func test_vaulted_cvvInput_rendersWhenRequired() {
    var state = PrimerPaymentMethodSelectionState()
    state.requiresCvvInput = true
    state.selectedVaultedPaymentMethod = makeVaultedCard()
    let session = makeSession(state: state)
    XCTAssertTrue(SwiftUIRenderProbe.render(VaultedPaymentMethodsDefaults.cvvInput(session)))
  }

  func test_vaulted_cvvInput_emptyWhenNotRequired() {
    let session = makeSession()
    XCTAssertFalse(session.state.requiresCvvInput)
    XCTAssertTrue(SwiftUIRenderProbe.render(VaultedPaymentMethodsDefaults.cvvInput(session)))
  }

  // MARK: - Composable views (full render through Bound)

  func test_vaultedPaymentMethods_rendersBoundListWithCvvRecapture() {
    var state = PrimerPaymentMethodSelectionState()
    let card = makeVaultedCard()
    state.requiresCvvInput = true
    state.selectedVaultedPaymentMethod = card
    state.isVaultPaymentLoading = true
    let session = makeSession(state: state, vaulted: [card, makeVaultedCard(id: "vault_2")])
    let view = PrimerVaultedPaymentMethods().environment(\.primerSelectionSession, session)
    XCTAssertTrue(SwiftUIRenderProbe.render(view))
  }

  func test_vaultedPaymentMethods_rendersUnavailableWithoutSession() {
    XCTAssertTrue(SwiftUIRenderProbe.render(PrimerVaultedPaymentMethods()))
  }

  func test_paymentMethods_rendersBoundListWithMethods() {
    var state = PrimerPaymentMethodSelectionState()
    state.paymentMethods = [
      CheckoutPaymentMethod(id: "pm_1", type: "PAYMENT_CARD", name: "Card"),
      CheckoutPaymentMethod(id: "pm_2", type: "PAYPAL", name: "PayPal")
    ]
    let session = makeSession(state: state)
    let view = PrimerPaymentMethods().environment(\.primerSelectionSession, session)
    XCTAssertTrue(SwiftUIRenderProbe.render(view))
  }

  func test_paymentMethods_rendersEmptyState() {
    let session = makeSession()
    let view = PrimerPaymentMethods().environment(\.primerSelectionSession, session)
    XCTAssertTrue(SwiftUIRenderProbe.render(view))
  }

  func test_paymentMethods_rendersUnavailableWithoutSession() {
    XCTAssertTrue(SwiftUIRenderProbe.render(PrimerPaymentMethods()))
  }
}
