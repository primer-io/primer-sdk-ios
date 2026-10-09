//
//  CardFormDefaultsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

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
}
