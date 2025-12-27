//
//  PrimerPaymentMethodTypeImageNameTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

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

    func test_defaultImageName_paymentCard_returnsCreditCardImage() {
        XCTAssertEqual(PrimerPaymentMethodType.paymentCard.defaultImageName, .creditCard)
    }

    func test_defaultImageName_applePay_returnsAppleIconImage() {
        XCTAssertEqual(PrimerPaymentMethodType.applePay.defaultImageName, .appleIcon)
    }

    func test_defaultImageName_googlePay_returnsAppleIconImage() {
        // Google Pay uses same icon as Apple Pay
        XCTAssertEqual(PrimerPaymentMethodType.googlePay.defaultImageName, .appleIcon)
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

    // MARK: - Primary Payment Methods

    func test_icon_payPal_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.payPal.icon)
    }

    func test_icon_primerTestPayPal_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.primerTestPayPal.icon)
    }

    func test_icon_klarna_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.klarna.icon)
    }

    func test_icon_primerTestKlarna_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.primerTestKlarna.icon)
    }

    func test_icon_goCardless_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.goCardless.icon)
    }

    func test_icon_stripeAch_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.stripeAch.icon)
    }

    func test_icon_applePay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.applePay.icon)
    }

    func test_icon_googlePay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.googlePay.icon)
    }

    func test_icon_paymentCard_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.paymentCard.icon)
    }

    // MARK: - Alternative Payment Methods

    func test_icon_hoolah_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.hoolah.icon)
    }

    func test_icon_atome_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.atome.icon)
    }

    func test_icon_coinbase_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.coinbase.icon)
    }

    // MARK: - Adyen Payment Methods

    func test_icon_adyenAlipay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenAlipay.icon)
    }

    func test_icon_adyenBlik_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenBlik.icon)
    }

    func test_icon_adyenBancontactCard_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenBancontactCard.icon)
    }

    func test_icon_adyenDotPay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenDotPay.icon)
    }

    func test_icon_adyenGiropay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenGiropay.icon)
    }

    func test_icon_adyenIDeal_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenIDeal.icon)
    }

    func test_icon_adyenInterac_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenInterac.icon)
    }

    func test_icon_adyenMobilePay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenMobilePay.icon)
    }

    func test_icon_adyenMBWay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenMBWay.icon)
    }

    func test_icon_adyenMultibanco_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenMultibanco.icon)
    }

    func test_icon_adyenPayTrail_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenPayTrail.icon)
    }

    func test_icon_adyenPayshop_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenPayshop.icon)
    }

    func test_icon_adyenSofort_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenSofort.icon)
    }

    func test_icon_primerTestSofort_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.primerTestSofort.icon)
    }

    func test_icon_adyenTrustly_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenTrustly.icon)
    }

    func test_icon_adyenTwint_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenTwint.icon)
    }

    func test_icon_adyenVipps_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.adyenVipps.icon)
    }

    // MARK: - Buckaroo Payment Methods

    func test_icon_buckarooBancontact_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.buckarooBancontact.icon)
    }

    func test_icon_buckarooEps_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.buckarooEps.icon)
    }

    func test_icon_buckarooGiropay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.buckarooGiropay.icon)
    }

    func test_icon_buckarooIdeal_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.buckarooIdeal.icon)
    }

    func test_icon_buckarooSofort_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.buckarooSofort.icon)
    }

    // MARK: - Mollie Payment Methods

    func test_icon_mollieBankcontact_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.mollieBankcontact.icon)
    }

    func test_icon_mollieIdeal_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.mollieIdeal.icon)
    }

    // MARK: - Pay.nl Payment Methods

    func test_icon_payNLBancontact_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.payNLBancontact.icon)
    }

    func test_icon_payNLGiropay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.payNLGiropay.icon)
    }

    func test_icon_payNLIdeal_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.payNLIdeal.icon)
    }

    func test_icon_payNLPayconiq_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.payNLPayconiq.icon)
    }

    // MARK: - Rapyd Payment Methods

    func test_icon_rapydGCash_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.rapydGCash.icon)
    }

    func test_icon_rapydGrabPay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.rapydGrabPay.icon)
    }

    func test_icon_rapydPromptPay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.rapydPromptPay.icon)
    }

    func test_icon_omisePromptPay_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.omisePromptPay.icon)
    }

    // MARK: - Other Payment Methods

    func test_icon_xfersPayNow_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.xfersPayNow.icon)
    }

    func test_icon_fintechtureSmartTransfer_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.fintechtureSmartTransfer.icon)
    }

    func test_icon_fintechtureImmediateTransfer_returnsNonNilImage() {
        XCTAssertNotNil(PrimerPaymentMethodType.fintechtureImmediateTransfer.icon)
    }

    // MARK: - Fallback

    func test_icon_unmappedPaymentMethod_returnsGenericCardImage() {
        // Test that payment methods not explicitly mapped in the icon switch statement
        // fall through to the default case and return the generic card icon.
        // iPay88Card is a valid case but not explicitly handled in the icon switch.
        XCTAssertNotNil(PrimerPaymentMethodType.iPay88Card.icon)
        XCTAssertEqual(PrimerPaymentMethodType.iPay88Card.icon, ImageName.genericCard.image)
    }
}
