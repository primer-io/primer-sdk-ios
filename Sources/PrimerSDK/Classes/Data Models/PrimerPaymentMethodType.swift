#if canImport(UIKit)

import Foundation

internal enum PrimerPaymentMethodType: String, Codable, CaseIterable, Equatable, Hashable {
    
    static var allProviders: [String] {
        return PrimerPaymentMethodType.allCases.compactMap({ $0.provider }).unique
    }

    case adyenAlipay        = "ADYEN_ALIPAY"
    case adyenBlik          = "ADYEN_BLIK"
    case adyenDotPay        = "ADYEN_DOTPAY"
    case adyenGiropay       = "ADYEN_GIROPAY"
    case adyenIDeal         = "ADYEN_IDEAL"
    case adyenInterac       = "ADYEN_INTERAC"
    case adyenMobilePay     = "ADYEN_MOBILEPAY"
    case adyenPayTrail      = "ADYEN_PAYTRAIL"
    case adyenSofort        = "ADYEN_SOFORT"
    case adyenPayshop       = "ADYEN_PAYSHOP"
    case adyenTrustly       = "ADYEN_TRUSTLY"
    case adyenTwint         = "ADYEN_TWINT"
    case adyenVipps         = "ADYEN_VIPPS"
    case apaya              = "APAYA"
    case applePay           = "APPLE_PAY"
    case atome              = "ATOME"
    case buckarooBancontact = "BUCKAROO_BANCONTACT"
    case buckarooEps        = "BUCKAROO_EPS"
    case buckarooGiropay    = "BUCKAROO_GIROPAY"
    case buckarooIdeal      = "BUCKAROO_IDEAL"
    case buckarooSofort     = "BUCKAROO_SOFORT"
    case coinbase           = "COINBASE"
    case goCardless         = "GOCARDLESS"
    case googlePay          = "GOOGLE_PAY"
    case hoolah             = "HOOLAH"
    case klarna             = "KLARNA"
    case mollieBankcontact  = "MOLLIE_BANCONTACT"
    case mollieIdeal        = "MOLLIE_IDEAL"
    case opennode           = "OPENNODE"
    case payNLBancontact    = "PAY_NL_BANCONTACT"
    case payNLGiropay       = "PAY_NL_GIROPAY"
    case payNLIdeal         = "PAY_NL_IDEAL"
    case payNLPayconiq      = "PAY_NL_PAYCONIQ"
    case paymentCard        = "PAYMENT_CARD"
    case payPal             = "PAYPAL"
    case primerTestKlarna   = "PRIMER_TEST_KLARNA"
    case primerTestPayPal   = "PRIMER_TEST_PAYPAL"
    case primerTestSofort   = "PRIMER_TEST_SOFORT"
    case rapydFast          = "RAPYD_FAST"
    case rapydGCash         = "RAPYD_GCASH"
    case rapydGrabPay       = "RAPYD_GRABPAY"
    case rapydPoli          = "RAPYD_POLI"
    case twoCtwoP           = "TWOC2P"
    case xfersPayNow        = "XFERS_PAYNOW"

    var isEnabled: Bool {
        switch self {
        case .goCardless,
                .googlePay:
            return false
        default:
            return true
        }
    }
    
    var provider: String {
        switch self {
        case .adyenAlipay,
                .adyenBlik,
                .adyenDotPay,
                .adyenGiropay,
                .adyenIDeal,
                .adyenInterac,
                .adyenMobilePay,
                .adyenPayTrail,
                .adyenSofort,
                .adyenPayshop,
                .adyenTrustly,
                .adyenTwint,
                .adyenVipps:
            return "ADYEN"
            
        case .apaya,
                .applePay,
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
                .rapydPoli:
            return "RAPYD"
            
        case .xfersPayNow:
            return "XFERS"
        }
    }
}

#endif
