#if canImport(UIKit)

import Foundation

public enum PrimerPaymentMethodType: Codable, Equatable, Hashable {
        
    case adyenAlipay
    case adyenBlik
    case adyenDotPay
    case adyenGiropay
    case adyenIDeal
    case adyenInterac
    case adyenMobilePay
    case adyenPayTrail
    case adyenSofort
    case adyenPayshop
    case adyenTrustly
    case adyenTwint
    case adyenVipps
    case apaya
    case applePay
    case atome
    case buckarooBancontact
    case buckarooEps
    case buckarooGiropay
    case buckarooIdeal
    case buckarooSofort
    case coinbase
    case goCardlessMandate
    case googlePay
    case hoolah
    case klarna
    case mollieBankcontact
    case mollieIdeal
    case payNLBancontact
    case payNLGiropay
    case payNLIdeal
    case payNLPayconiq
    case paymentCard
    case payPal
    case primerTestPayPal
    case primerTestKlarna
    case primerTestSofort
    case twoCtwoP
    case xfers
    case opennode
    case other(rawValue: String)
    
    // swiftlint:disable cyclomatic_complexity
    public init(rawValue: String) {
        switch rawValue {
        case "ADYEN_ALIPAY":
            self = .adyenAlipay
        case "ADYEN_BLIK":
            self = .adyenBlik
        case "ADYEN_DOTPAY":
            self = .adyenDotPay
        case "ADYEN_GIROPAY":
            self = .adyenGiropay
        case "ADYEN_IDEAL":
            self = .adyenIDeal
        case "ADYEN_INTERAC":
            self = .adyenInterac
        case "ADYEN_MOBILEPAY":
            self = .adyenMobilePay
        case "ADYEN_PAYTRAIL":
            self = .adyenPayTrail
        case "ADYEN_SOFORT":
            self = .adyenSofort
        case "ADYEN_PAYSHOP":
            self = .adyenPayshop
        case "ADYEN_TRUSTLY":
            self = .adyenTrustly
        case "ADYEN_TWINT":
            self = .adyenTwint
        case "ADYEN_VIPPS":
            self = .adyenVipps
        case "APAYA":
            self = .apaya
        case "APPLE_PAY":
            self = .applePay
        case "ATOME":
            self = .atome
        case "BUCKAROO_BANCONTACT":
            self = .buckarooBancontact
        case "BUCKAROO_EPS":
            self = .buckarooEps
        case "BUCKAROO_GIROPAY":
            self = .buckarooGiropay
        case "BUCKAROO_IDEAL":
            self = .buckarooIdeal
        case "BUCKAROO_SOFORT":
            self = .buckarooSofort
        case "COINBASE":
            self = .coinbase
        case "GOCARDLESS":
            self = .goCardlessMandate
        case "GOOGLE_PAY":
            self = .googlePay
        case "HOOLAH":
            self = .hoolah
        case "KLARNA":
            self = .klarna
        case "MOLLIE_BANCONTACT":
            self = .mollieBankcontact
        case "MOLLIE_IDEAL":
            self = .mollieIdeal
        case "PAY_NL_BANCONTACT":
            self = .payNLBancontact
        case "PAY_NL_GIROPAY":
            self = .payNLGiropay
        case "PAY_NL_IDEAL":
            self = .payNLIdeal
        case "PAY_NL_PAYCONIQ":
            self = .payNLPayconiq
        case "PAYMENT_CARD":
            self = .paymentCard
        case "PAYPAL":
            self = .payPal
        case "PRIMER_TEST_PAYPAL":
            self = .primerTestPayPal
        case "PRIMER_TEST_KLARNA":
            self = .primerTestKlarna
        case "PRIMER_TEST_SOFORT":
            self = .primerTestSofort
        case "TWOC2P":
            self = .twoCtwoP
        case "XFERS_PAYNOW":
            self = .xfers
        case "OPENNODE":
            self = .opennode
        default:
            self = .other(rawValue: rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .adyenAlipay:
            return "ADYEN_ALIPAY"
        case .adyenBlik:
            return "ADYEN_BLIK"
        case .adyenDotPay:
            return "ADYEN_DOTPAY"
        case .adyenGiropay:
            return "ADYEN_GIROPAY"
        case .adyenIDeal:
            return "ADYEN_IDEAL"
        case .adyenInterac:
            return "ADYEN_INTERAC"
        case .adyenMobilePay:
            return "ADYEN_MOBILEPAY"
        case .adyenPayshop:
            return "ADYEN_PAYSHOP"
        case .adyenPayTrail:
            return "ADYEN_PAYTRAIL"
        case .adyenSofort:
            return "ADYEN_SOFORT"
        case .adyenTrustly:
            return "ADYEN_TRUSTLY"
        case .adyenTwint:
            return "ADYEN_TWINT"
        case .adyenVipps:
            return "ADYEN_VIPPS"
        case .apaya:
            return "APAYA"
        case .applePay:
            return "APPLE_PAY"
        case .atome:
            return "ATOME"
        case .buckarooBancontact:
            return "BUCKAROO_BANCONTACT"
        case .buckarooEps:
            return "BUCKAROO_EPS"
        case .buckarooGiropay:
            return "BUCKAROO_GIROPAY"
        case .buckarooIdeal:
            return "BUCKAROO_IDEAL"
        case .buckarooSofort:
            return "BUCKAROO_SOFORT"
        case .coinbase:
            return "COINBASE"
        case .goCardlessMandate:
            return "GOCARDLESS"
        case .googlePay:
            return "GOOGLE_PAY"
        case .hoolah:
            return "HOOLAH"
        case .klarna:
            return "KLARNA"
        case .mollieBankcontact:
            return "MOLLIE_BANCONTACT"
        case .mollieIdeal:
            return "MOLLIE_IDEAL"
        case .payNLBancontact:
            return "PAY_NL_BANCONTACT"
        case .payNLGiropay:
            return "PAY_NL_GIROPAY"
        case .payNLIdeal:
            return "PAY_NL_IDEAL"
        case .payNLPayconiq:
            return "PAY_NL_PAYCONIQ"
        case .paymentCard:
            return "PAYMENT_CARD"
        case .payPal:
            return "PAYPAL"
        case .primerTestPayPal:
            return "PRIMER_TEST_PAYPAL"
        case .primerTestKlarna:
            return "PRIMER_TEST_KLARNA"
        case .primerTestSofort:
            return "PRIMER_TEST_SOFORT"
        case .twoCtwoP:
            return "TWOC2P"
        case .xfers:
            return "XFERS_PAYNOW"
        case .opennode:
            return "OPENNODE"
        case .other(let rawValue):
            return rawValue
        }
    }
    
    var isEnabled: Bool {
        switch self {
        case .adyenAlipay,
                .adyenBlik,
                .adyenDotPay,
                .adyenGiropay,
                .adyenIDeal,
                .adyenInterac,
                .adyenMobilePay,
                .adyenPayshop,
                .adyenPayTrail,
                .adyenSofort,
                .adyenTrustly,
                .adyenTwint,
                .adyenVipps,
                .applePay,
                .atome,
                .buckarooBancontact,
                .buckarooEps,
                .buckarooGiropay,
                .buckarooIdeal,
                .buckarooSofort,
                .coinbase,
                .hoolah,
                .mollieBankcontact,
                .mollieIdeal,
                .payNLBancontact,
                .payNLGiropay,
                .payNLIdeal,
                .payNLPayconiq,
                .primerTestKlarna,
                .primerTestPayPal,
                .primerTestSofort,
                .opennode,
                .twoCtwoP,
                .xfers:
            return Primer.shared.intent == .checkout
            
        case .apaya:
            return Primer.shared.intent == .vault
            
        case .goCardlessMandate,
                .googlePay,
                .other:
            return false
            
        case .klarna,
                .paymentCard,
                .payPal:
            return true
        }
    }
    // swiftlint:enable cyclomatic_complexity
    
    private enum CodingKeys: String, CodingKey {
        case adyenAlipay
        case adyenBlik
        case adyenDotPay
        case adyenGiropay
        case adyenIDeal
        case adyenInterac
        case adyenMobilePay
        case adyenPayTrail
        case adyenSofort
        case adyenPayshop
        case adyenTrustly
        case adyenTwint
        case adyenVipps
        case apaya
        case applePay
        case atome
        case buckarooBancontact
        case buckarooEps
        case buckarooGiropay
        case buckarooIdeal
        case buckarooSofort
        case coinbase
        case goCardlessMandate
        case googlePay
        case hoolah
        case klarna
        case mbWay
        case mollieBankcontact
        case mollieIdeal
        case payNLBancontact
        case payNLGiropay
        case payNLIdeal
        case payNLPayconiq
        case paymentCard
        case payPal
        case twoCtwoP
        case xfers
        case opennode
        case other
    }
    
    public init(from decoder: Decoder) throws {
        let rawValue: String = try decoder.singleValueContainer().decode(String.self)
        self = PrimerPaymentMethodType(rawValue: rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.rawValue, forKey: CodingKeys(rawValue: "type")!)
    }
}

#endif
