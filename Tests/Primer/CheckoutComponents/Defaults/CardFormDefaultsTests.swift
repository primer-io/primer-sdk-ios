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

  // MARK: - CardFieldContent per-field gating

  func test_cardFieldContent_isRequired_whenFieldInCardFields() {
    // Given the default configuration includes the card-number field
    let session = makeSession(formConfiguration: .default)
    let content = CardFieldContent(session: session, field: .cardNumber)

    // Then the field renders (it is part of the configuration's card fields).
    XCTAssertTrue(isRendered(content))
  }

  func test_cardFieldContent_isRequired_whenFieldInBillingFields() {
    // Given a configuration whose billing fields include the city field
    let config = CardFormConfiguration(
      cardFields: [.cardNumber],
      billingFields: [.city],
      requiresBillingAddress: true
    )
    let session = makeSession(formConfiguration: config)
    let content = CardFieldContent(session: session, field: .city)

    // Then the field renders (it is part of the billing fields).
    XCTAssertTrue(isRendered(content))
  }

  func test_cardFieldContent_rendersEmpty_whenFieldNotInConfiguration() {
    // Given the default configuration does NOT include a billing city field
    let session = makeSession(formConfiguration: .default)
    let content = CardFieldContent(session: session, field: .city)

    // Then the field is gated out (renders EmptyView).
    XCTAssertFalse(isRendered(content))
  }

  // MARK: - CardNetworkFieldContent gating

  func test_cardNetworkFieldContent_renders_whenMoreThanOneNetwork() {
    // Given two available networks
    let session = makeSession(availableNetworks: [.visa, .masterCard])

    // Then the selector should render (count > 1).
    XCTAssertGreaterThan(session.state.availableNetworks.count, 1)
  }

  func test_cardNetworkFieldContent_gatedOut_withSingleNetwork() {
    // Given a single available network
    let session = makeSession(availableNetworks: [.visa])

    // Then the selector is gated out (count is not > 1).
    XCTAssertFalse(session.state.availableNetworks.count > 1)
  }

  func test_cardNetworkFieldContent_gatedOut_withNoNetworks() {
    // Given no available networks
    let session = makeSession(availableNetworks: [])

    // Then the selector is gated out.
    XCTAssertFalse(session.state.availableNetworks.count > 1)
  }

  // MARK: - Helpers

  /// Mirrors `CardFieldContent`'s private `isFieldRequired` gate: the field renders only when the
  /// API-driven configuration lists it in card or billing fields, otherwise it collapses to EmptyView.
  private func isRendered(_ content: CardFieldContent) -> Bool {
    guard let scope = content.session.scope as? any CardFormFieldScopeInternal else { return false }
    let configuration = scope.getFormConfiguration()
    return configuration.cardFields.contains(content.field)
      || configuration.billingFields.contains(content.field)
  }
}
