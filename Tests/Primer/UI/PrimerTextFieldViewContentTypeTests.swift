//
//  PrimerTextFieldViewContentTypeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) import PrimerUI
import XCTest

final class PrimerTextFieldViewContentTypeTests: XCTestCase {

    func testFieldsOfferTheMatchingAutoFill() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("The card's expiry, CVV and name content types need iOS 17") }
        let expected: [(PrimerTextFieldView, UITextContentType)] = [
            (PrimerCardNumberFieldView(), .creditCardNumber),
            (PrimerExpiryDateFieldView(), .creditCardExpiration),
            (PrimerCVVFieldView(), .creditCardSecurityCode),
            (PrimerCardholderNameFieldView(), .creditCardName),
            (PrimerFirstNameFieldView(), .givenName),
            (PrimerLastNameFieldView(), .familyName),
            (PrimerAddressLine1FieldView(), .streetAddressLine1),
            (PrimerAddressLine2FieldView(), .streetAddressLine2),
            (PrimerCityFieldView(), .addressCity),
            (PrimerStateFieldView(), .addressState),
            (PrimerPostalCodeFieldView(), .postalCode)
        ]

        for (view, contentType) in expected {
            XCTAssertEqual(view.textField.textContentType, contentType, "\(type(of: view))")
        }
    }
}
