//
//  PrimerPaymentMethodType.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Identifies the type of payment method used for a transaction.
///
/// `PrimerPaymentMethodType` enumerates all payment methods supported by the Primer SDK.
/// Each case corresponds to a specific payment provider and method combination.
///
/// Payment methods are organized by provider:
/// - **Card payments**: `paymentCard`
/// - **Digital wallets**: `applePay`, `googlePay`, `payPal`
/// - **Buy now, pay later**: `klarna`, `atome`, `hoolah`
/// - **Bank transfers**: `goCardless`, `stripeAch`
/// - **Regional methods**: Various provider-specific implementations for iDEAL, BLIK, etc.
///
/// Use this enum when:
/// - Accessing payment method scopes: `checkoutScope.getPaymentMethodScope(for: .paymentCard)`
/// - Filtering or identifying payment methods
/// - Handling payment method-specific logic
///
/// Example usage:
/// ```swift
/// // Get card form scope using enum
/// let cardFormScope: PrimerCardFormScope? = checkoutScope.getPaymentMethodScope(for: .paymentCard)
///
/// // Check payment method type in results
/// if paymentResult.paymentMethodType == PrimerPaymentMethodType.applePay.rawValue {
///     // Handle Apple Pay specific logic
/// }
/// ```
/// - Note: **v3.0 breaking change**: This enum is now `public`. All cases are part of the
///   public API contract — no cases can be removed or renamed without a breaking change.
public enum PrimerPaymentMethodType: String, Codable, CaseIterable, Equatable, Hashable {
    case adyenAlipay                    = "ADYEN_ALIPAY"
    case adyenBlik                      = "ADYEN_BLIK"
    case adyenBancontactCard            = "ADYEN_BANCONTACT_CARD"
    case adyenDotPay                    = "ADYEN_DOTPAY"
    case adyenGiropay                   = "ADYEN_GIROPAY"
    case adyenIDeal                     = "ADYEN_IDEAL"
    case adyenInterac                   = "ADYEN_INTERAC"
    case adyenKlarna                    = "ADYEN_KLARNA"
    case adyenMobilePay                 = "ADYEN_MOBILEPAY"
    case adyenMBWay                     = "ADYEN_MBWAY"
    case adyenMultibanco                = "ADYEN_MULTIBANCO"
    case adyenPayTrail                  = "ADYEN_PAYTRAIL"
    case adyenPayshop                   = "ADYEN_PAYSHOP"
    case adyenSofort                    = "ADYEN_SOFORT"
    case adyenTrustly                   = "ADYEN_TRUSTLY"
    case adyenTwint                     = "ADYEN_TWINT"
    case adyenVipps                     = "ADYEN_VIPPS"
    case applePay                       = "APPLE_PAY"
    case atome                          = "ATOME"
    case buckarooBancontact             = "BUCKAROO_BANCONTACT"
    case buckarooEps                    = "BUCKAROO_EPS"
    case buckarooGiropay                = "BUCKAROO_GIROPAY"
    case buckarooIdeal                  = "BUCKAROO_IDEAL"
    case buckarooSofort                 = "BUCKAROO_SOFORT"
    case coinbase                       = "COINBASE"
    case goCardless                     = "GOCARDLESS"
    case googlePay                      = "GOOGLE_PAY"
    case hoolah                         = "HOOLAH"
    case iPay88Card                     = "IPAY88_CARD"
    case klarna                         = "KLARNA"
    case mollieBankcontact              = "MOLLIE_BANCONTACT"
    case mollieGiftcard                 = "MOLLIE_GIFTCARD"
    case mollieIdeal                    = "MOLLIE_IDEAL"
    case opennode                       = "OPENNODE"
    case payNLBancontact                = "PAY_NL_BANCONTACT"
    case payNLGiropay                   = "PAY_NL_GIROPAY"
    case payNLIdeal                     = "PAY_NL_IDEAL"
    case payNLKaartdirect                = "PAY_NL_KAARTDIRECT"
    case payNLPayconiq                  = "PAY_NL_PAYCONIQ"
    case payNLPaypal                    = "PAY_NL_PAYPAL"
    case paymentCard                    = "PAYMENT_CARD"
    case payPal                         = "PAYPAL"
    case primerTestKlarna               = "PRIMER_TEST_KLARNA"
    case primerTestPayPal               = "PRIMER_TEST_PAYPAL"
    case primerTestSofort               = "PRIMER_TEST_SOFORT"
    case rapydFast                      = "RAPYD_FAST"
    case rapydGCash                     = "RAPYD_GCASH"
    case rapydGrabPay                   = "RAPYD_GRABPAY"
    case rapydPromptPay                 = "RAPYD_PROMPTPAY"
    case rapydPoli                      = "RAPYD_POLI"
    case omisePromptPay                 = "OMISE_PROMPTPAY"
    case twoCtwoP                       = "TWOC2P"
    case xenditOvo                      = "XENDIT_OVO"
    case xenditRetailOutlets            = "XENDIT_RETAIL_OUTLETS"
    case xfersPayNow                    = "XFERS_PAYNOW"
    case nolPay                         = "NOL_PAY"
    case fintechtureSmartTransfer       = "FINTECTURE_SMART_TRANSFER"
    case fintechtureImmediateTransfer   = "FINTECHTURE_IMMEDIATE_TRANSFER"
    case stripeAch                      = "STRIPE_ACH"

    var provider: String {
        switch self {
        case .adyenAlipay,
             .adyenBlik,
             .adyenBancontactCard,
             .adyenDotPay,
             .adyenGiropay,
             .adyenIDeal,
             .adyenInterac,
             .adyenKlarna,
             .adyenMobilePay,
             .adyenMBWay,
             .adyenMultibanco,
             .adyenPayTrail,
             .adyenSofort,
             .adyenPayshop,
             .adyenTrustly,
             .adyenTwint,
             .adyenVipps:
            "ADYEN"

        case .applePay,
             .atome,
             .coinbase,
             .goCardless,
             .googlePay,
             .hoolah,
             .klarna,
             .opennode,
             .paymentCard,
             .payPal,
             .twoCtwoP:
            rawValue

        case .buckarooBancontact,
             .buckarooEps,
             .buckarooGiropay,
             .buckarooIdeal,
             .buckarooSofort:
            "BUCKAROO"

        case .iPay88Card:
            "IPAY88"

        case .mollieBankcontact,
             .mollieGiftcard,
             .mollieIdeal:
            "MOLLIE"

        case .payNLBancontact,
             .payNLGiropay,
             .payNLIdeal,
             .payNLKaartdirect,
             .payNLPayconiq,
             .payNLPaypal:
            "PAY_NL"

        case .primerTestKlarna,
             .primerTestPayPal,
             .primerTestSofort:
            "PRIMER_TEST"

        case .rapydFast,
             .rapydGCash,
             .rapydGrabPay,
             .rapydPoli,
             .rapydPromptPay:
            "RAPYD"

        case .omisePromptPay:
            "OMISE"

        case .xenditOvo,
             .xenditRetailOutlets:
            "XENDIT"

        case .xfersPayNow:
            "XFERS"
        case .nolPay:
            "NOL_PAY"
        case .stripeAch:
            "STRIPE"

        case .fintechtureSmartTransfer, .fintechtureImmediateTransfer:
            "FINTECHTURE"
        }
    }
}
