//
//  CardFormFieldsViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class CardFormFieldsViewTests: XCTestCase {
    func test_billingRows_fullAddress_pairsTheNamesAndPostalCodeWithCity() {
        let rows = CardFormFieldsView.billingRows(
            [.countryCode, .firstName, .lastName, .addressLine1, .addressLine2, .postalCode, .city, .state, .phoneNumber]
        )

        XCTAssertEqual(
            rows,
            [[.countryCode], [.firstName, .lastName], [.addressLine1], [.addressLine2], [.postalCode, .city], [.state], [.phoneNumber]]
        )
    }

    func test_billingRows_partnerMissingOrNotNext_keepsTheFieldAlone() {
        XCTAssertEqual(CardFormFieldsView.billingRows([.postalCode, .state]), [[.postalCode], [.state]])
        XCTAssertEqual(CardFormFieldsView.billingRows([.city, .postalCode]), [[.city], [.postalCode]])
        XCTAssertEqual(CardFormFieldsView.billingRows([.firstName, .addressLine1, .lastName]), [[.firstName], [.addressLine1], [.lastName]])
    }
}
