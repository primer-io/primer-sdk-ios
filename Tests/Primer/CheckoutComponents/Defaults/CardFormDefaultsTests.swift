//
//  CardFormDefaultsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
final class CardFormDefaultsTests: XCTestCase {

  private func makeSession(
    formConfiguration: CardFormConfiguration = .default,
    availableNetworks: [CardNetwork] = []
  ) -> PrimerCardFormSession {
    PrimerCardFormSession(
      scope: MockCardFormScope(
        availableNetworks: availableNetworks,
        formConfiguration: formConfiguration,
        enableLogging: false
      )
    )
  }

  // MARK: - Section helpers return concrete types

  func test_cardDetails_returnsCardDetailsContent_boundToSession() {
    let session = makeSession()
    let content = CardFormDefaults.cardDetails(session)
    XCTAssertTrue(content.session === session)
  }

  func test_billingAddress_returnsBillingAddressContent_boundToSession() {
    let session = makeSession()
    let content: BillingAddressContent = CardFormDefaults.billingAddress(session)
    XCTAssertTrue(content.session === session)
  }

  func test_submitButton_returnsCardSubmitButton_boundToSession() {
    let session = makeSession()
    let content: CardSubmitButton = CardFormDefaults.submitButton(session)
    XCTAssertTrue(content.session === session)
  }

  // MARK: - Field helpers map to the correct PrimerInputElementType

  func test_cardNumber_mapsToCardNumberField() {
    XCTAssertEqual(CardFormDefaults.cardNumber(makeSession()).field, .cardNumber)
  }

  func test_expiryDate_mapsToExpiryDateField() {
    XCTAssertEqual(CardFormDefaults.expiryDate(makeSession()).field, .expiryDate)
  }

  func test_cvv_mapsToCvvField() {
    XCTAssertEqual(CardFormDefaults.cvv(makeSession()).field, .cvv)
  }

  func test_cardholderName_mapsToCardholderNameField() {
    XCTAssertEqual(CardFormDefaults.cardholderName(makeSession()).field, .cardholderName)
  }

  func test_countryCode_mapsToCountryCodeField() {
    XCTAssertEqual(CardFormDefaults.countryCode(makeSession()).field, .countryCode)
  }

  func test_firstName_mapsToFirstNameField() {
    XCTAssertEqual(CardFormDefaults.firstName(makeSession()).field, .firstName)
  }

  func test_lastName_mapsToLastNameField() {
    XCTAssertEqual(CardFormDefaults.lastName(makeSession()).field, .lastName)
  }

  func test_addressLine1_mapsToAddressLine1Field() {
    XCTAssertEqual(CardFormDefaults.addressLine1(makeSession()).field, .addressLine1)
  }

  func test_addressLine2_mapsToAddressLine2Field() {
    XCTAssertEqual(CardFormDefaults.addressLine2(makeSession()).field, .addressLine2)
  }

  func test_city_mapsToCityField() {
    XCTAssertEqual(CardFormDefaults.city(makeSession()).field, .city)
  }

  func test_state_mapsToStateField() {
    XCTAssertEqual(CardFormDefaults.state(makeSession()).field, .state)
  }

  func test_postalCode_mapsToPostalCodeField() {
    XCTAssertEqual(CardFormDefaults.postalCode(makeSession()).field, .postalCode)
  }

  func test_cardNetwork_returnsCardNetworkFieldContent_boundToSession() {
    let session = makeSession()
    let content: CardNetworkFieldContent = CardFormDefaults.cardNetwork(session)
    XCTAssertTrue(content.session === session)
  }

  // MARK: - Section content rendering

  func test_cardDetailsContent_rendersFieldsForInternalScope() {
    XCTAssertTrue(SwiftUIRenderProbe.render(CardFormDefaults.cardDetails(makeSession())))
  }

  func test_billingAddressContent_rendersWhenBillingRequired() {
    let config = CardFormConfiguration(
      cardFields: [.cardNumber],
      billingFields: [.city, .countryCode],
      requiresBillingAddress: true
    )
    XCTAssertTrue(SwiftUIRenderProbe.render(CardFormDefaults.billingAddress(makeSession(formConfiguration: config))))
  }

  func test_submitButton_rendersAndForwardsSubmit() {
    let session = makeSession()
    XCTAssertTrue(SwiftUIRenderProbe.render(CardFormDefaults.submitButton(session)))
    session.submit()
    let scope = session.scope as? MockCardFormScope
    XCTAssertNotNil(scope)
  }

  func test_unavailable_renders() {
    XCTAssertTrue(SwiftUIRenderProbe.render(CardFormDefaults.unavailable()))
  }

  // MARK: - Field content rendering (both gating branches)

  func test_cardFieldContent_rendersField_whenRequired() {
    XCTAssertTrue(SwiftUIRenderProbe.render(CardFormDefaults.cardNumber(makeSession(formConfiguration: .default))))
  }

  func test_cardFieldContent_rendersEmpty_whenNotRequired() {
    XCTAssertTrue(SwiftUIRenderProbe.render(CardFormDefaults.city(makeSession(formConfiguration: .default))))
  }

  func test_cardNetworkFieldContent_rendersDropdown_withMultipleNetworks() {
    XCTAssertTrue(SwiftUIRenderProbe.render(CardFormDefaults.cardNetwork(makeSession(availableNetworks: [.visa, .masterCard]))))
  }

  func test_cardNetworkFieldContent_rendersEmpty_withSingleNetwork() {
    XCTAssertTrue(SwiftUIRenderProbe.render(CardFormDefaults.cardNetwork(makeSession(availableNetworks: [.visa]))))
  }

  // MARK: - PrimerCardForm composable view

  func test_primerCardForm_rendersBoundFormWithInjectedSession() {
    let config = CardFormConfiguration(
      cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
      billingFields: [.countryCode, .city, .postalCode],
      requiresBillingAddress: true
    )
    let session = makeSession(formConfiguration: config, availableNetworks: [.visa, .masterCard])
    let view = PrimerCardForm().environment(\.primerCardFormSession, session)
    XCTAssertTrue(SwiftUIRenderProbe.render(view))
  }

  func test_primerCardForm_rendersUnavailableWithoutSession() {
    XCTAssertTrue(SwiftUIRenderProbe.render(PrimerCardForm()))
  }
}
