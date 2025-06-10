//
//  PaymentMethodProtocol.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// Represents a payment method available in the Primer checkout flow.
///
/// Each payment method has its own UI representation along with state management, encapsulated by its associated
/// PrimerPaymentMethodScope. This protocol provides both a customizable UI interface and a default implementation.
public protocol PaymentMethodProtocol: Identifiable {
    associatedtype ScopeType: PrimerPaymentMethodScope

    /// The display name for the payment method.
    var name: String? { get }

    /// The type of payment method.
    var type: PaymentMethodType { get }

    /// Provides access to this payment method's state and behavior.
    @MainActor
    var scope: ScopeType { get }

    /// Defines a custom UI for this payment method using SwiftUI.
    ///
    /// - Parameter content: A ViewBuilder closure that uses the payment method's scope as a parameter,
    ///                      allowing full access to the payment method's state and behavior.
    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (ScopeType) -> V) -> AnyView

    /// Provides the default UI implementation for this payment method.
    @MainActor
    func defaultContent() -> AnyView
}

/// Defines the types of payment methods supported by the SDK
public enum PaymentMethodType: String, Codable, CaseIterable, Equatable, Hashable {
    case adyenAlipay                    = "ADYEN_ALIPAY"
    case adyenBlik                      = "ADYEN_BLIK"
    case adyenBancontactCard            = "ADYEN_BANCONTACT_CARD"
    case adyenDotPay                    = "ADYEN_DOTPAY"
    case adyenGiropay                   = "ADYEN_GIROPAY"
    case adyenIDeal                     = "ADYEN_IDEAL"
    case adyenInterac                   = "ADYEN_INTERAC"
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
    case mollieIdeal                    = "MOLLIE_IDEAL"
    case opennode                       = "OPENNODE"
    case payNLBancontact                = "PAY_NL_BANCONTACT"
    case payNLGiropay                   = "PAY_NL_GIROPAY"
    case payNLIdeal                     = "PAY_NL_IDEAL"
    case payNLPayconiq                  = "PAY_NL_PAYCONIQ"
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
             .adyenMobilePay,
             .adyenMBWay,
             .adyenMultibanco,
             .adyenPayTrail,
             .adyenSofort,
             .adyenPayshop,
             .adyenTrustly,
             .adyenTwint,
             .adyenVipps:
            return "ADYEN"

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
            return rawValue

        case .buckarooBancontact,
             .buckarooEps,
             .buckarooGiropay,
             .buckarooIdeal,
             .buckarooSofort:
            return "BUCKAROO"

        case .iPay88Card:
            return "IPAY88"

        case .mollieBankcontact,
             .mollieIdeal:
            return "MOLLIE"

        case .payNLBancontact,
             .payNLGiropay,
             .payNLIdeal,
             .payNLPayconiq:
            return "PAY_NL"

        case .primerTestKlarna,
             .primerTestPayPal,
             .primerTestSofort:
            return "PRIMER_TEST"

        case .rapydFast,
             .rapydGCash,
             .rapydGrabPay,
             .rapydPoli,
             .rapydPromptPay:
            return "RAPYD"

        case .omisePromptPay:
            return "OMISE"

        case .xenditOvo,
             .xenditRetailOutlets:
            return "XENDIT"

        case .xfersPayNow:
            return "XFERS"
        case .nolPay:
            return "NOL_PAY"
        case .stripeAch:
            return "STRIPE"

        case .fintechtureSmartTransfer, .fintechtureImmediateTransfer:
            return "FINTECHTURE"
        }
    }
}
