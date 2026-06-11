//
//  PrimerPaymentMethodTypeImageNameTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - defaultImageName Tests

@available(iOS 15.0, *)
final class PrimerPaymentMethodTypeDefaultImageNameTests: XCTestCase {

    // MARK: - Primary Payment Methods

    func test_defaultImageName_payPal_returnsPaypalImage() {
        XCTAssertEqual(PrimerPaymentMethodType.payPal.defaultImageName, .paypal)
    }

    func test_defaultImageName_primerTestPayPal_returnsPaypalImage() {
        XCTAssertEqual(PrimerPaymentMethodType.primerTestPayPal.defaultImageName, .paypal)
    }

    func test_defaultImageName_klarna_returnsKlarnaImage() {
        XCTAssertEqual(PrimerPaymentMethodType.klarna.defaultImageName, .klarna)
    }

    func test_defaultImageName_primerTestKlarna_returnsKlarnaImage() {
        XCTAssertEqual(PrimerPaymentMethodType.primerTestKlarna.defaultImageName, .klarna)
    }

    func test_defaultImageName_adyenKlarna_returnsKlarnaImage() {
        XCTAssertEqual(PrimerPaymentMethodType.adyenKlarna.defaultImageName, .klarna)
    }

    func test_defaultImageName_paymentCard_returnsCreditCardImage() {
        XCTAssertEqual(PrimerPaymentMethodType.paymentCard.defaultImageName, .creditCard)
    }

    func test_defaultImageName_applePay_returnsAppleIconImage() {
        XCTAssertEqual(PrimerPaymentMethodType.applePay.defaultImageName, .appleIcon)
    }

    func test_defaultImageName_googlePay_returnsGenericCard() {
        XCTAssertEqual(PrimerPaymentMethodType.googlePay.defaultImageName, .genericCard)
    }

    // MARK: - ACH Payment Methods

    func test_defaultImageName_goCardless_returnsAchBankImage() {
        XCTAssertEqual(PrimerPaymentMethodType.goCardless.defaultImageName, .achBank)
    }

    func test_defaultImageName_stripeAch_returnsAchBankImage() {
        XCTAssertEqual(PrimerPaymentMethodType.stripeAch.defaultImageName, .achBank)
    }

    // MARK: - Fallback

    func test_defaultImageName_unknownType_returnsGenericCard() {
        // Adyen payment methods don't have specific ImageName mappings
        XCTAssertEqual(PrimerPaymentMethodType.adyenBlik.defaultImageName, .genericCard)
        XCTAssertEqual(PrimerPaymentMethodType.adyenIDeal.defaultImageName, .genericCard)
        XCTAssertEqual(PrimerPaymentMethodType.hoolah.defaultImageName, .genericCard)
    }
}

// MARK: - icon Property Tests

@available(iOS 15.0, *)
final class PrimerPaymentMethodTypeIconTests: XCTestCase {

    func test_icon_allTypes_returnNonNilImage() {
        for type in PrimerPaymentMethodType.allCases {
            XCTAssertNotNil(type.icon, "\(type) should resolve a non-nil icon")
        }
    }

    func test_icon_unmappedType_fallsBackToGenericCard() {
        // Types not explicitly handled in the icon switch fall through to the generic card icon.
        XCTAssertEqual(PrimerPaymentMethodType.adyenAffirm.icon, ImageName.genericCard.image)
        XCTAssertEqual(PrimerPaymentMethodType.iPay88Card.icon, ImageName.genericCard.image)
    }
}
